package com.lovebombing.app.notify

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.lovebombing.app.MainActivity
import com.lovebombing.app.R
import com.lovebombing.app.data.AppDao
import com.lovebombing.app.data.AppDatabase
import com.lovebombing.app.data.AutoPlanSetting
import com.lovebombing.app.data.Content
import com.lovebombing.app.data.EventKind
import com.lovebombing.app.data.Plan
import com.lovebombing.app.data.PlanStatus
import com.lovebombing.app.data.PlanStatusRow
import com.lovebombing.app.data.PlanType
import com.lovebombing.app.data.Settings
import com.lovebombing.app.data.eventsBetween
import com.lovebombing.app.data.formatMinutes
import com.lovebombing.app.data.planItems
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId

/** One notification to show at [at] (epoch millis). */
data class Reminder(
    val key: String,
    val at: Long,
    val title: String,
    val text: String,
    /** Message category to suggest when the notification is tapped. */
    val suggestCategory: String? = null,
    val festivalKey: String? = null,
    /** Set for plan reminders: lets the notification offer Done / Skip. */
    val planKey: String? = null,
)

/** Everything the reminder engine reads from the database. */
data class ReminderData(
    val settings: Settings,
    val plans: List<Plan>,
    val autos: Map<String, AutoPlanSetting>,
    val statuses: Map<String, PlanStatusRow>,
)

suspend fun AppDao.reminderData(): ReminderData? {
    val s = settings() ?: return null
    return ReminderData(s, allPlans(), allAutoPlans().associateBy { it.templateId }, allStatuses().associateBy { it.key })
}

/**
 * All reminders are kept in a single AlarmManager chain: we always arm one alarm
 * for the earliest upcoming reminder; when it fires we post everything due and
 * arm the next one. This survives reboots via [BootReceiver].
 */
object ReminderScheduler {
    const val CHANNEL_DAILY = "daily"
    const val CHANNEL_EVENTS = "events"
    const val EXTRA_CATEGORY = "suggest_category"
    const val EXTRA_FESTIVAL = "suggest_festival"
    private const val PREFS = "reminder_state"
    private const val KEY_LAST = "last_fired_until"
    private const val LOOKAHEAD_DAYS = 400L

    /** Reminders whose time falls in (fromExclusive, toInclusive]. */
    fun remindersBetween(context: Context, data: ReminderData, fromExclusive: Long, toInclusive: Long): List<Reminder> {
        val settings = data.settings
        val zone = ZoneId.systemDefault()
        val content = Content.get(context)
        val name = settings.wifeName.trim().ifEmpty { "her" }
        val out = ArrayList<Reminder>()
        fun at(day: LocalDate, minutes: Int) = LocalDateTime.of(day, java.time.LocalTime.of(minutes / 60, minutes % 60))
            .atZone(zone).toInstant().toEpochMilli()
        fun add(r: Reminder) { if (r.at > fromExclusive && r.at <= toInclusive) out += r }

        val startDay = java.time.Instant.ofEpochMilli(fromExclusive).atZone(zone).toLocalDate()
        val endDay = java.time.Instant.ofEpochMilli(toInclusive).atZone(zone).toLocalDate()

        // Daily reminders
        var d = startDay
        while (!d.isAfter(endDay)) {
            if (settings.morningOn) add(Reminder("morning-$d", at(d, settings.morningMinutes), "Good morning, husband ☀️",
                "Start $name's day with a sweet good-morning text. One's ready for you.", "Good Morning"))
            if (settings.middayOn) add(Reminder("midday-$d", at(d, settings.middayMinutes), "Mid-day nudge 💌",
                "Send her something that isn't about chores.", "Romantic"))
            if (settings.nightOn) add(Reminder("night-$d", at(d, settings.nightMinutes), "Say good night 🌙",
                "End $name's day with a good-night message. Tap to send one.", "Good Night"))
            d = d.plusDays(1)
        }

        // Event reminders: look at events up to 7 days past the window so "7 days before" is found.
        val items = planItems(startDay, endDay.plusDays(8), settings, data.plans, data.autos, data.statuses, content.festivals)
        val events = eventsBetween(startDay, endDay.plusDays(8), settings, items, content.festivals)
        for (e in events) {
            when (e.kind) {
                EventKind.BIRTHDAY, EventKind.ANNIVERSARY -> {
                    val on = if (e.kind == EventKind.BIRTHDAY) settings.birthdayOn else settings.anniversaryOn
                    if (!on) continue
                    val cat = if (e.kind == EventKind.BIRTHDAY) "Birthday" else "Anniversary"
                    val what = e.title
                    add(Reminder("${e.kind}-7-${e.date}", at(e.date.minusDays(7), 19 * 60), "$what in 7 days 🎁",
                        "One week to go. Time to plan a gift, a dinner or a surprise."))
                    add(Reminder("${e.kind}-1-${e.date}", at(e.date.minusDays(1), 19 * 60), "$what is tomorrow",
                        "Gift wrapped? Table booked? Set an alarm to be the first to wish her at midnight."))
                    add(Reminder("${e.kind}-0-${e.date}", at(e.date, 7 * 60), "Today: $what 🎉",
                        "Be the first to wish her. Tap for a message ready to send.", cat))
                }
                EventKind.FESTIVAL -> {
                    if (!settings.festivalsOn) continue
                    add(Reminder("fest-${e.festivalKey}-${e.date}", at(e.date.minusDays(3), 10 * 60), "${e.title} in 3 days 🪔",
                        "Plan something special for $name: an outfit, sweets, flowers or a small gift."))
                }
                EventKind.PLAN -> {
                    val p = e.item ?: continue
                    if (!settings.plansOn || p.status != PlanStatus.PENDING) continue
                    val type = p.type
                    val start = at(p.date, p.minuteOfDay)
                    val note = p.note.ifBlank { type.label }
                    val suggest = if (type == PlanType.MESSAGE) {
                        p.messageCategory ?: p.messageId?.let { content.message(it)?.category } ?: "Romantic"
                    } else null
                    add(Reminder("plan-${p.key}-15", start - 15 * 60 * 1000, "In 15 min: ${p.title}",
                        "${formatMinutes(p.minuteOfDay)} · $note", suggest, planKey = p.key))
                    if (type == PlanType.DATE_NIGHT || type == PlanType.GIFT) {
                        add(Reminder("plan-${p.key}-1d", start - 24 * 60 * 60 * 1000, "Tomorrow: ${p.title}",
                            "${formatMinutes(p.minuteOfDay)} · $note", planKey = p.key))
                    }
                }
            }
        }
        out.sortBy { it.at }
        return out
    }

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Re-arms the alarm chain from now. Safe to call often. */
    suspend fun reschedule(context: Context) {
        val now = System.currentTimeMillis()
        prefs(context).edit().putLong(KEY_LAST, now).apply()
        armNext(context, now)
    }

    /** Called by [ReminderReceiver]: posts every reminder due since the last run, then arms the next. */
    suspend fun fire(context: Context) {
        val dao = AppDatabase.get(context).dao()
        val data = dao.reminderData()
        val now = System.currentTimeMillis()
        if (data == null || !data.settings.onboarded) return
        val last = prefs(context).getLong(KEY_LAST, now - 60_000)
        // Don't replay a pile of stale reminders after the phone was off for a while.
        val from = maxOf(last, now - 30 * 60 * 1000)
        val due = remindersBetween(context, data, from, now + 30_000)
        due.forEach { post(context, it) }
        val until = maxOf(now + 30_000, due.maxOfOrNull { it.at } ?: 0)
        prefs(context).edit().putLong(KEY_LAST, until).apply()
        armNext(context, until)
    }

    private suspend fun armNext(context: Context, after: Long) {
        val dao = AppDatabase.get(context).dao()
        val data = dao.reminderData()
        val alarm = context.getSystemService(AlarmManager::class.java)
        val pi = alarmIntent(context)
        if (data == null || !data.settings.onboarded) {
            alarm.cancel(pi)
            return
        }
        // Search a short window first (daily reminders), widening only if nothing is found.
        var next: Reminder? = null
        for (days in longArrayOf(2, 30, LOOKAHEAD_DAYS)) {
            next = remindersBetween(context, data, after, after + days * 24 * 60 * 60 * 1000).firstOrNull()
            if (next != null) break
        }
        if (next == null) {
            alarm.cancel(pi)
            return
        }
        val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarm.canScheduleExactAlarms()
        try {
            if (canExact) alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.at, pi)
            else alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.at, pi)
        } catch (_: SecurityException) {
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.at, pi)
        }
    }

    private fun alarmIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context, 1, Intent(context, ReminderReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    fun createChannels(context: Context) {
        val nm = context.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(NotificationChannel(CHANNEL_DAILY, "Daily message reminders", NotificationManager.IMPORTANCE_DEFAULT).apply {
            description = "Good-morning, mid-day and good-night nudges"
        })
        nm.createNotificationChannel(NotificationChannel(CHANNEL_EVENTS, "Birthdays, anniversaries and plans", NotificationManager.IMPORTANCE_HIGH).apply {
            description = "Upcoming birthdays, anniversaries, festivals and your plans"
        })
    }

    private fun post(context: Context, r: Reminder) {
        val daily = r.key.startsWith("morning") || r.key.startsWith("midday") || r.key.startsWith("night")
        val open = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            r.suggestCategory?.let { putExtra(EXTRA_CATEGORY, it) }
            r.festivalKey?.let { putExtra(EXTRA_FESTIVAL, it) }
        }
        val id = r.key.hashCode()
        val content = PendingIntent.getActivity(context, id, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = NotificationCompat.Builder(context, if (daily) CHANNEL_DAILY else CHANNEL_EVENTS)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(0xFFD9546E.toInt())
            .setContentTitle(r.title)
            .setContentText(r.text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(r.text))
            .setContentIntent(content)
            .setAutoCancel(true)
            .setPriority(if (daily) NotificationCompat.PRIORITY_DEFAULT else NotificationCompat.PRIORITY_HIGH)
        r.planKey?.let { key ->
            builder.addAction(0, "Done", PlanActionReceiver.intent(context, key, PlanStatus.DONE, id))
            builder.addAction(0, "Skip", PlanActionReceiver.intent(context, key, PlanStatus.SKIPPED, id))
        }
        val n = builder.build()
        try {
            NotificationManagerCompat.from(context).notify(id, n)
        } catch (_: SecurityException) {
            // Notification permission not granted; nothing to show.
        }
    }
}
