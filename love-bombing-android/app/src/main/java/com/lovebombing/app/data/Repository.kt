package com.lovebombing.app.data

import android.content.Context
import android.net.Uri
import com.lovebombing.app.notify.ReminderScheduler
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId

class Repository(private val context: Context) {
    val dao = AppDatabase.get(context).dao()
    val content = Content.get(context)

    suspend fun saveSettings(settings: Settings) {
        dao.saveSettings(settings)
        ReminderScheduler.reschedule(context)
    }

    suspend fun logSent(message: Message?, category: String, text: String) {
        dao.insertSent(SentMessage(messageId = message?.id, category = category, text = text, sentAt = System.currentTimeMillis()))
    }

    suspend fun toggleFavorite(id: Int, isFavorite: Boolean) {
        if (isFavorite) dao.removeFavorite(id) else dao.addFavorite(Favorite(id, System.currentTimeMillis()))
    }

    suspend fun savePlan(plan: Plan) {
        dao.savePlan(plan)
        ReminderScheduler.reschedule(context)
    }

    suspend fun deletePlan(plan: Plan) {
        dao.deletePlan(plan)
        ReminderScheduler.reschedule(context)
    }

    // ---- Backup -------------------------------------------------------------

    suspend fun exportTo(uri: Uri) = withContext(Dispatchers.IO) {
        val root = JSONObject()
        root.put("app", "love-bombing")
        root.put("version", 1)
        root.put("exportedAt", System.currentTimeMillis())
        dao.settings()?.let { s ->
            root.put("settings", JSONObject().apply {
                put("onboarded", s.onboarded); put("wifeName", s.wifeName)
                put("birthday", s.birthday ?: JSONObject.NULL); put("anniversary", s.anniversary ?: JSONObject.NULL)
                put("morningMinutes", s.morningMinutes); put("nightMinutes", s.nightMinutes); put("middayMinutes", s.middayMinutes)
                put("morningOn", s.morningOn); put("nightOn", s.nightOn); put("middayOn", s.middayOn)
                put("birthdayOn", s.birthdayOn); put("anniversaryOn", s.anniversaryOn)
                put("festivalsOn", s.festivalsOn); put("plansOn", s.plansOn)
            })
        }
        root.put("sent", JSONArray().apply {
            dao.allSent().forEach {
                put(JSONObject().put("messageId", it.messageId ?: JSONObject.NULL).put("category", it.category)
                    .put("text", it.text).put("sentAt", it.sentAt))
            }
        })
        root.put("favorites", JSONArray().apply {
            dao.allFavorites().forEach { put(JSONObject().put("messageId", it.messageId).put("addedAt", it.addedAt)) }
        })
        root.put("plans", JSONArray().apply {
            dao.allPlans().forEach {
                put(JSONObject().put("type", it.type).put("title", it.title).put("dateEpochDay", it.dateEpochDay)
                    .put("minuteOfDay", it.minuteOfDay).put("note", it.note)
                    .put("messageId", it.messageId ?: JSONObject.NULL).put("messageText", it.messageText ?: JSONObject.NULL)
                    .put("createdAt", it.createdAt))
            }
        })
        root.put("wishlist", JSONArray().apply {
            dao.allWishlist().forEach {
                put(JSONObject().put("text", it.text).put("note", it.note).put("createdAt", it.createdAt).put("done", it.done))
            }
        })
        val out = context.contentResolver.openOutputStream(uri, "wt") ?: error("Could not open file for writing")
        out.bufferedWriter().use { it.write(root.toString(2)) }
    }

    /** Replaces all local data with the backup's contents. */
    suspend fun importFrom(uri: Uri) = withContext(Dispatchers.IO) {
        val text = context.contentResolver.openInputStream(uri)?.bufferedReader()?.use { it.readText() }
            ?: error("Could not open file")
        val root = JSONObject(text)
        require(root.optString("app") == "love-bombing") { "This isn't a Love Bombing backup file" }

        fun JSONObject.longOrNull(key: String) = if (isNull(key) || !has(key)) null else getLong(key)
        fun JSONObject.intOrNull(key: String) = if (isNull(key) || !has(key)) null else getInt(key)
        fun JSONObject.strOrNull(key: String) = if (isNull(key) || !has(key)) null else getString(key)
        fun JSONObject.arr(key: String): List<JSONObject> = optJSONArray(key)?.let { a -> List(a.length()) { a.getJSONObject(it) } } ?: emptyList()

        val defaults = Settings()
        val settings = root.optJSONObject("settings")?.let { s ->
            Settings(
                onboarded = s.optBoolean("onboarded", true),
                wifeName = s.optString("wifeName"),
                birthday = s.longOrNull("birthday"),
                anniversary = s.longOrNull("anniversary"),
                morningMinutes = s.optInt("morningMinutes", defaults.morningMinutes),
                nightMinutes = s.optInt("nightMinutes", defaults.nightMinutes),
                middayMinutes = s.optInt("middayMinutes", defaults.middayMinutes),
                morningOn = s.optBoolean("morningOn", true),
                nightOn = s.optBoolean("nightOn", true),
                middayOn = s.optBoolean("middayOn", true),
                birthdayOn = s.optBoolean("birthdayOn", true),
                anniversaryOn = s.optBoolean("anniversaryOn", true),
                festivalsOn = s.optBoolean("festivalsOn", true),
                plansOn = s.optBoolean("plansOn", true),
            )
        }
        val sent = root.arr("sent").map {
            SentMessage(messageId = it.intOrNull("messageId"), category = it.getString("category"),
                text = it.getString("text"), sentAt = it.getLong("sentAt"))
        }
        val favorites = root.arr("favorites").map { Favorite(it.getInt("messageId"), it.optLong("addedAt")) }
        val plans = root.arr("plans").map {
            Plan(type = it.getString("type"), title = it.getString("title"), dateEpochDay = it.getLong("dateEpochDay"),
                minuteOfDay = it.getInt("minuteOfDay"), note = it.optString("note"), messageId = it.intOrNull("messageId"),
                messageText = it.strOrNull("messageText"), createdAt = it.optLong("createdAt", System.currentTimeMillis()))
        }
        val wishlist = root.arr("wishlist").map {
            WishlistItem(text = it.getString("text"), note = it.optString("note"),
                createdAt = it.optLong("createdAt", System.currentTimeMillis()), done = it.optBoolean("done"))
        }
        dao.replaceAll(settings, sent, favorites, plans, wishlist)
        ReminderScheduler.reschedule(context)
    }
}

/** Pure helpers for suggestions and streaks, shared by the UI and notifications. */
object Suggest {
    const val NO_REPEAT_DAYS = 60L
    private val daytimeRotation = listOf("Flirty", "Romantic", "Appreciation", "Missing You", "Playful Tease", "Supportive")

    fun recentIds(sent: List<SentMessage>, now: Long = System.currentTimeMillis()): Set<Int> {
        val cutoff = now - NO_REPEAT_DAYS * 24 * 60 * 60 * 1000
        return sent.asSequence().filter { it.sentAt >= cutoff }.mapNotNull { it.messageId }.toSet()
    }

    /** Category that best fits today and the current time. */
    fun categoryFor(today: LocalDate, time: LocalTime, events: List<Event>): Pair<String, String?> {
        val todays = events.filter { it.date == today }
        todays.firstOrNull { it.kind == EventKind.BIRTHDAY }?.let { return "Birthday" to null }
        todays.firstOrNull { it.kind == EventKind.ANNIVERSARY }?.let { return "Anniversary" to null }
        todays.firstOrNull { it.kind == EventKind.FESTIVAL }?.let { return Content.FESTIVAL_CATEGORY to it.festivalKey }
        return when {
            time.hour < 11 -> "Good Morning" to null
            time.hour >= 21 -> "Good Night" to null
            else -> daytimeRotation[Math.floorMod(today.toEpochDay(), daytimeRotation.size.toLong()).toInt()] to null
        }
    }

    /**
     * Deterministic pick for (day, category), skipping anything sent in the last 60 days.
     * [offset] lets "Next" walk through alternatives.
     */
    fun pick(
        content: Content,
        category: String?,
        festivalKey: String?,
        recent: Set<Int>,
        day: LocalDate,
        offset: Int,
    ): Message? {
        var pool = content.messages.filter { category == null || it.category == category }
        if (festivalKey != null) {
            val specific = pool.filter { it.festivalKey == festivalKey }
            pool = if (specific.isNotEmpty()) specific + pool.filter { it.festivalKey == "general" } else pool
        }
        val fresh = pool.filter { it.id !in recent }
        val usable = fresh.ifEmpty { pool }
        if (usable.isEmpty()) return null
        val seed = day.toEpochDay() * 31 + (category?.hashCode() ?: 0)
        return usable[Math.floorMod(seed + offset, usable.size.toLong()).toInt()]
    }

    fun streak(sent: List<SentMessage>, today: LocalDate, zone: ZoneId = ZoneId.systemDefault()): Int {
        val days = sent.map { Instant.ofEpochMilli(it.sentAt).atZone(zone).toLocalDate() }.toHashSet()
        var cursor = if (today in days) today else today.minusDays(1)
        var count = 0
        while (cursor in days) {
            count++
            cursor = cursor.minusDays(1)
        }
        return count
    }
}
