package com.dosemate.app.data.repo

import android.content.Context
import android.net.Uri
import androidx.room.withTransaction
import com.dosemate.app.alarm.ReminderEngine
import com.dosemate.app.data.db.AppDatabase
import com.dosemate.app.data.db.DismissMethod
import com.dosemate.app.data.db.DoseLogEntity
import com.dosemate.app.data.db.DoseTimeEntity
import com.dosemate.app.data.db.FoodRelation
import com.dosemate.app.data.db.JournalEntryEntity
import com.dosemate.app.data.db.MedIcon
import com.dosemate.app.data.db.MedicineEntity
import com.dosemate.app.data.db.MedicineType
import com.dosemate.app.data.db.ToneType
import com.dosemate.app.data.db.VibrationPattern
import com.dosemate.core.AlertStyle
import com.dosemate.core.DurationType
import com.dosemate.core.LogStatus
import com.dosemate.core.ScheduleType
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Backup to / restore from a single local .zip file (chosen with the system file picker).
 * Contains a JSON dump of the database and settings plus private photos, tones and voice notes.
 */
@Singleton
class BackupManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val db: AppDatabase,
    private val settings: SettingsRepository,
    private val photos: PhotoStore,
    private val engine: ReminderEngine,
    private val seeder: PlanSeeder,
) {
    private val folders = listOf(PhotoStore.MEDICINE, PhotoStore.JOURNAL, PhotoStore.TONES, PhotoStore.VOICE)

    suspend fun export(uri: Uri): Boolean = withContext(Dispatchers.IO) {
        runCatching {
            val json = JSONObject()
                .put("app", "DoseMate")
                .put("version", 1)
                .put("exportedAt", LocalDateTime.now().toString())
                .put("settings", settingsJson())
                .put("medicines", JSONArray(db.medicineDao().getAll().map { medicineJson(it.medicine) }))
                .put("times", JSONArray(db.medicineDao().allTimes().map { timeJson(it) }))
                .put("logs", JSONArray(db.doseLogDao().all().map { logJson(it) }))
                .put("journal", JSONArray(db.journalDao().all().map { journalJson(it) }))
            context.contentResolver.openOutputStream(uri)?.use { raw ->
                ZipOutputStream(raw.buffered()).use { zip ->
                    zip.putNextEntry(ZipEntry("data.json"))
                    zip.write(json.toString(2).toByteArray())
                    zip.closeEntry()
                    for (folder in folders) {
                        photos.dir(folder).listFiles()?.filter { it.isFile && !it.name.startsWith("builtin_") }?.forEach { file ->
                            zip.putNextEntry(ZipEntry("$folder/${file.name}"))
                            file.inputStream().use { it.copyTo(zip) }
                            zip.closeEntry()
                        }
                    }
                }
            } ?: error("Cannot open file")
            true
        }.getOrDefault(false)
    }

    suspend fun restore(uri: Uri): Boolean = withContext(Dispatchers.IO) {
        runCatching {
            var data: JSONObject? = null
            val files = mutableMapOf<String, ByteArray>()
            context.contentResolver.openInputStream(uri)?.use { raw ->
                ZipInputStream(raw.buffered()).use { zip ->
                    while (true) {
                        val entry = zip.nextEntry ?: break
                        val bytes = zip.readBytes()
                        val name = entry.name
                        if (name == "data.json") data = JSONObject(String(bytes))
                        else if (!entry.isDirectory && name.count { it == '/' } == 1 && !name.contains("..")) files[name] = bytes
                    }
                }
            }
            val json = data ?: error("Not a DoseMate backup")
            require(json.optString("app") == "DoseMate")

            engine.cancelEverything()
            db.withTransaction {
                db.activeAlertDao().deleteAll()
                db.doseLogDao().deleteAll()
                db.journalDao().deleteAll()
                db.medicineDao().deleteAll()
                db.medicineDao().insertAllRaw(json.getJSONArray("medicines").objects().map(::medicineFrom))
                db.medicineDao().insertAllTimes(json.getJSONArray("times").objects().map(::timeFrom))
                db.doseLogDao().insertAll(json.getJSONArray("logs").objects().map(::logFrom))
                db.journalDao().insertAll(json.getJSONArray("journal").objects().map(::journalFrom))
            }
            for ((path, bytes) in files) {
                val (folder, name) = path.split("/")
                if (folder in folders) File(photos.dir(folder), name).writeBytes(bytes)
            }
            settingsFrom(json.getJSONObject("settings"))
            engine.rescheduleAll()
            true
        }.getOrDefault(false)
    }

    /** Erases everything. Optionally reloads the prescribed plan. */
    suspend fun reset(reloadPlan: Boolean) = withContext(Dispatchers.IO) {
        engine.cancelEverything()
        db.clearAllTables()
        folders.forEach { folder -> photos.dir(folder).listFiles()?.forEach { it.delete() } }
        settings.reset()
        if (reloadPlan) seeder.seedIfNeeded() else settings.update { it.copy(seeded = true) }
        engine.rescheduleAll()
    }

    // ---- JSON helpers

    private fun JSONArray.objects(): List<JSONObject> = (0 until length()).map { getJSONObject(it) }
    private fun JSONObject.optLongOrNull(key: String): Long? = if (has(key) && !isNull(key)) getLong(key) else null
    private fun JSONObject.optIntOrNull(key: String): Int? = if (has(key) && !isNull(key)) getInt(key) else null
    private fun JSONObject.optStringOrNull(key: String): String? = if (has(key) && !isNull(key)) getString(key) else null
    private inline fun <reified E : Enum<E>> JSONObject.enum(key: String, def: E): E =
        optStringOrNull(key)?.let { name -> enumValues<E>().firstOrNull { it.name == name } } ?: def

    private fun settingsJson(): JSONObject {
        val obj = JSONObject()
        settings.exportMap().forEach { (k, v) ->
            val typed = when (v) {
                is Boolean -> JSONObject().put("t", "b").put("v", v)
                is Int -> JSONObject().put("t", "i").put("v", v)
                is Long -> JSONObject().put("t", "l").put("v", v)
                is Float -> JSONObject().put("t", "f").put("v", v.toDouble())
                is String -> JSONObject().put("t", "s").put("v", v)
                else -> null
            }
            if (typed != null) obj.put(k, typed)
        }
        return obj
    }

    private fun settingsFrom(obj: JSONObject) {
        val map = mutableMapOf<String, Any?>()
        obj.keys().forEach { k ->
            val t = obj.getJSONObject(k)
            map[k] = when (t.getString("t")) {
                "b" -> t.getBoolean("v")
                "i" -> t.getInt("v")
                "l" -> t.getLong("v")
                "f" -> t.getDouble("v").toFloat()
                else -> t.getString("v")
            }
        }
        settings.importMap(map)
    }

    private fun medicineJson(m: MedicineEntity) = JSONObject().apply {
        put("id", m.id); put("name", m.name); put("type", m.type.name); put("colorIndex", m.colorIndex); put("icon", m.icon.name)
        put("photoPath", m.photoPath ?: JSONObject.NULL); put("doseAmount", m.doseAmount); put("doseUnit", m.doseUnit)
        put("instructions", m.instructions); put("food", m.food.name); put("notes", m.notes); put("warning", m.warning)
        put("banner", m.banner); put("bannerDismissed", m.bannerDismissed)
        put("scheduleType", m.scheduleType.name); put("weekdays", m.weekdays); put("intervalDays", m.intervalDays)
        put("timesPerDay", m.timesPerDay); put("windowStartMinute", m.windowStartMinute); put("windowEndMinute", m.windowEndMinute)
        put("startDate", m.startDate.toEpochDay()); put("durationType", m.durationType.name)
        put("endDate", m.endDate?.toEpochDay() ?: JSONObject.NULL); put("durationDays", m.durationDays ?: JSONObject.NULL)
        put("durationDoses", m.durationDoses ?: JSONObject.NULL)
        put("linkedMedicineId", m.linkedMedicineId ?: JSONObject.NULL); put("linkedGapMinutes", m.linkedGapMinutes)
        put("paused", m.paused); put("archived", m.archived); put("trackFrom", m.trackFrom.toString())
        put("stockEnabled", m.stockEnabled); put("stockCount", m.stockCount); put("stockPerDose", m.stockPerDose)
        put("refillThreshold", m.refillThreshold); put("refillAlerted", m.refillAlerted)
        put("alertStyle", m.alertStyle.name); put("toneType", m.toneType.name); put("toneUri", m.toneUri ?: JSONObject.NULL)
        put("toneName", m.toneName ?: JSONObject.NULL); put("vibration", m.vibration.name); put("flashlight", m.flashlight)
        put("dismissMethod", m.dismissMethod.name); put("repeatIntervalMinutes", m.repeatIntervalMinutes); put("repeatMax", m.repeatMax)
        put("preAlarmMinutes", m.preAlarmMinutes); put("completedCelebrated", m.completedCelebrated); put("createdAt", m.createdAt)
    }

    private fun medicineFrom(o: JSONObject) = MedicineEntity(
        id = o.getLong("id"), name = o.getString("name"), type = o.enum("type", MedicineType.OTHER),
        colorIndex = o.optInt("colorIndex"), icon = o.enum("icon", MedIcon.PILL), photoPath = o.optStringOrNull("photoPath"),
        doseAmount = o.optDouble("doseAmount", 1.0), doseUnit = o.optString("doseUnit"), instructions = o.optString("instructions"),
        food = o.enum("food", FoodRelation.NONE), notes = o.optString("notes"), warning = o.optString("warning"),
        banner = o.optString("banner"), bannerDismissed = o.optBoolean("bannerDismissed"),
        scheduleType = o.enum("scheduleType", ScheduleType.DAILY), weekdays = o.optInt("weekdays"),
        intervalDays = o.optInt("intervalDays", 1), timesPerDay = o.optInt("timesPerDay", 1),
        windowStartMinute = o.optInt("windowStartMinute", 480), windowEndMinute = o.optInt("windowEndMinute", 1320),
        startDate = LocalDate.ofEpochDay(o.getLong("startDate")), durationType = o.enum("durationType", DurationType.ONGOING),
        endDate = o.optLongOrNull("endDate")?.let(LocalDate::ofEpochDay), durationDays = o.optIntOrNull("durationDays"),
        durationDoses = o.optIntOrNull("durationDoses"), linkedMedicineId = o.optLongOrNull("linkedMedicineId"),
        linkedGapMinutes = o.optInt("linkedGapMinutes", 30), paused = o.optBoolean("paused"), archived = o.optBoolean("archived"),
        trackFrom = o.optStringOrNull("trackFrom")?.let(LocalDateTime::parse) ?: LocalDateTime.now(),
        stockEnabled = o.optBoolean("stockEnabled"), stockCount = o.optDouble("stockCount", 0.0),
        stockPerDose = o.optDouble("stockPerDose", 1.0), refillThreshold = o.optDouble("refillThreshold", 5.0),
        refillAlerted = o.optBoolean("refillAlerted"), alertStyle = o.enum("alertStyle", AlertStyle.ALARM),
        toneType = o.enum("toneType", ToneType.DEFAULT), toneUri = o.optStringOrNull("toneUri"), toneName = o.optStringOrNull("toneName"),
        vibration = o.enum("vibration", VibrationPattern.STANDARD), flashlight = o.optBoolean("flashlight"),
        dismissMethod = o.enum("dismissMethod", DismissMethod.BUTTONS), repeatIntervalMinutes = o.optInt("repeatIntervalMinutes", 5),
        repeatMax = o.optInt("repeatMax", 3), preAlarmMinutes = o.optInt("preAlarmMinutes"),
        completedCelebrated = o.optBoolean("completedCelebrated"), createdAt = o.optLong("createdAt"),
    )

    private fun timeJson(t: DoseTimeEntity) = JSONObject()
        .put("id", t.id).put("medicineId", t.medicineId).put("minuteOfDay", t.minuteOfDay).put("enabled", t.enabled)
        .put("alertStyle", t.alertStyle?.name ?: JSONObject.NULL)

    private fun timeFrom(o: JSONObject) = DoseTimeEntity(
        id = o.getLong("id"), medicineId = o.getLong("medicineId"), minuteOfDay = o.getInt("minuteOfDay"),
        enabled = o.optBoolean("enabled", true),
        alertStyle = o.optStringOrNull("alertStyle")?.let { n -> AlertStyle.entries.firstOrNull { it.name == n } },
    )

    private fun logJson(l: DoseLogEntity) = JSONObject()
        .put("id", l.id).put("medicineId", l.medicineId).put("slotId", l.slotId).put("scheduledAt", l.scheduledAt.toString())
        .put("status", l.status.name).put("actionAt", l.actionAt.toString()).put("skipReason", l.skipReason ?: JSONObject.NULL)

    private fun logFrom(o: JSONObject) = DoseLogEntity(
        id = o.getLong("id"), medicineId = o.getLong("medicineId"), slotId = o.getLong("slotId"),
        scheduledAt = LocalDateTime.parse(o.getString("scheduledAt")), status = o.enum("status", LogStatus.TAKEN),
        actionAt = LocalDateTime.parse(o.getString("actionAt")), skipReason = o.optStringOrNull("skipReason"),
    )

    private fun journalJson(j: JournalEntryEntity) = JSONObject()
        .put("id", j.id).put("date", j.date.toEpochDay()).put("photoPath", j.photoPath ?: JSONObject.NULL)
        .put("itchScore", j.itchScore).put("notes", j.notes).put("createdAt", j.createdAt)

    private fun journalFrom(o: JSONObject) = JournalEntryEntity(
        id = o.getLong("id"), date = LocalDate.ofEpochDay(o.getLong("date")), photoPath = o.optStringOrNull("photoPath"),
        itchScore = o.optInt("itchScore"), notes = o.optString("notes"), createdAt = o.optLong("createdAt"),
    )
}
