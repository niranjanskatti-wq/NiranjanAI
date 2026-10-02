package com.essential.app.notify

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.essential.app.core.Backup
import com.essential.app.core.Focus
import com.essential.app.core.HabitTimer
import com.essential.app.core.Hooks
import com.essential.app.core.TimeUtil
import com.essential.app.data.Repo
import com.essential.app.ui.MainActivity
import java.time.LocalDate

/**
 * Exact, Doze-proof alarms. Only the next event is armed at any time; it is re-armed after
 * every fire, boot, app update, time/zone change and any schedule edit.
 */
object Alarms {
    private const val RC_NEXT = 1
    private const val RC_SNOOZE = 2
    private const val RC_FOCUS = 3
    private const val RC_HTIMER = 5
    const val ACTION_FIRE = "com.essential.app.ALARM_FIRE"
    const val ACTION_SNOOZE = "com.essential.app.ALARM_SNOOZE"
    const val ACTION_FOCUS_END = "com.essential.app.FOCUS_END"
    const val ACTION_HTIMER_END = "com.essential.app.HABIT_TIMER_END"

    fun am(ctx: Context): AlarmManager = ctx.getSystemService(AlarmManager::class.java)

    fun canExact(ctx: Context): Boolean = Build.VERSION.SDK_INT < 31 || am(ctx).canScheduleExactAlarms()

    private fun pi(ctx: Context, rc: Int, action: String, extras: Intent.() -> Unit = {}): PendingIntent {
        val i = Intent(ctx, AlarmReceiver::class.java).setAction(action).apply(extras)
        return PendingIntent.getBroadcast(ctx, rc, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    private fun setExact(ctx: Context, at: Long, op: PendingIntent) {
        val am = am(ctx)
        val repo = Repo.get(ctx)
        try {
            when {
                !canExact(ctx) -> am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, op)
                repo.settings.bool("alarm_clock_mode") -> {
                    val show = PendingIntent.getActivity(ctx, 99, Intent(ctx, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
                    am.setAlarmClock(AlarmManager.AlarmClockInfo(at, show), op)
                }
                else -> am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, op)
            }
        } catch (e: SecurityException) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, op)
        }
    }

    /** Arm the next reminder. Safe to call often. */
    fun schedule(ctx: Context) {
        val repo = Repo.get(ctx)
        if (!repo.settings.bool("onboarded")) return
        val now = TimeUtil.nowMillis()
        val next = Planner.events(repo, now).firstOrNull() ?: return
        repo.settings.set("next_alarm_at", next.at)
        setExact(ctx, next.at, pi(ctx, RC_NEXT, ACTION_FIRE))
    }

    fun snooze(ctx: Context, date: LocalDate, hour: Int) {
        setExact(ctx, TimeUtil.nowMillis() + 10 * 60_000L, pi(ctx, RC_SNOOZE, ACTION_SNOOZE) {
            putExtra("date", date.toString()); putExtra("hour", hour)
        })
    }

    fun scheduleFocusEnd(ctx: Context, at: Long) = setExact(ctx, at, pi(ctx, RC_FOCUS, ACTION_FOCUS_END))
    fun cancelFocusEnd(ctx: Context) = am(ctx).cancel(pi(ctx, RC_FOCUS, ACTION_FOCUS_END))
    fun scheduleHabitTimerEnd(ctx: Context, at: Long) = setExact(ctx, at, pi(ctx, RC_HTIMER, ACTION_HTIMER_END))
    fun cancelHabitTimerEnd(ctx: Context) = am(ctx).cancel(pi(ctx, RC_HTIMER, ACTION_HTIMER_END))

    /** Handle everything due since the last fire (skipping anything older than 20 minutes). */
    fun handleDue(ctx: Context) {
        val repo = Repo.get(ctx)
        val now = TimeUtil.nowMillis()
        val last = repo.settings.long("last_alarm_handled").coerceAtLeast(now - 20 * 60_000L)
        val due = Planner.events(repo, last - 1).filter { it.at in (last + 1)..(now + 30_000L) }
        repo.settings.set("last_alarm_handled", now + 30_000L)
        for (ev in due) handle(ctx, repo, ev)
        Hooks.afterChange(ctx)
    }

    private fun handle(ctx: Context, repo: Repo, ev: Planner.Ev) {
        val quiet = Planner.inQuietHours(repo, ev.at)
        when (ev.kind) {
            Planner.K.CHECKIN -> if (!quiet && !Focus.isActive(ctx) && repo.logFor(ev.date, ev.hour) == null) Notifier.checkin(ctx, ev.date, ev.hour)
            Planner.K.BLOCK -> if (!quiet) Notifier.simple(ctx, Notifier.CH_BLOCK, 3001, "Next: ${ev.blockTitle}", "Starts at ${ev.text}", "now")
            Planner.K.REVIEW -> if (!quiet && repo.review(ev.date) == null) Notifier.simple(ctx, Notifier.CH_REVIEW, 3003, "Daily review", "Two minutes: one small win, one thing to cut, tomorrow's ONE thing.", "review")
            Planner.K.WIND -> if (!quiet) Notifier.simple(ctx, Notifier.CH_WIND, 3004, "Wind down", "Sleep in 15 minutes. Screens away; tomorrow is planned.", "now")
            Planner.K.SLEEP -> if (!quiet && repo.sleepLog(ev.date) == null) Notifier.simple(ctx, Notifier.CH_SLEEP, 3005, "Good morning", "How did you sleep? Log bedtime, wake time and quality.", "sleep")
            Planner.K.BACKUP -> {
                var auto: String? = null
                if (repo.settings.bool("backup_auto")) auto = try { Backup.autoBackup(ctx) } catch (e: Exception) { null }
                if (repo.settings.bool("n_backup") && !quiet) Notifier.simple(ctx, Notifier.CH_BACKUP, 3006, "Weekly backup",
                    if (auto != null) "Saved automatically: $auto" else "Export a backup to keep your data safe.", "backup")
            }
            Planner.K.OBSTACLE -> if (!quiet) Notifier.simple(ctx, Notifier.CH_TOOLS, 3007, "Weekly obstacle", "What one obstacle slowed your Essential Intent most this week?", "obstacle")
            Planner.K.REPORT -> if (!quiet) Notifier.simple(ctx, Notifier.CH_TOOLS, 3008, "Your weekly report is ready", "Under 200 words, made on your phone.", "report")
            Planner.K.UNCOMMIT -> if (!quiet) Notifier.simple(ctx, Notifier.CH_TOOLS, 3009, "Monthly uncommit review", "If you weren't already doing it, would you start it today? Also review your Not Now list.", "uncommit")
            Planner.K.FOLLOW_UP -> if (!quiet && repo.pendingFollowUps().isNotEmpty()) Notifier.simple(ctx, Notifier.CH_TOOLS, 3010, "Follow-through", "You decided to reduce or stop some commitments. Did it happen?", "uncommit")
            Planner.K.SPRINT_END -> {
                repo.closeFinishedSprints(ev.date)
                Notifier.simple(ctx, Notifier.CH_TOOLS, 3011, "Sprint complete: ${ev.text}", "Your Max vs Normal report is ready. One recovery week in Normal Mode starts now.", "sprint")
            }
            Planner.K.REFRESH -> {}
        }
    }
}

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        val pr: PendingResult? = goAsync()
        try {
            when (intent.action) {
                Alarms.ACTION_FIRE -> Alarms.handleDue(ctx)
                Alarms.ACTION_SNOOZE -> {
                    val date = LocalDate.parse(intent.getStringExtra("date") ?: return)
                    val hour = intent.getIntExtra("hour", -1)
                    if (hour >= 0 && Repo.get(ctx).logFor(date, hour) == null) Notifier.checkin(ctx, date, hour)
                }
                Alarms.ACTION_FOCUS_END -> Focus.finish(ctx, true)
                Alarms.ACTION_HTIMER_END -> HabitTimer.state(ctx)?.let { st -> if (!st.paused && !st.open && st.leftMs() <= 1500) HabitTimer.finish(ctx, save = true, completed = true) }
            }
        } finally {
            Alarms.schedule(ctx)
            pr?.finish()
        }
    }
}

/** Re-arm after reboot, app update, time or time-zone change, or exact-alarm permission change. */
class SystemEventReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        val repo = Repo.get(ctx)
        if (intent.action == Intent.ACTION_TIMEZONE_CHANGED || intent.action == Intent.ACTION_TIME_CHANGED) {
            repo.settings.set("last_alarm_handled", TimeUtil.nowMillis())
        }
        TimeUtil.zone = if (repo.settings.bool("use_ist")) TimeUtil.IST else java.time.ZoneId.systemDefault()
        Notifier.ensureChannels(ctx)
        HabitTimer.state(ctx)?.let { st ->
            if (!st.paused && !st.open) { if (st.leftMs() <= 0) HabitTimer.finish(ctx, save = true, completed = true) else Alarms.scheduleHabitTimerEnd(ctx, TimeUtil.nowMillis() + st.leftMs()) }
        }
        Focus.state(ctx)?.let { st -> if (!st.paused) { if (st.endAt <= TimeUtil.nowMillis()) Focus.finish(ctx, true) else Alarms.scheduleFocusEnd(ctx, st.endAt) } }
        Alarms.schedule(ctx)
        Hooks.afterChange(ctx)
    }
}
