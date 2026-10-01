package com.essential.app.data

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import com.essential.app.core.TimeUtil

/**
 * Local SQLite store. Everything the app knows lives here (including settings),
 * so a single backup file captures the whole app.
 *
 * Every user table carries `updated_at` (epoch millis) and `is_sample` so that a
 * future optional sync layer can diff rows, and sample data can be cleared.
 */
class Db private constructor(ctx: Context) : SQLiteOpenHelper(ctx, NAME, null, VERSION) {

    companion object {
        const val NAME = "essential.db"
        const val VERSION = 1

        @Volatile private var inst: Db? = null
        fun get(ctx: Context): Db = inst ?: synchronized(this) {
            inst ?: Db(ctx.applicationContext).also { inst = it }
        }

        /** Drop cached singletons (tests). */
        fun resetForTests() { inst?.close(); inst = null; Repo.resetForTests(); Settings.reset() }

        /** Tables included in backups, in restore order. */
        val TABLES = listOf(
            "settings", "venture", "goal", "milestone", "template", "block", "sprint", "day_plan",
            "hour_log", "focus_session", "distraction", "daily_review", "habit", "habit_log",
            "sleep_log", "opportunity", "no_log", "commitment", "uncommit_review", "task_estimate",
            "obstacle", "trade", "keyword_rule"
        )

        private val SCHEMA = listOf(
            "CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)",
            """CREATE TABLE venture(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, color INTEGER NOT NULL,
               archived INTEGER NOT NULL DEFAULT 0, sort INTEGER NOT NULL DEFAULT 0, is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE goal(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, type TEXT NOT NULL,
               start_date TEXT NOT NULL, end_date TEXT NOT NULL, progress INTEGER NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'active',
               is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE milestone(id INTEGER PRIMARY KEY AUTOINCREMENT, goal_id INTEGER NOT NULL, title TEXT NOT NULL,
               done INTEGER NOT NULL DEFAULT 0, done_date TEXT, sort INTEGER NOT NULL DEFAULT 0, is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE template(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, mode TEXT NOT NULL,
               assigned_weekdays TEXT NOT NULL DEFAULT '', sort INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE block(id INTEGER PRIMARY KEY AUTOINCREMENT, template_id INTEGER NOT NULL, start_time INTEGER NOT NULL,
               end_time INTEGER NOT NULL, title TEXT NOT NULL, category TEXT NOT NULL, venture_id INTEGER,
               is_protected INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE sprint(id INTEGER PRIMARY KEY AUTOINCREMENT, goal TEXT NOT NULL, start_date TEXT NOT NULL,
               end_date TEXT NOT NULL, status TEXT NOT NULL, recovery_end_date TEXT, report_seen INTEGER NOT NULL DEFAULT 0,
               is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE day_plan(date TEXT PRIMARY KEY, template_id INTEGER, mode TEXT, one_thing TEXT, task_2 TEXT, task_3 TEXT,
               one_done INTEGER NOT NULL DEFAULT 0, task_2_done INTEGER NOT NULL DEFAULT 0, task_3_done INTEGER NOT NULL DEFAULT 0,
               is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE hour_log(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, hour_start INTEGER NOT NULL,
               minutes INTEGER NOT NULL DEFAULT 60, activity TEXT NOT NULL, category TEXT, venture_id INTEGER, type TEXT NOT NULL,
               focus INTEGER, energy INTEGER, followed_plan TEXT, off_plan_reason TEXT, money_amount REAL, money_note TEXT,
               source TEXT NOT NULL, logged_at INTEGER NOT NULL, is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            "CREATE INDEX hour_log_date ON hour_log(date, hour_start)",
            """CREATE TABLE focus_session(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, start INTEGER NOT NULL, end INTEGER,
               planned_minutes INTEGER NOT NULL, task TEXT, interruptions INTEGER NOT NULL DEFAULT 0, completed INTEGER NOT NULL DEFAULT 0,
               is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE distraction(id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp INTEGER NOT NULL, date TEXT NOT NULL, reason TEXT,
               is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE daily_review(date TEXT PRIMARY KEY, one_thing_done INTEGER NOT NULL DEFAULT 0, small_win TEXT, trivial_to_cut TEXT,
               headline TEXT, day_rating INTEGER, tomorrow_one_thing TEXT, is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE habit(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, trigger TEXT, active INTEGER NOT NULL DEFAULT 1,
               sort INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE habit_log(habit_id INTEGER NOT NULL, date TEXT NOT NULL, done INTEGER NOT NULL DEFAULT 1,
               is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(habit_id, date))""",
            """CREATE TABLE sleep_log(date TEXT PRIMARY KEY, bedtime INTEGER NOT NULL, wake_time INTEGER NOT NULL, quality INTEGER NOT NULL,
               is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE opportunity(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, score_fit INTEGER NOT NULL,
               score_money INTEGER NOT NULL, score_strengths INTEGER NOT NULL, score_energy INTEGER NOT NULL, give_up_answer TEXT NOT NULL,
               total_score INTEGER NOT NULL, decision TEXT NOT NULL, created TEXT NOT NULL, review_date TEXT,
               is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE no_log(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, what TEXT NOT NULL, hours_saved REAL NOT NULL,
               is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE commitment(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, active INTEGER NOT NULL DEFAULT 1,
               updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE uncommit_review(id INTEGER PRIMARY KEY AUTOINCREMENT, month TEXT NOT NULL, item TEXT NOT NULL, venture_id INTEGER,
               would_start TEXT, decision TEXT, follow_up_done INTEGER NOT NULL DEFAULT 0, is_sample INTEGER NOT NULL DEFAULT 0,
               updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE task_estimate(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, date TEXT NOT NULL,
               estimated_minutes INTEGER NOT NULL, actual_minutes INTEGER, is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE obstacle(id INTEGER PRIMARY KEY AUTOINCREMENT, week TEXT NOT NULL, obstacle TEXT NOT NULL, action TEXT,
               resolved INTEGER, is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE trade(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, ts INTEGER NOT NULL, instrument TEXT NOT NULL,
               direction TEXT NOT NULL, entry REAL, exit REAL, qty REAL, pnl REAL NOT NULL, rules_followed INTEGER NOT NULL,
               emotion TEXT, checklist_passed INTEGER NOT NULL, note TEXT, is_sample INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0)""",
            """CREATE TABLE keyword_rule(id INTEGER PRIMARY KEY AUTOINCREMENT, keywords TEXT NOT NULL, category TEXT, venture_id INTEGER,
               type TEXT, updated_at INTEGER NOT NULL DEFAULT 0)"""
        )
    }

    override fun onCreate(db: SQLiteDatabase) {
        SCHEMA.forEach { db.execSQL(it) }
        Seed.seed(db)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        // Future migrations go here, one `if (oldVersion < N)` step at a time.
    }

    override fun onConfigure(db: SQLiteDatabase) {
        db.setForeignKeyConstraintsEnabled(false)
    }

    val w: SQLiteDatabase get() = writableDatabase

    fun <T> query(sql: String, vararg args: Any?, map: (Cursor) -> T): List<T> {
        val out = ArrayList<T>()
        w.rawQuery(sql, args.map { it?.toString() }.toTypedArray()).use { c ->
            while (c.moveToNext()) out.add(map(c))
        }
        return out
    }

    fun <T> one(sql: String, vararg args: Any?, map: (Cursor) -> T): T? = query(sql, *args, map = map).firstOrNull()

    fun scalarD(sql: String, vararg args: Any?): Double =
        one(sql, *args) { if (it.isNull(0)) 0.0 else it.getDouble(0) } ?: 0.0

    fun scalarL(sql: String, vararg args: Any?): Long =
        one(sql, *args) { if (it.isNull(0)) 0L else it.getLong(0) } ?: 0L

    fun insert(table: String, cv: ContentValues): Long {
        stamp(table, cv)
        return w.insertOrThrow(table, null, cv)
    }

    fun upsert(table: String, cv: ContentValues): Long {
        stamp(table, cv)
        return w.insertWithOnConflict(table, null, cv, SQLiteDatabase.CONFLICT_REPLACE)
    }

    fun update(table: String, cv: ContentValues, where: String, vararg args: Any?): Int {
        stamp(table, cv)
        return w.update(table, cv, where, args.map { it?.toString() }.toTypedArray())
    }

    fun delete(table: String, where: String, vararg args: Any?): Int =
        w.delete(table, where, args.map { it?.toString() }.toTypedArray())

    fun exec(sql: String, vararg args: Any?) = w.execSQL(sql, args)

    fun tx(block: () -> Unit) {
        val d = w
        d.beginTransaction()
        try { block(); d.setTransactionSuccessful() } finally { d.endTransaction() }
    }

    private fun stamp(table: String, cv: ContentValues) {
        if (table != "settings" && !cv.containsKey("updated_at")) cv.put("updated_at", TimeUtil.nowMillis())
    }
}

fun cv(vararg pairs: Pair<String, Any?>): ContentValues {
    val c = ContentValues()
    for ((k, v) in pairs) when (v) {
        null -> c.putNull(k)
        is String -> c.put(k, v)
        is Int -> c.put(k, v)
        is Long -> c.put(k, v)
        is Double -> c.put(k, v)
        is Float -> c.put(k, v.toDouble())
        is Boolean -> c.put(k, if (v) 1 else 0)
        else -> c.put(k, v.toString())
    }
    return c
}

fun Cursor.str(col: String): String? { val i = getColumnIndexOrThrow(col); return if (isNull(i)) null else getString(i) }
fun Cursor.s(col: String): String = str(col) ?: ""
fun Cursor.int(col: String): Int { val i = getColumnIndexOrThrow(col); return if (isNull(i)) 0 else getInt(i) }
fun Cursor.intN(col: String): Int? { val i = getColumnIndexOrThrow(col); return if (isNull(i)) null else getInt(i) }
fun Cursor.lng(col: String): Long { val i = getColumnIndexOrThrow(col); return if (isNull(i)) 0L else getLong(i) }
fun Cursor.lngN(col: String): Long? { val i = getColumnIndexOrThrow(col); return if (isNull(i)) null else getLong(i) }
fun Cursor.dbl(col: String): Double { val i = getColumnIndexOrThrow(col); return if (isNull(i)) 0.0 else getDouble(i) }
fun Cursor.dblN(col: String): Double? { val i = getColumnIndexOrThrow(col); return if (isNull(i)) null else getDouble(i) }
fun Cursor.bool(col: String): Boolean = int(col) != 0
