package com.essential.app.notify

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.RemoteInput
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.widget.RemoteViews
import com.essential.app.R
import com.essential.app.core.Days
import com.essential.app.core.Focus
import com.essential.app.core.TimeUtil
import com.essential.app.data.Habit
import com.essential.app.data.HabitUnit
import com.essential.app.data.Repo
import com.essential.app.data.UserAlarm
import com.essential.app.ui.AlarmRingActivity
import com.essential.app.ui.FocusActivity
import com.essential.app.ui.MainActivity
import java.time.LocalDate

/** Builds every notification. One channel per type so each can be controlled in Android settings. */
object Notifier {
    const val CH_CHECKIN = "checkin"; const val CH_BLOCK = "block"; const val CH_REVIEW = "review"
    const val CH_WIND = "wind_down"; const val CH_SLEEP = "sleep_log"; const val CH_BACKUP = "backup"; const val CH_TOOLS = "tools"
    const val CH_FOCUS = "focus"; const val CH_TEST = "test"
    const val CH_HTIMER = "habit_timer"; const val CH_HTIMER_DONE = "habit_timer_done"; const val ID_HTIMER = 4100
    const val CH_ALARM = "user_alarm"; const val CH_ALARM_NV = "user_alarm_no_vibrate"; const val CH_HREMIND = "habit_reminder"
    const val ID_FOCUS = 4000
    const val KEY_REPLY = "reply"
    private const val ACCENT = 0xFF7FD1B9.toInt()

    fun nm(ctx: Context): NotificationManager = ctx.getSystemService(NotificationManager::class.java)

    fun ensureChannels(ctx: Context) {
        val nm = nm(ctx)
        fun ch(id: String, name: String, imp: Int, desc: String) {
            val c = NotificationChannel(id, name, imp); c.description = desc
            if (id == CH_FOCUS || id == CH_HTIMER) { c.setSound(null, null); c.enableVibration(false) }
            nm.createNotificationChannel(c)
        }
        ch(CH_CHECKIN, "Hourly check-in", NotificationManager.IMPORTANCE_HIGH, "Every hour: what did you do? Log it with one tap.")
        ch(CH_BLOCK, "Next block", NotificationManager.IMPORTANCE_DEFAULT, "5 minutes before each block starts")
        nm.deleteNotificationChannel("trade_stop") // trading removed in v2
        ch(CH_REVIEW, "Daily review", NotificationManager.IMPORTANCE_DEFAULT, "Evening review reminder")
        ch(CH_WIND, "Wind-down", NotificationManager.IMPORTANCE_DEFAULT, "15 minutes before sleep")
        ch(CH_SLEEP, "Morning sleep log", NotificationManager.IMPORTANCE_DEFAULT, "Log last night's sleep")
        ch(CH_BACKUP, "Weekly backup", NotificationManager.IMPORTANCE_LOW, "Backup reminders and automatic backups")
        ch(CH_TOOLS, "Reviews & reports", NotificationManager.IMPORTANCE_DEFAULT, "Weekly report, obstacle, monthly uncommit, sprints")
        ch(CH_FOCUS, "Focus session", NotificationManager.IMPORTANCE_LOW, "Ongoing focus timer")
        ch(CH_TEST, "Test", NotificationManager.IMPORTANCE_HIGH, "Test notification from Settings")
        ch(CH_HTIMER, "Habit timer", NotificationManager.IMPORTANCE_LOW, "Running meditation / pranayam timer")
        ch(CH_HTIMER_DONE, "Habit timer bell", NotificationManager.IMPORTANCE_HIGH, "Bell when a meditation / pranayam timer ends")
        ch(CH_HREMIND, "Gentle reminders", NotificationManager.IMPORTANCE_HIGH, "Your alarms set to \"gentle reminder\": one notification sound")
        val sound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM) ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
        val attrs = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
        for ((id, vib) in listOf(CH_ALARM to true, CH_ALARM_NV to false)) {
            val c = NotificationChannel(id, if (vib) "Alarms" else "Alarms (no vibration)", NotificationManager.IMPORTANCE_HIGH)
            c.description = "Your alarms: rings with the alarm sound until you stop or snooze it"
            c.setSound(sound, attrs); c.enableVibration(vib)
            if (vib) c.vibrationPattern = longArrayOf(0, 800, 600, 800, 600)
            c.setBypassDnd(true); c.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            nm.createNotificationChannel(c)
        }
    }

    fun openApp(ctx: Context, route: String, rc: Int, extras: Intent.() -> Unit = {}): PendingIntent {
        val i = Intent(ctx, MainActivity::class.java).setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            .putExtra("route", route).setAction("route.$route.$rc").apply(extras)
        return PendingIntent.getActivity(ctx, rc, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    fun action(ctx: Context, action: String, rc: Int, mutable: Boolean = false, extras: Intent.() -> Unit = {}): PendingIntent {
        val i = Intent(ctx, ActionReceiver::class.java).setAction(action).apply(extras)
        val flag = if (mutable) PendingIntent.FLAG_MUTABLE else PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(ctx, rc, i, PendingIntent.FLAG_UPDATE_CURRENT or flag)
    }

    private fun base(ctx: Context, ch: String): Notification.Builder =
        Notification.Builder(ctx, ch).setSmallIcon(R.drawable.ic_notif).setColor(ACCENT).setAutoCancel(true)

    fun canPost(ctx: Context) = nm(ctx).areNotificationsEnabled()

    fun simple(ctx: Context, ch: String, id: Int, title: String, text: String, route: String) {
        if (!canPost(ctx)) return
        nm(ctx).notify(id, base(ctx, ch).setContentTitle(title).setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setContentIntent(openApp(ctx, route, id)).build())
    }

    fun checkinId(hour: Int) = 2000 + hour

    /** "What did you do from 9 AM to 10 AM?" with one-tap actions and inline reply. */
    fun checkin(ctx: Context, date: LocalDate, hour: Int) {
        if (!canPost(ctx)) return
        val repo = Repo.get(ctx)
        val planned = Days.resolve(repo, date).plannedFor(hour)
        val title = "What did you do from ${TimeUtil.fmtTime(hour * 60)} to ${TimeUtil.fmtTime((hour + 1) * 60)}?"
        val text = planned?.let { "Planned: ${it.title}" } ?: "Tap a button, reply, or open to log."
        val id = checkinId(hour)
        fun extras(kind: String): Intent.() -> Unit = { putExtra("date", date.toString()); putExtra("hour", hour); putExtra("kind", kind) }
        val rcBase = id * 10

        val big = RemoteViews(ctx.packageName, R.layout.notif_checkin)
        big.setTextViewText(R.id.n_title, title)
        big.setTextViewText(R.id.n_text, text)
        big.setOnClickPendingIntent(R.id.n_planned, action(ctx, ActionReceiver.LOG, rcBase + 1, extras = extras("as_planned")))
        big.setOnClickPendingIntent(R.id.n_essential, action(ctx, ActionReceiver.LOG, rcBase + 2, extras = extras("essential")))
        big.setOnClickPendingIntent(R.id.n_trivial, action(ctx, ActionReceiver.LOG, rcBase + 3, extras = extras("trivial")))

        val replyPi = action(ctx, ActionReceiver.REPLY, rcBase + 4, mutable = true, extras = extras("reply"))
        val remote = RemoteInput.Builder(KEY_REPLY).setLabel("What did you do?").build()
        val reply = Notification.Action.Builder(null, "Reply", replyPi).addRemoteInput(remote).setAllowGeneratedReplies(false).build()
        val snooze = Notification.Action.Builder(null, "Snooze 10 min", action(ctx, ActionReceiver.SNOOZE, rcBase + 5, extras = extras("snooze"))).build()
        val planned1 = Notification.Action.Builder(null, "As planned", action(ctx, ActionReceiver.LOG, rcBase + 6, extras = extras("as_planned"))).build()

        val n = base(ctx, CH_CHECKIN).setContentTitle(title).setContentText(text)
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setCustomBigContentView(big)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setContentIntent(openApp(ctx, "log", rcBase + 7) { putExtra("date", date.toString()); putExtra("hour", hour) })
            .addAction(planned1).addAction(reply).addAction(snooze)
            .setGroup("checkins")
            .build()
        nm(ctx).notify(id, n)
    }

    fun cancelCheckin(ctx: Context, hour: Int) = nm(ctx).cancel(checkinId(hour))

    fun focusOngoing(ctx: Context) {
        val st = Focus.state(ctx) ?: return
        val left = st.leftMillis()
        val open = PendingIntent.getActivity(ctx, 4001, Intent(ctx, FocusActivity::class.java).setFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val b = base(ctx, CH_FOCUS).setOngoing(true).setAutoCancel(false).setOnlyAlertOnce(true)
            .setContentTitle(if (st.paused) "Focus paused" else "Focus: ${st.task.ifBlank { "Essential work" }}")
            .setContentText(if (st.paused) "${TimeUtil.fmtCountdown(left / 1000)} left" else "Time left")
            .setContentIntent(open).setCategory(Notification.CATEGORY_PROGRESS)
        if (!st.paused) {
            b.setUsesChronometer(true).setChronometerCountDown(true).setWhen(TimeUtil.nowMillis() + left).setShowWhen(true)
            b.addAction(Notification.Action.Builder(null, "Pause", action(ctx, ActionReceiver.FOCUS_PAUSE, 4002)).build())
        } else {
            b.setShowWhen(false)
            b.addAction(Notification.Action.Builder(null, "Resume", action(ctx, ActionReceiver.FOCUS_RESUME, 4003)).build())
        }
        b.addAction(Notification.Action.Builder(null, "End", action(ctx, ActionReceiver.FOCUS_STOP, 4004)).build())
        if (canPost(ctx)) nm(ctx).notify(ID_FOCUS, b.build())
    }

    fun cancelFocus(ctx: Context) = nm(ctx).cancel(ID_FOCUS)

    fun habitTimerOngoing(ctx: Context) {
        val st = com.essential.app.core.HabitTimer.state(ctx) ?: return
        val open = PendingIntent.getActivity(ctx, 4101, Intent(ctx, com.essential.app.ui.HabitTimerActivity::class.java).setFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val now = TimeUtil.nowMillis()
        val b = base(ctx, CH_HTIMER).setOngoing(true).setAutoCancel(false).setOnlyAlertOnce(true)
            .setContentTitle(if (st.paused) "${st.name} · paused" else st.name)
            .setContentIntent(open).setCategory(Notification.CATEGORY_STOPWATCH)
        if (st.paused) {
            b.setShowWhen(false).setContentText(if (st.open) "${TimeUtil.fmtCountdown(st.elapsedMs() / 1000)} so far" else "${TimeUtil.fmtCountdown(st.leftMs() / 1000)} left")
            b.addAction(Notification.Action.Builder(null, "Resume", action(ctx, ActionReceiver.HT_RESUME, 4103)).build())
        } else {
            b.setUsesChronometer(true).setShowWhen(true)
            if (st.open) b.setWhen(now - st.elapsedMs(now)).setContentText("Timer running")
            else b.setChronometerCountDown(true).setWhen(now + st.leftMs(now)).setContentText("Time left")
            b.addAction(Notification.Action.Builder(null, "Pause", action(ctx, ActionReceiver.HT_PAUSE, 4102)).build())
        }
        b.addAction(Notification.Action.Builder(null, "Finish & save", action(ctx, ActionReceiver.HT_FINISH, 4104)).build())
        if (canPost(ctx)) nm(ctx).notify(ID_HTIMER, b.build())
    }

    fun cancelHabitTimer(ctx: Context) = nm(ctx).cancel(ID_HTIMER)

    fun habitTimerDone(ctx: Context, name: String, minutes: Int) {
        if (!canPost(ctx)) return
        nm(ctx).notify(4105, base(ctx, CH_HTIMER_DONE).setContentTitle("$name complete 🔔")
            .setContentText(if (minutes > 0) "$minutes min logged. Well done." else "Time's up.")
            .setContentIntent(openApp(ctx, "habits", 4106)).build())
    }

    /** An alarm you set. "Alarm" style rings (insistent alarm sound, full screen on the lock screen); "reminder" is one sound. */
    fun userAlarm(ctx: Context, x: UserAlarm, title: String, text: String, habit: Habit?) {
        val id = (UserAlarms.ID_BASE + x.id).toInt()
        val rc = id * 10
        fun ring(extra: String? = null, req: Int): PendingIntent {
            val i = Intent(ctx, AlarmRingActivity::class.java).setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION)
                .setAction("alarm.${x.id}.$req").putExtra(AlarmRingActivity.EXTRA_ID, x.id)
            if (extra != null) i.putExtra(extra, true)
            return PendingIntent.getActivity(ctx, rc + req, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }
        val b = base(ctx, if (!x.rings) CH_HREMIND else if (x.vibrate) CH_ALARM else CH_ALARM_NV)
            .setContentTitle(title).setContentText(text).setStyle(Notification.BigTextStyle().bigText(text))
            .setShowWhen(true).setWhen(TimeUtil.nowMillis())
            .setVisibility(Notification.VISIBILITY_PUBLIC)
        if (x.rings) {
            b.setCategory(Notification.CATEGORY_ALARM).setOngoing(true).setAutoCancel(false)
                .setFullScreenIntent(ring(req = 1), true).setContentIntent(ring(req = 2))
                .setTimeoutAfter(10 * 60_000L)
        } else {
            b.setCategory(Notification.CATEGORY_REMINDER)
                .setContentIntent(if (habit != null) openApp(ctx, "habit", rc + 2) { putExtra("habit_id", habit.id) } else openApp(ctx, "alarms", rc + 2))
        }
        val extras: Intent.() -> Unit = { putExtra("alarm_id", x.id) }
        if (habit != null) {
            if (habit.unit == HabitUnit.MINUTES) b.addAction(Notification.Action.Builder(null, "Start timer", ring(AlarmRingActivity.EXTRA_START_TIMER, 3)).build())
            b.addAction(Notification.Action.Builder(null, "Done", action(ctx, ActionReceiver.UA_DONE, rc + 4, extras = extras)).build())
        }
        b.addAction(Notification.Action.Builder(null, "Snooze ${x.snoozeMin} min", action(ctx, ActionReceiver.UA_SNOOZE, rc + 5, extras = extras)).build())
        b.addAction(Notification.Action.Builder(null, if (x.rings) "Stop" else "Dismiss", action(ctx, ActionReceiver.UA_STOP, rc + 6, extras = extras)).build())
        val n = b.build()
        if (x.rings) n.flags = n.flags or Notification.FLAG_INSISTENT
        nm(ctx).notify(id, n)
    }

    fun focusDone(ctx: Context, minutes: Int, task: String) =
        simple(ctx, CH_FOCUS, 4005, "Focus complete: $minutes min", "${task.ifBlank { "Essential work" }} — logged as Essential.", "now")

    fun test(ctx: Context) = simple(ctx, CH_TEST, 3999, "Abhyasa is working", "Notifications arrive on time. Less, but better.", "settings")
}
