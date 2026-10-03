package com.essential.app.notify

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.essential.app.core.Days
import com.essential.app.core.Hooks
import com.essential.app.core.TimeUtil
import com.essential.app.data.Habit
import com.essential.app.data.HabitUnit
import com.essential.app.data.Repo
import com.essential.app.data.UserAlarm
import com.essential.app.ui.AlarmRingActivity
import com.essential.app.ui.MainActivity
import java.time.LocalDate

/**
 * Your own alarms (wake up, pranayam, sleep…), each daily, on chosen days or once.
 * Uses setAlarmClock — the same Doze-proof call clock apps use — and arms only the next one.
 */
object UserAlarms {
    private const val RC = 6
    const val ACTION = "com.essential.app.USER_ALARM"
    const val ID_BASE = 5000
    val DAY_SHORT = listOf("M", "T", "W", "T", "F", "S", "S")
    val DAY_NAMES = listOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
    const val WEEKDAYS = 0b0011111
    const val WEEKENDS = 0b1100000

    fun bit(d: LocalDate) = 1 shl (d.dayOfWeek.value - 1)

    fun daysText(x: UserAlarm): String = when {
        x.once -> x.onceDate?.let { d -> val date = LocalDate.parse(d); val today = TimeUtil.now().toLocalDate()
            "Once · " + when (date) { today -> "today"; today.plusDays(1) -> "tomorrow"; else -> TimeUtil.fmtDay(date) } } ?: "Once"
        x.days == UserAlarm.EVERY_DAY -> "Every day"
        x.days == WEEKDAYS -> "Mon–Fri"
        x.days == WEEKENDS -> "Sat, Sun"
        else -> (0..6).filter { x.days and (1 shl it) != 0 }.joinToString(", ") { DAY_NAMES[it] }
    }

    private fun millis(d: LocalDate, minute: Int) = d.atTime(minute / 60, minute % 60).atZone(TimeUtil.zone).toInstant().toEpochMilli()

    /** The date a one-time alarm set now for [minute] should ring: today if still ahead, else tomorrow. */
    fun onceDateFor(minute: Int, nowMs: Long = TimeUtil.nowMillis()): LocalDate {
        val today = TimeUtil.at(nowMs).toLocalDate()
        return if (millis(today, minute) > nowMs) today else today.plusDays(1)
    }

    /** Next time this alarm rings after [fromMs], or null if it is off or a past one-time alarm. */
    fun nextFire(x: UserAlarm, fromMs: Long): Long? {
        if (!x.enabled) return null
        if (x.once) return x.onceDate?.let { millis(LocalDate.parse(it), x.minute) }?.takeIf { it > fromMs }
        if (x.days and UserAlarm.EVERY_DAY == 0) return null
        val start = TimeUtil.at(fromMs).toLocalDate()
        for (i in 0..7) {
            val d = start.plusDays(i.toLong())
            if (x.days and bit(d) == 0) continue
            val t = millis(d, x.minute)
            if (t > fromMs) return t
        }
        return null
    }

    /** "Rings in 7 h 20 min" — shown after saving, like a clock app. */
    fun ringsIn(at: Long, now: Long = TimeUtil.nowMillis()): String {
        val m = ((at - now + 59_999) / 60_000).coerceAtLeast(1)
        val d = m / (24 * 60); val h = (m / 60) % 24; val mm = m % 60
        return "Rings in " + listOfNotNull(d.takeIf { it > 0 }?.let { "$it d" }, h.takeIf { it > 0 }?.let { "$it h" }, mm.takeIf { it > 0 || (d == 0L && h == 0L) }?.let { "$it min" }).joinToString(" ")
    }

    // ------------------------------------------------------------ snoozes ("id@at;id@at")
    private fun snoozes(repo: Repo): List<Pair<Long, Long>> = repo.settings.str("ua_snoozes").split(';').mapNotNull {
        val p = it.split('@'); if (p.size == 2) (p[0].toLongOrNull() ?: return@mapNotNull null) to (p[1].toLongOrNull() ?: return@mapNotNull null) else null
    }
    private fun saveSnoozes(repo: Repo, l: List<Pair<Long, Long>>) = repo.settings.set("ua_snoozes", l.joinToString(";") { "${it.first}@${it.second}" })
    fun snoozedUntil(ctx: Context, id: Long): Long? = snoozes(Repo.get(ctx)).filter { it.first == id }.maxOfOrNull { it.second }

    /** Earliest upcoming ring (alarm or snooze), with the alarm. */
    fun next(ctx: Context, now: Long = TimeUtil.nowMillis()): Pair<UserAlarm, Long>? {
        val repo = Repo.get(ctx)
        val all = repo.alarms()
        val cands = all.mapNotNull { x -> nextFire(x, now)?.let { x to it } } +
            snoozes(repo).filter { it.second > now }.mapNotNull { (id, at) -> all.firstOrNull { it.id == id }?.let { it to at } }
        return cands.minByOrNull { it.second }
    }

    private fun pi(ctx: Context): PendingIntent = PendingIntent.getBroadcast(ctx, RC,
        Intent(ctx, AlarmReceiver::class.java).setAction(ACTION), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    /** Arm the next alarm. Called with every other re-arm (boot, update, time change, edits). */
    fun schedule(ctx: Context) {
        val repo = Repo.get(ctx)
        val am = Alarms.am(ctx)
        val n = next(ctx)
        if (n == null) { am.cancel(pi(ctx)); repo.settings.set("ua_next_at", 0L); return }
        repo.settings.set("ua_next_at", n.second)
        val show = Notifier.openApp(ctx, "alarms", 98)
        try {
            if (Alarms.canExact(ctx)) am.setAlarmClock(AlarmManager.AlarmClockInfo(n.second, show), pi(ctx))
            else am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, n.second, pi(ctx))
        } catch (e: SecurityException) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, n.second, pi(ctx))
        }
    }

    /** After you add, edit or switch an alarm: never ring for a time that already passed. */
    fun changed(ctx: Context) {
        val s = Repo.get(ctx).settings
        s.set("ua_last", maxOf(s.long("ua_last"), TimeUtil.nowMillis()))
        schedule(ctx)
    }

    /** Ring everything due since the last check (nothing older than 30 minutes). */
    fun handleDue(ctx: Context) {
        val repo = Repo.get(ctx)
        val now = TimeUtil.nowMillis()
        val last = repo.settings.long("ua_last").coerceAtLeast(now - 30 * 60_000L)
        val upto = now + 30_000L
        repo.settings.set("ua_last", upto)
        val all = repo.alarms()
        val ring = LinkedHashSet<Long>()
        for (x in all) {
            val t = nextFire(x, last) ?: continue
            if (t <= upto) { ring.add(x.id); if (x.once) repo.setAlarmEnabled(x.id, false) }
        }
        val (due, later) = snoozes(repo).partition { it.second <= upto }
        saveSnoozes(repo, later.filter { s -> all.any { it.id == s.first } })
        due.forEach { ring.add(it.first) }
        ring.forEach { id -> all.firstOrNull { it.id == id }?.let { ring(ctx, it) } }
        if (ring.isNotEmpty()) Hooks.afterChange(ctx)
    }

    fun title(repo: Repo, x: UserAlarm): String = x.label.ifBlank { x.habitId?.let { repo.habit(it)?.name } ?: "Alarm" }

    /** One line about the habit: "Pranayam · 15 minutes today" or "Already done today". */
    fun habitLine(repo: Repo, h: Habit): String {
        val today = Days.today(repo)
        if (h.id in repo.habitDone(today)) return "${h.name} · already done today"
        val t = h.target?.takeIf { it > 0 && h.measured }
        return if (t != null) "${h.name} · ${HabitUnit.fmt(h.unit, t)} today" else "Time for ${h.name}"
    }

    fun ring(ctx: Context, x: UserAlarm) {
        val repo = Repo.get(ctx)
        val habit = x.habitId?.let { repo.habit(it) }
        val title = title(repo, x)
        val text = listOfNotNull(TimeUtil.fmtTimeFull(x.minute), habit?.let { habitLine(repo, it) }).joinToString(" · ")
        if (Notifier.canPost(ctx)) Notifier.userAlarm(ctx, x, title, text, habit)
        else if (x.rings) try {
            // Notifications are off: best effort, open the alarm screen, which then rings by itself.
            ctx.startActivity(Intent(ctx, AlarmRingActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                .putExtra(AlarmRingActivity.EXTRA_ID, x.id).putExtra(AlarmRingActivity.EXTRA_SELF_SOUND, true))
        } catch (_: Exception) { }
    }

    fun stop(ctx: Context, id: Long) = Notifier.nm(ctx).cancel((ID_BASE + id).toInt())

    fun snooze(ctx: Context, id: Long): Long {
        val repo = Repo.get(ctx)
        val x = repo.alarm(id) ?: return 0
        stop(ctx, id)
        val at = TimeUtil.nowMillis() + x.snoozeMin * 60_000L
        saveSnoozes(repo, snoozes(repo).filter { it.first != id } + (id to at))
        schedule(ctx)
        return at
    }

    /** Cancel a pending snooze (e.g. the alarm was turned off or deleted). */
    fun clearSnooze(ctx: Context, id: Long) {
        val repo = Repo.get(ctx)
        saveSnoozes(repo, snoozes(repo).filter { it.first != id })
    }

    /** "Mark done" from an alarm: measured habits log their daily target (if set), others are ticked. */
    fun markHabitDone(ctx: Context, habitId: Long): String? {
        val repo = Repo.get(ctx)
        val h = repo.habit(habitId) ?: return null
        val today = Days.today(repo)
        val t = h.target?.takeIf { it > 0 && h.measured }
        if (t != null) {
            val got = repo.amount(h.id, today, today)
            if (got < t) repo.logAmount(h, today, t - got, note = "Alarm")
            repo.setHabit(h.id, today, true)
        } else repo.setHabit(h.id, today, true)
        Hooks.afterChange(ctx)
        return h.name
    }

    fun openAlarms(ctx: Context) = ctx.startActivity(Intent(ctx, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK).putExtra("route", "alarms"))
}
