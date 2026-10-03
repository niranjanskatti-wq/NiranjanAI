package com.dosemate.app.data.repo

import android.content.Context
import android.content.SharedPreferences
import com.dosemate.core.AlertStyle
import com.dosemate.core.QuietHours
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.conflate
import java.security.MessageDigest
import java.time.LocalDate
import java.time.LocalTime
import javax.inject.Inject
import javax.inject.Singleton

enum class ThemeMode { SYSTEM, LIGHT, DARK, AMOLED }

/** All user preferences. Stored in private SharedPreferences so receivers can read them synchronously. */
data class AppSettings(
    val themeMode: ThemeMode = ThemeMode.SYSTEM,
    val accent: Int = 0,
    val language: String = "system",
    val use24h: Boolean = false,
    val largeText: Boolean = false,

    val snoozeOptions: List<Int> = listOf(5, 10, 15, 30),
    val defaultSnooze: Int = 10,
    val defaultTabletStyle: AlertStyle = AlertStyle.ALARM,
    val defaultOtherStyle: AlertStyle = AlertStyle.SOUND,
    val repeatInterval: Int = 5,
    val repeatMax: Int = 3,
    val escalate: Boolean = true,
    val quietEnabled: Boolean = false,
    val quietStart: LocalTime = LocalTime.of(23, 0),
    val quietEnd: LocalTime = LocalTime.of(6, 30),
    val quietAlarmsToo: Boolean = false,
    val hideNames: Boolean = false,
    val lateAfterMinutes: Int = 30,
    val missedAfterMinutes: Int = 120,

    val alarmStartVolume: Int = 30,
    val alarmRampSeconds: Int = 30,
    val alarmMaxVolume: Int = 100,
    val forceAlarmVolume: Boolean = true,
    val dndBypass: Boolean = false,
    val ringMinutes: Int = 3,

    val doctorName: String = "",
    val prescribedDate: LocalDate? = null,
    val dietNote: String = "",

    val appLock: Boolean = false,
    val pinHash: String = "",
    val biometric: Boolean = true,

    val journalReminder: Boolean = true,
    val journalDay: Int = 7, // ISO day: 7 = Sunday
    val journalTime: LocalTime = LocalTime.of(10, 0),

    val onboardingDone: Boolean = false,
    val seeded: Boolean = false,
) {
    val quietHours: QuietHours get() = QuietHours(quietEnabled, quietStart, quietEnd)
}

@Singleton
class SettingsRepository @Inject constructor(@ApplicationContext context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    val settings: Flow<AppSettings> = callbackFlow {
        trySend(current())
        val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, _ -> trySend(current()) }
        prefs.registerOnSharedPreferenceChangeListener(listener)
        awaitClose { prefs.unregisterOnSharedPreferenceChangeListener(listener) }
    }.conflate()

    fun current(): AppSettings = read(prefs)

    fun update(transform: (AppSettings) -> AppSettings) {
        write(prefs, transform(current()))
    }

    fun setPin(pin: String) = update { it.copy(pinHash = hash(pin)) }

    fun checkPin(pin: String): Boolean = current().pinHash.isNotEmpty() && current().pinHash == hash(pin)

    fun reset() {
        prefs.edit().clear().apply()
    }

    /** Raw key/value export for backups. */
    fun exportMap(): Map<String, Any?> = prefs.all

    fun importMap(values: Map<String, Any?>) {
        val editor = prefs.edit().clear()
        values.forEach { (k, v) ->
            when (v) {
                is Boolean -> editor.putBoolean(k, v)
                is Int -> editor.putInt(k, v)
                is Long -> editor.putLong(k, v)
                is Float -> editor.putFloat(k, v)
                is Double -> editor.putInt(k, v.toInt())
                is String -> editor.putString(k, v)
            }
        }
        editor.apply()
    }

    companion object {
        const val PREFS = "dosemate_settings"

        private fun hash(pin: String): String =
            MessageDigest.getInstance("SHA-256").digest("dosemate:$pin".toByteArray())
                .joinToString("") { "%02x".format(it) }

        /** Synchronous read used before Hilt is ready (e.g. attachBaseContext). */
        fun read(context: Context): AppSettings =
            read(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE))

        private fun read(p: SharedPreferences): AppSettings {
            val d = AppSettings()
            fun time(key: String, def: LocalTime) =
                p.getInt(key, -1).let { if (it < 0) def else LocalTime.of(it / 60, it % 60) }
            fun <E : Enum<E>> enum(key: String, def: E, values: Array<E>): E =
                p.getString(key, null)?.let { name -> values.firstOrNull { it.name == name } } ?: def
            return AppSettings(
                themeMode = enum("themeMode", d.themeMode, ThemeMode.entries.toTypedArray()),
                accent = p.getInt("accent", d.accent),
                language = p.getString("language", d.language) ?: d.language,
                use24h = p.getBoolean("use24h", d.use24h),
                largeText = p.getBoolean("largeText", d.largeText),
                snoozeOptions = p.getString("snoozeOptions", null)
                    ?.split(",")?.mapNotNull { it.trim().toIntOrNull() }?.filter { it in 1..240 }
                    ?.takeIf { it.isNotEmpty() } ?: d.snoozeOptions,
                defaultSnooze = p.getInt("defaultSnooze", d.defaultSnooze),
                defaultTabletStyle = enum("defaultTabletStyle", d.defaultTabletStyle, AlertStyle.entries.toTypedArray()),
                defaultOtherStyle = enum("defaultOtherStyle", d.defaultOtherStyle, AlertStyle.entries.toTypedArray()),
                repeatInterval = p.getInt("repeatInterval", d.repeatInterval),
                repeatMax = p.getInt("repeatMax", d.repeatMax),
                escalate = p.getBoolean("escalate", d.escalate),
                quietEnabled = p.getBoolean("quietEnabled", d.quietEnabled),
                quietStart = time("quietStart", d.quietStart),
                quietEnd = time("quietEnd", d.quietEnd),
                quietAlarmsToo = p.getBoolean("quietAlarmsToo", d.quietAlarmsToo),
                hideNames = p.getBoolean("hideNames", d.hideNames),
                lateAfterMinutes = p.getInt("lateAfterMinutes", d.lateAfterMinutes),
                missedAfterMinutes = p.getInt("missedAfterMinutes", d.missedAfterMinutes),
                alarmStartVolume = p.getInt("alarmStartVolume", d.alarmStartVolume),
                alarmRampSeconds = p.getInt("alarmRampSeconds", d.alarmRampSeconds),
                alarmMaxVolume = p.getInt("alarmMaxVolume", d.alarmMaxVolume),
                forceAlarmVolume = p.getBoolean("forceAlarmVolume", d.forceAlarmVolume),
                dndBypass = p.getBoolean("dndBypass", d.dndBypass),
                ringMinutes = p.getInt("ringMinutes", d.ringMinutes),
                doctorName = p.getString("doctorName", d.doctorName) ?: "",
                prescribedDate = p.getLong("prescribedDate", Long.MIN_VALUE)
                    .takeIf { it != Long.MIN_VALUE }?.let(LocalDate::ofEpochDay),
                dietNote = p.getString("dietNote", d.dietNote) ?: "",
                appLock = p.getBoolean("appLock", d.appLock),
                pinHash = p.getString("pinHash", d.pinHash) ?: "",
                biometric = p.getBoolean("biometric", d.biometric),
                journalReminder = p.getBoolean("journalReminder", d.journalReminder),
                journalDay = p.getInt("journalDay", d.journalDay),
                journalTime = time("journalTime", d.journalTime),
                onboardingDone = p.getBoolean("onboardingDone", d.onboardingDone),
                seeded = p.getBoolean("seeded", d.seeded),
            )
        }

        private fun write(p: SharedPreferences, s: AppSettings) {
            p.edit()
                .putString("themeMode", s.themeMode.name)
                .putInt("accent", s.accent)
                .putString("language", s.language)
                .putBoolean("use24h", s.use24h)
                .putBoolean("largeText", s.largeText)
                .putString("snoozeOptions", s.snoozeOptions.joinToString(","))
                .putInt("defaultSnooze", s.defaultSnooze)
                .putString("defaultTabletStyle", s.defaultTabletStyle.name)
                .putString("defaultOtherStyle", s.defaultOtherStyle.name)
                .putInt("repeatInterval", s.repeatInterval)
                .putInt("repeatMax", s.repeatMax)
                .putBoolean("escalate", s.escalate)
                .putBoolean("quietEnabled", s.quietEnabled)
                .putInt("quietStart", s.quietStart.hour * 60 + s.quietStart.minute)
                .putInt("quietEnd", s.quietEnd.hour * 60 + s.quietEnd.minute)
                .putBoolean("quietAlarmsToo", s.quietAlarmsToo)
                .putBoolean("hideNames", s.hideNames)
                .putInt("lateAfterMinutes", s.lateAfterMinutes)
                .putInt("missedAfterMinutes", s.missedAfterMinutes)
                .putInt("alarmStartVolume", s.alarmStartVolume)
                .putInt("alarmRampSeconds", s.alarmRampSeconds)
                .putInt("alarmMaxVolume", s.alarmMaxVolume)
                .putBoolean("forceAlarmVolume", s.forceAlarmVolume)
                .putBoolean("dndBypass", s.dndBypass)
                .putInt("ringMinutes", s.ringMinutes)
                .putString("doctorName", s.doctorName)
                .putLong("prescribedDate", s.prescribedDate?.toEpochDay() ?: Long.MIN_VALUE)
                .putString("dietNote", s.dietNote)
                .putBoolean("appLock", s.appLock)
                .putString("pinHash", s.pinHash)
                .putBoolean("biometric", s.biometric)
                .putBoolean("journalReminder", s.journalReminder)
                .putInt("journalDay", s.journalDay)
                .putInt("journalTime", s.journalTime.hour * 60 + s.journalTime.minute)
                .putBoolean("onboardingDone", s.onboardingDone)
                .putBoolean("seeded", s.seeded)
                .apply()
        }
    }
}
