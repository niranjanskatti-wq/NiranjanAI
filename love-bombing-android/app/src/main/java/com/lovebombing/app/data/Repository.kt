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
        dao.deleteStatus(planKey(plan.id))
        ReminderScheduler.reschedule(context)
    }

    suspend fun setStatus(item: PlanItem, status: PlanStatus) {
        val existing = dao.status(item.key) ?: PlanStatusRow(item.key, status.name)
        dao.saveStatus(existing.copy(status = status.name, updatedAt = System.currentTimeMillis()))
        ReminderScheduler.reschedule(context)
    }

    /** "Change": move one occurrence to a new date/time (the routine itself is untouched). */
    suspend fun moveItem(item: PlanItem, date: LocalDate, minuteOfDay: Int) {
        if (item.plan != null) {
            dao.savePlan(item.plan.copy(dateEpochDay = date.toEpochDay(), minuteOfDay = minuteOfDay))
            dao.deleteStatus(item.key)
        } else {
            val existing = dao.status(item.key) ?: PlanStatusRow(item.key, PlanStatus.PENDING.name)
            dao.saveStatus(
                existing.copy(
                    status = PlanStatus.PENDING.name, epochDay = date.toEpochDay(), minuteOfDay = minuteOfDay,
                    updatedAt = System.currentTimeMillis(),
                ),
            )
        }
        ReminderScheduler.reschedule(context)
    }

    suspend fun saveAutoPlan(setting: AutoPlanSetting) {
        dao.saveAutoPlan(setting)
        ReminderScheduler.reschedule(context)
    }

    suspend fun setAllAutoPlans(enabled: Boolean) {
        val existing = dao.allAutoPlans().associateBy { it.templateId }
        AutoPlans.templates.forEach { t ->
            dao.saveAutoPlan((existing[t.id] ?: AutoPlanSetting(t.id, enabled)).copy(enabled = enabled))
        }
        ReminderScheduler.reschedule(context)
    }

    // ---- Backup -------------------------------------------------------------

    suspend fun exportTo(uri: Uri) = withContext(Dispatchers.IO) {
        val root = JSONObject()
        root.put("app", "love-bombing")
        root.put("version", 2)
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
                put(JSONObject().put("id", it.id).put("type", it.type).put("title", it.title).put("dateEpochDay", it.dateEpochDay)
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
        root.put("autoPlans", JSONArray().apply {
            dao.allAutoPlans().forEach {
                put(JSONObject().put("templateId", it.templateId).put("enabled", it.enabled)
                    .put("minuteOfDay", it.minuteOfDay ?: JSONObject.NULL).put("dayOfWeek", it.dayOfWeek ?: JSONObject.NULL))
            }
        })
        root.put("planStatus", JSONArray().apply {
            dao.allStatuses().forEach {
                put(JSONObject().put("key", it.key).put("status", it.status)
                    .put("epochDay", it.epochDay ?: JSONObject.NULL).put("minuteOfDay", it.minuteOfDay ?: JSONObject.NULL)
                    .put("updatedAt", it.updatedAt))
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
            Plan(id = it.optLong("id", 0), type = it.getString("type"), title = it.getString("title"), dateEpochDay = it.getLong("dateEpochDay"),
                minuteOfDay = it.getInt("minuteOfDay"), note = it.optString("note"), messageId = it.intOrNull("messageId"),
                messageText = it.strOrNull("messageText"), createdAt = it.optLong("createdAt", System.currentTimeMillis()))
        }
        val wishlist = root.arr("wishlist").map {
            WishlistItem(text = it.getString("text"), note = it.optString("note"),
                createdAt = it.optLong("createdAt", System.currentTimeMillis()), done = it.optBoolean("done"))
        }
        val autoPlans = root.arr("autoPlans").map {
            AutoPlanSetting(it.getString("templateId"), it.getBoolean("enabled"), it.intOrNull("minuteOfDay"), it.intOrNull("dayOfWeek"))
        }
        val statuses = root.arr("planStatus").map {
            PlanStatusRow(it.getString("key"), it.getString("status"), it.longOrNull("epochDay"), it.intOrNull("minuteOfDay"),
                it.optLong("updatedAt", System.currentTimeMillis()))
        }
        dao.replaceAll(settings, sent, favorites, plans, wishlist, autoPlans, statuses)
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

    /** A long message that fits [theme] (e.g. "Good Morning"), avoiding recent repeats. */
    fun pickLong(content: Content, theme: String?, recent: Set<Int>, day: LocalDate, offset: Int): Message? {
        val long = content.messages.filter { it.isLong }
        val themed = long.filter { it.theme == theme }.ifEmpty { long }
        val usable = themed.filter { it.id !in recent }.ifEmpty { themed }
        if (usable.isEmpty()) return null
        return usable[Math.floorMod(day.toEpochDay() * 17 + offset, usable.size.toLong()).toInt()]
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
