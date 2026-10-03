package com.dosemate.app.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.RemoteInput
import com.dosemate.app.alarm.AlarmContract.dose
import com.dosemate.app.alarm.AlarmContract.kind
import com.dosemate.app.di.entryPoint
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull

/** Runs [block] off the main thread while keeping the receiver alive. */
private fun BroadcastReceiver.async(context: Context, block: suspend () -> Unit) {
    val pending = goAsync()
    context.entryPoint().scope().launch {
        try {
            withTimeoutOrNull(9_000) { block() }
        } finally {
            pending.finish()
        }
    }
}

/** Receives dose alarms, the daily maintenance alarm and the weekly journal reminder. */
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val ep = context.entryPoint()
        when (intent.action) {
            AlarmContract.ACTION_FIRE -> {
                val key = intent.dose() ?: return
                async(context) { ep.engine().onAlarmFired(key, intent.kind()) }
            }
            AlarmContract.ACTION_MAINTENANCE -> async(context) { ep.engine().rescheduleAll() }
            AlarmContract.ACTION_JOURNAL -> async(context) {
                ep.notifications().showJournalReminder()
                ep.engine().rescheduleAll()
            }
        }
    }
}

/** Taken / Snooze / Skip buttons on notifications. */
class ActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val key = intent.dose() ?: return
        val engine = context.entryPoint().engine()
        when (intent.action) {
            AlarmContract.ACTION_TAKEN -> async(context) { engine.markTaken(key) }
            AlarmContract.ACTION_SNOOZE -> {
                val minutes = intent.getIntExtra(AlarmContract.EXTRA_MINUTES, 10)
                async(context) { engine.snooze(key, minutes) }
            }
            AlarmContract.ACTION_SKIP -> {
                val reason = RemoteInput.getResultsFromIntent(intent)
                    ?.getCharSequence(AlarmContract.KEY_SKIP_REASON)?.toString()
                async(context) { engine.markSkipped(key, reason) }
            }
        }
    }
}

/**
 * Re-plans every alarm after a reboot, an app update, a clock or time zone change, or when the
 * exact-alarm permission changes. Alarms are stored in wall-clock time, so a 9 PM dose stays at
 * 9 PM local time after travelling.
 */
class SystemEventReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
            "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED",
            -> async(context) { context.entryPoint().engine().rescheduleAll() }
        }
    }
}
