package com.essential.app.notify

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.RemoteInput
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.essential.app.R
import com.essential.app.core.Days
import com.essential.app.core.Focus
import com.essential.app.core.TimeUtil
import com.essential.app.data.Repo
import com.essential.app.ui.FocusActivity
import com.essential.app.ui.MainActivity
import java.time.LocalDate

/** Builds every notification. One channel per type so each can be controlled in Android settings. */
object Notifier {
    const val CH_CHECKIN = "checkin"; const val CH_BLOCK = "block"; const val CH_TRADE = "trade_stop"; const val CH_REVIEW = "review"
    const val CH_WIND = "wind_down"; const val CH_SLEEP = "sleep_log"; const val CH_BACKUP = "backup"; const val CH_TOOLS = "tools"
    const val CH_FOCUS = "focus"; const val CH_TEST = "test"
    const val ID_FOCUS = 4000
    const val KEY_REPLY = "reply"
    private const val ACCENT = 0xFF7FD1B9.toInt()

    fun nm(ctx: Context): NotificationManager = ctx.getSystemService(NotificationManager::class.java)

    fun ensureChannels(ctx: Context) {
        val nm = nm(ctx)
        fun ch(id: String, name: String, imp: Int, desc: String) {
            val c = NotificationChannel(id, name, imp); c.description = desc
            if (id == CH_FOCUS) { c.setSound(null, null); c.enableVibration(false) }
            nm.createNotificationChannel(c)
        }
        ch(CH_CHECKIN, "Hourly check-in", NotificationManager.IMPORTANCE_HIGH, "Every hour: what did you do? Log it with one tap.")
        ch(CH_BLOCK, "Next block", NotificationManager.IMPORTANCE_DEFAULT, "5 minutes before each block starts")
        ch(CH_TRADE, "Trading hard stop", NotificationManager.IMPORTANCE_HIGH, "Close positions and step away")
        ch(CH_REVIEW, "Daily review", NotificationManager.IMPORTANCE_DEFAULT, "Evening review reminder")
        ch(CH_WIND, "Wind-down", NotificationManager.IMPORTANCE_DEFAULT, "15 minutes before sleep")
        ch(CH_SLEEP, "Morning sleep log", NotificationManager.IMPORTANCE_DEFAULT, "Log last night's sleep")
        ch(CH_BACKUP, "Weekly backup", NotificationManager.IMPORTANCE_LOW, "Backup reminders and automatic backups")
        ch(CH_TOOLS, "Reviews & reports", NotificationManager.IMPORTANCE_DEFAULT, "Weekly report, obstacle, monthly uncommit, sprints")
        ch(CH_FOCUS, "Focus session", NotificationManager.IMPORTANCE_LOW, "Ongoing focus timer")
        ch(CH_TEST, "Test", NotificationManager.IMPORTANCE_HIGH, "Test notification from Settings")
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
            b.setUsesChronometer(true).setChronometerCountDown(true).setWhen(System.currentTimeMillis() + left).setShowWhen(true)
            b.addAction(Notification.Action.Builder(null, "Pause", action(ctx, ActionReceiver.FOCUS_PAUSE, 4002)).build())
        } else {
            b.setShowWhen(false)
            b.addAction(Notification.Action.Builder(null, "Resume", action(ctx, ActionReceiver.FOCUS_RESUME, 4003)).build())
        }
        b.addAction(Notification.Action.Builder(null, "End", action(ctx, ActionReceiver.FOCUS_STOP, 4004)).build())
        if (canPost(ctx)) nm(ctx).notify(ID_FOCUS, b.build())
    }

    fun cancelFocus(ctx: Context) = nm(ctx).cancel(ID_FOCUS)

    fun focusDone(ctx: Context, minutes: Int, task: String) =
        simple(ctx, CH_FOCUS, 4005, "Focus complete: $minutes min", "${task.ifBlank { "Essential work" }} — logged as Essential.", "now")

    fun test(ctx: Context) = simple(ctx, CH_TEST, 3999, "Essential is working", "Notifications arrive on time. Less, but better.", "settings")
}
