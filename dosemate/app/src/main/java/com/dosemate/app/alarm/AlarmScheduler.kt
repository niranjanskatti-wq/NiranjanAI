package com.dosemate.app.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import com.dosemate.app.MainActivity
import com.dosemate.app.alarm.AlarmContract.putDose
import com.dosemate.app.data.repo.AppSettings
import com.dosemate.core.AlarmKind
import com.dosemate.core.AlertStyle
import com.dosemate.core.PlannedAlarm
import com.dosemate.core.TimeMath
import dagger.hilt.android.qualifiers.ApplicationContext
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.temporal.TemporalAdjusters
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Registers planned doses with [AlarmManager].
 *
 * Alarm-mode doses use [AlarmManager.setAlarmClock] (highest priority, exempt from Doze, shown in
 * the status bar). Notification doses use [AlarmManager.setExactAndAllowWhileIdle]. If the exact
 * alarm permission is revoked we fall back to inexact alarms rather than dropping reminders.
 */
@Singleton
class AlarmScheduler @Inject constructor(@ApplicationContext private val context: Context) {

    private val alarmManager = context.getSystemService(AlarmManager::class.java)
    private val registry = context.getSharedPreferences("alarm_registry", Context.MODE_PRIVATE)

    fun canScheduleExact(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()

    /** Registers [plan] and cancels anything registered earlier that is no longer in it. */
    fun apply(plan: List<PlannedAlarm>, zone: ZoneId = ZoneId.systemDefault()) {
        val codes = mutableSetOf<String>()
        for (alarm in plan) {
            val code = requestCode(alarm.slotId, alarm.kind)
            if (!codes.add(code.toString())) continue
            register(alarm, code, zone)
        }
        val previous = registry.getStringSet(KEY_CODES, emptySet()).orEmpty()
        (previous - codes).forEach { it.toIntOrNull()?.let(::cancel) }
        registry.edit().putStringSet(KEY_CODES, codes).apply()
    }

    fun cancelAll() {
        registry.getStringSet(KEY_CODES, emptySet()).orEmpty().forEach { it.toIntOrNull()?.let(::cancel) }
        registry.edit().remove(KEY_CODES).apply()
    }

    private fun register(alarm: PlannedAlarm, code: Int, zone: ZoneId) {
        val trigger = TimeMath.toEpochMillis(alarm.fireAt, zone)
        val intent = Intent(context, AlarmReceiver::class.java)
            .setAction(AlarmContract.ACTION_FIRE)
            .setData(Uri.parse("dosemate://alarm/$code"))
            .putDose(DoseKey(alarm.medicineId, alarm.slotId, alarm.scheduledAt))
            .putExtra(AlarmContract.EXTRA_KIND, alarm.kind.name)
        val pending = PendingIntent.getBroadcast(
            context, code, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val alarmClock = alarm.kind != AlarmKind.PRE && alarm.style == AlertStyle.ALARM
        try {
            when {
                alarmClock && canScheduleExact() ->
                    alarmManager.setAlarmClock(AlarmManager.AlarmClockInfo(trigger, showIntent()), pending)
                canScheduleExact() ->
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
                else ->
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
            }
        } catch (e: SecurityException) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
        }
    }

    private fun cancel(code: Int) {
        val intent = Intent(context, AlarmReceiver::class.java)
            .setAction(AlarmContract.ACTION_FIRE)
            .setData(Uri.parse("dosemate://alarm/$code"))
        PendingIntent.getBroadcast(
            context, code, intent, PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )?.let {
            alarmManager.cancel(it)
            it.cancel()
        }
    }

    private fun showIntent(): PendingIntent = PendingIntent.getActivity(
        context, 1, Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /** Daily safety net: re-plans everything and records missed doses at about 3 AM. */
    fun scheduleMaintenance(now: LocalDateTime = LocalDateTime.now()) {
        var next = now.toLocalDate().atTime(3, 5)
        if (!next.isAfter(now)) next = next.plusDays(1)
        setInexact(MAINTENANCE_CODE, AlarmContract.ACTION_MAINTENANCE, next)
    }

    /** Weekly skin-photo reminder. */
    fun scheduleJournal(settings: AppSettings, now: LocalDateTime = LocalDateTime.now()) {
        if (!settings.journalReminder) {
            cancelSimple(JOURNAL_CODE, AlarmContract.ACTION_JOURNAL)
            return
        }
        val day = DayOfWeek.of(settings.journalDay.coerceIn(1, 7))
        var date: LocalDate = now.toLocalDate().with(TemporalAdjusters.nextOrSame(day))
        var next = LocalDateTime.of(date, settings.journalTime)
        if (!next.isAfter(now)) {
            date = date.plusWeeks(1)
            next = LocalDateTime.of(date, settings.journalTime)
        }
        val trigger = TimeMath.toEpochMillis(next, ZoneId.systemDefault())
        val pending = simpleIntent(JOURNAL_CODE, AlarmContract.ACTION_JOURNAL)
        if (canScheduleExact()) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
        } else {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
        }
    }

    private fun setInexact(code: Int, action: String, at: LocalDateTime) {
        val trigger = TimeMath.toEpochMillis(at, ZoneId.systemDefault())
        alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, simpleIntent(code, action))
    }

    private fun simpleIntent(code: Int, action: String): PendingIntent = PendingIntent.getBroadcast(
        context, code,
        Intent(context, AlarmReceiver::class.java).setAction(action),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun cancelSimple(code: Int, action: String) {
        PendingIntent.getBroadcast(
            context, code, Intent(context, AlarmReceiver::class.java).setAction(action),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )?.let { alarmManager.cancel(it) }
    }

    /** Next alarm the system will ring for us (alarm-clock alarms only). */
    fun nextAlarmClockMillis(): Long? = alarmManager.nextAlarmClock?.takeIf {
        it.showIntent?.creatorPackage == context.packageName
    }?.triggerTime

    companion object {
        private const val KEY_CODES = "codes"
        private const val MAINTENANCE_CODE = 2_000_000_001
        private const val JOURNAL_CODE = 2_000_000_002

        fun requestCode(slotId: Long, kind: AlarmKind): Int = ((slotId % 400_000_000L) * 4 + kind.ordinal).toInt()
    }
}
