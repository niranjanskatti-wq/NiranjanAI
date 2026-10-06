package com.lovebombing.app.notify

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import com.lovebombing.app.data.AppDatabase
import com.lovebombing.app.data.PlanStatus
import com.lovebombing.app.data.PlanStatusRow
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

private val receiverScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

private fun BroadcastReceiver.runAsync(block: suspend () -> Unit) {
    val pending = goAsync()
    receiverScope.launch {
        try {
            block()
        } finally {
            pending.finish()
        }
    }
}

/** The single alarm in the reminder chain fired. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext
        runAsync { ReminderScheduler.fire(app) }
    }
}

/** Alarms are wiped on reboot, app update, clock or permission changes: re-arm them. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext
        runAsync { ReminderScheduler.reschedule(app) }
    }
}

/** "Done" / "Skip" tapped on a plan reminder notification. */
class PlanActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext
        val key = intent.getStringExtra(EXTRA_KEY) ?: return
        val status = intent.getStringExtra(EXTRA_STATUS) ?: return
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION, 0)
        runAsync {
            val dao = AppDatabase.get(app).dao()
            val existing = dao.status(key) ?: PlanStatusRow(key, status)
            dao.saveStatus(existing.copy(status = status, updatedAt = System.currentTimeMillis()))
            NotificationManagerCompat.from(app).cancel(notificationId)
            ReminderScheduler.reschedule(app)
        }
    }

    companion object {
        private const val EXTRA_KEY = "plan_key"
        private const val EXTRA_STATUS = "plan_status"
        private const val EXTRA_NOTIFICATION = "notification_id"

        fun intent(context: Context, key: String, status: PlanStatus, notificationId: Int): PendingIntent {
            val i = Intent(context, PlanActionReceiver::class.java)
                .putExtra(EXTRA_KEY, key)
                .putExtra(EXTRA_STATUS, status.name)
                .putExtra(EXTRA_NOTIFICATION, notificationId)
            return PendingIntent.getBroadcast(
                context, (key + status.name).hashCode(), i,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
