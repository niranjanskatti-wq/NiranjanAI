package com.essential.app.data

import android.content.Context

/**
 * Typed settings stored in the `settings` table (so backups include them).
 * Values are cached in memory; writes go straight to SQLite.
 */
class Settings private constructor(private val db: Db) {
    companion object {
        @Volatile private var inst: Settings? = null
        fun get(ctx: Context): Settings = inst ?: synchronized(this) {
            inst ?: Settings(Db.get(ctx)).also { inst = it }
        }
        /** Drop the cache (after a restore). */
        fun reset() { inst = null }

        val DEFAULTS: Map<String, String> = mapOf(
            "onboarded" to "0", "theme" to "dark", "use_ist" to "1",
            "wake_normal" to "300", "sleep_normal" to "1320", "wake_max" to "270", "sleep_max" to "1380",
            "target_eh_normal" to "6", "target_work_normal" to "10", "target_eh_max" to "9", "target_work_max" to "14",
            "review_normal" to "1290", "review_max" to "1365",
            "n_checkin" to "1", "n_block" to "1", "n_review" to "1", "n_wind" to "1",
            "n_sleep" to "1", "n_backup" to "1", "n_tools" to "1",
            "quiet_enabled" to "0", "quiet_start" to "1380", "quiet_end" to "300",
            "alarm_clock_mode" to "0", "voice_lang" to "en-IN",
            "w_eh" to "35", "w_work" to "10", "w_one" to "15", "w_plan" to "15", "w_routine" to "15", "w_sleep" to "10",
            "backup_auto" to "0", "backup_tree_uri" to "", "last_auto_backup" to "0",
            "focus_dnd" to "0", "last_alarm_handled" to "0", "sample_loaded" to "0",
            "tabs" to "now,log,habits,insights,tools",
            "tab_order" to "now,log,habits,alarms,insights,tools,settings",
            "haptics" to "1"
        )
    }

    private val cache = HashMap<String, String?>()

    init {
        db.query("SELECT key, value FROM settings") { it.getString(0) to it.getString(1) }.forEach { cache[it.first] = it.second }
    }

    fun str(key: String): String = cache[key] ?: DEFAULTS[key] ?: ""
    fun strN(key: String): String? = cache[key] ?: DEFAULTS[key]
    fun int(key: String): Int = str(key).toIntOrNull() ?: DEFAULTS[key]?.toIntOrNull() ?: 0
    fun long(key: String): Long = str(key).toLongOrNull() ?: 0L
    fun dbl(key: String): Double = str(key).toDoubleOrNull() ?: 0.0
    fun bool(key: String): Boolean = str(key) == "1"

    fun set(key: String, value: Any?) {
        val v = when (value) { null -> null; is Boolean -> if (value) "1" else "0"; else -> value.toString() }
        cache[key] = v
        if (v == null) db.delete("settings", "key=?", key) else db.upsert("settings", cv("key" to key, "value" to v))
    }

    fun remove(key: String) = set(key, null)

    // Convenience accessors
    fun wake(mode: String) = int(if (mode == Mode.MAX) "wake_max" else "wake_normal")
    fun sleep(mode: String) = int(if (mode == Mode.MAX) "sleep_max" else "sleep_normal")
    fun targetEssential(mode: String) = dbl(if (mode == Mode.MAX) "target_eh_max" else "target_eh_normal")
    fun targetWork(mode: String) = dbl(if (mode == Mode.MAX) "target_work_max" else "target_work_normal")
    fun reviewTime(mode: String) = int(if (mode == Mode.MAX) "review_max" else "review_normal")
    val darkTheme get() = str("theme") != "light"
}
