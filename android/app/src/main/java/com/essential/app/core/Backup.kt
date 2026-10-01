package com.essential.app.core

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.MediaStore
import com.essential.app.data.Db
import com.essential.app.data.Repo
import com.essential.app.data.Settings
import com.essential.app.share.ShareProvider
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.time.LocalDate

/** One-file JSON backup of every table, restore, and CSV exports. All local. */
object Backup {
    const val FORMAT = "essential-backup"
    const val VERSION = 1

    fun exportJson(ctx: Context): String {
        val db = Db.get(ctx)
        val root = JSONObject()
        root.put("format", FORMAT); root.put("version", VERSION); root.put("schema", Db.VERSION)
        root.put("exported_at", System.currentTimeMillis())
        val tables = JSONObject()
        for (t in Db.TABLES) {
            val arr = JSONArray()
            db.w.rawQuery("SELECT * FROM $t", null).use { c ->
                while (c.moveToNext()) {
                    val o = JSONObject()
                    for (i in 0 until c.columnCount) {
                        val name = c.getColumnName(i)
                        when (c.getType(i)) {
                            android.database.Cursor.FIELD_TYPE_NULL -> o.put(name, JSONObject.NULL)
                            android.database.Cursor.FIELD_TYPE_INTEGER -> o.put(name, c.getLong(i))
                            android.database.Cursor.FIELD_TYPE_FLOAT -> o.put(name, c.getDouble(i))
                            else -> o.put(name, c.getString(i))
                        }
                    }
                    arr.put(o)
                }
            }
            tables.put(t, arr)
        }
        root.put("tables", tables)
        return root.toString()
    }

    fun fileName(): String = "essential-backup-${LocalDate.now(TimeUtil.zone)}.json"

    /** Save to Downloads (no permission needed on Android 10+). Returns a display path. */
    fun saveToDownloads(ctx: Context, name: String, mime: String, bytes: ByteArray): Uri? {
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            put(MediaStore.MediaColumns.RELATIVE_PATH, "Download/Essential")
        }
        val uri = ctx.contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values) ?: return null
        ctx.contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
        return uri
    }

    /** Write a file into the share cache and return a content:// Uri for the share sheet. */
    fun shareFile(ctx: Context, name: String, bytes: ByteArray): Uri {
        val dir = File(ctx.cacheDir, "share").apply { mkdirs() }
        File(dir, name).writeBytes(bytes)
        return ShareProvider.uriFor(ctx, name)
    }

    data class Exported(val downloads: Uri?, val share: Uri, val name: String)

    fun export(ctx: Context): Exported {
        val bytes = exportJson(ctx).toByteArray()
        val name = fileName()
        val dl = try { saveToDownloads(ctx, name, "application/json", bytes) } catch (e: Exception) { null }
        return Exported(dl, shareFile(ctx, name, bytes), name)
    }

    /** Replace all data with the backup's. Throws IllegalArgumentException for a wrong file. */
    fun restore(ctx: Context, uri: Uri) {
        val text = ctx.contentResolver.openInputStream(uri)?.use { it.readBytes().toString(Charsets.UTF_8) }
            ?: throw IllegalArgumentException("Couldn't read the file")
        restoreJson(ctx, text)
    }

    fun restoreJson(ctx: Context, text: String) {
        val root = try { JSONObject(text) } catch (e: Exception) { throw IllegalArgumentException("This isn't an Essential backup file") }
        if (root.optString("format") != FORMAT) throw IllegalArgumentException("This isn't an Essential backup file")
        val tables = root.getJSONObject("tables")
        val db = Db.get(ctx)
        db.tx {
            for (t in Db.TABLES) {
                db.w.delete(t, null, null)
                val arr = tables.optJSONArray(t) ?: continue
                val cols = db.query("PRAGMA table_info($t)") { it.getString(1) }.toSet()
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    val cv = ContentValues()
                    for (k in o.keys()) {
                        if (k !in cols) continue
                        when (val v = o.get(k)) {
                            JSONObject.NULL -> cv.putNull(k)
                            is Int -> cv.put(k, v.toLong())
                            is Long -> cv.put(k, v)
                            is Double -> cv.put(k, v)
                            is Boolean -> cv.put(k, if (v) 1 else 0)
                            else -> cv.put(k, v.toString())
                        }
                    }
                    db.w.insert(t, null, cv)
                }
            }
        }
        Settings.reset()
        Repo.get(ctx).settings.set("onboarded", true)
        Hooks.scheduleChanged(ctx)
    }

    /** Weekly automatic backup into the folder chosen in Settings. Returns the file name. */
    fun autoBackup(ctx: Context): String? {
        val s = Repo.get(ctx).settings
        val tree = s.str("backup_tree_uri").takeIf { it.isNotEmpty() }?.let { Uri.parse(it) } ?: return null
        val dirId = DocumentsContract.getTreeDocumentId(tree)
        val dirUri = DocumentsContract.buildDocumentUriUsingTree(tree, dirId)
        val name = fileName()
        val doc = DocumentsContract.createDocument(ctx.contentResolver, dirUri, "application/json", name) ?: return null
        ctx.contentResolver.openOutputStream(doc)?.use { it.write(exportJson(ctx).toByteArray()) }
        s.set("last_auto_backup", System.currentTimeMillis())
        return name
    }

    // ------------------------------------------------------------------ CSV
    private fun esc(v: Any?): String {
        val s = v?.toString() ?: ""
        return if (s.contains(',') || s.contains('"') || s.contains('\n')) "\"" + s.replace("\"", "\"\"") + "\"" else s
    }

    private fun csv(header: List<String>, rows: List<List<Any?>>): ByteArray =
        (header.joinToString(",") + "\n" + rows.joinToString("\n") { r -> r.joinToString(",") { esc(it) } } + "\n").toByteArray()

    fun csvFiles(ctx: Context): Map<String, ByteArray> {
        val repo = Repo.get(ctx)
        val from = LocalDate.of(2000, 1, 1); val to = LocalDate.of(2100, 1, 1)
        val ventures = repo.ventures(true).associate { it.id to it.name }
        val out = LinkedHashMap<String, ByteArray>()
        out["hour_logs.csv"] = csv(listOf("date", "hour", "minutes", "activity", "category", "venture", "type", "focus", "energy",
            "followed_plan", "off_plan_reason", "money_inr", "money_note", "source"),
            repo.logsRange(from, to).map { listOf(it.date, TimeUtil.fmtHourRange(it.hour), it.minutes, it.activity, it.category,
                ventures[it.ventureId], it.type, it.focus, it.energy, it.followedPlan, it.offPlanReason, it.money, it.moneyNote, it.source) })
        out["trades.csv"] = csv(listOf("date", "time", "instrument", "direction", "entry", "exit", "qty", "pnl_inr", "rules_followed",
            "emotion", "checklist_passed", "note"),
            repo.trades(from, to).map { listOf(it.date, TimeUtil.fmtClock(TimeUtil.at(it.ts)), it.instrument, it.direction, it.entry, it.exit,
                it.qty, it.pnl, if (it.rulesFollowed) "Y" else "N", it.emotion, if (it.checklistPassed) "Y" else "N", it.note) })
        out["reviews.csv"] = csv(listOf("date", "one_thing_done", "small_win", "trivial_to_cut", "headline", "rating", "tomorrow_one_thing"),
            repo.reviews(from, to).map { listOf(it.date, if (it.oneThingDone) "Y" else "N", it.smallWin, it.trivialToCut, it.headline, it.rating, it.tomorrowOneThing) })
        val habits = repo.habits(false).associate { it.id to it.name }
        out["habits.csv"] = csv(listOf("date", "habit", "done"),
            repo.db.query("SELECT habit_id, date, done FROM habit_log ORDER BY date") { listOf(it.getString(1), habits[it.getLong(0)], if (it.getInt(2) == 1) "Y" else "N") })
        out["sleep.csv"] = csv(listOf("date", "bedtime", "wake_time", "hours", "quality"),
            repo.sleepLogs(from, to).map { listOf(it.date, TimeUtil.fmtTimeFull(it.bedtime), TimeUtil.fmtTimeFull(it.wake), TimeUtil.fmtHours(it.hours), it.quality) })
        return out
    }

    fun exportCsv(ctx: Context): List<Uri> {
        val files = csvFiles(ctx)
        val stamp = LocalDate.now(TimeUtil.zone).toString()
        return files.map { (name, bytes) ->
            val n = name.replace(".csv", "-$stamp.csv")
            try { saveToDownloads(ctx, n, "text/csv", bytes) } catch (_: Exception) { }
            shareFile(ctx, n, bytes)
        }
    }
}
