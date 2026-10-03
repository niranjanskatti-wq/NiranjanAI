package com.dosemate.app

import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.core.content.ContextCompat
import com.dosemate.app.alarm.NotificationHelper
import com.dosemate.app.alarm.ReminderEngine
import com.dosemate.app.data.repo.MedicineRepository
import com.dosemate.app.data.repo.PlanSeeder
import com.dosemate.app.di.AppScope
import dagger.hilt.android.HiltAndroidApp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import javax.inject.Inject

@HiltAndroidApp
class DoseMateApp : Application() {

    @Inject lateinit var notifications: NotificationHelper
    @Inject lateinit var engine: ReminderEngine
    @Inject lateinit var seeder: PlanSeeder
    @Inject lateinit var medicines: MedicineRepository
    @Inject @AppScope lateinit var scope: CoroutineScope

    override fun onCreate() {
        super.onCreate()
        notifications.createChannels()
        scope.launch {
            seeder.seedIfNeeded()
            engine.rescheduleAll()
        }
        // Missed-dose summary when the phone is next unlocked.
        ContextCompat.registerReceiver(
            this,
            object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    scope.launch { showMissedSinceLastUnlock() }
                }
            },
            IntentFilter(Intent.ACTION_USER_PRESENT),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
    }

    private suspend fun showMissedSinceLastUnlock() {
        val prefs = getSharedPreferences("unlock", MODE_PRIVATE)
        val last = prefs.getLong("lastSummary", 0L)
        val since = com.dosemate.app.alarm.AlarmContract.decode(last)
        val missed = engine.missedSince(since)
        prefs.edit().putLong("lastSummary", com.dosemate.app.alarm.AlarmContract.encode(LocalDateTime.now())).apply()
        if (missed.isEmpty()) return
        val names = missed.mapNotNull { log -> medicines.get(log.medicineId)?.medicine?.name }
        notifications.showMissedSummary(names)
    }
}
