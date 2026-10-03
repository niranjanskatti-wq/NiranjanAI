package com.dosemate.app.alarm

import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.ProcessLifecycleOwner
import com.dosemate.app.alarm.AlarmContract.dose
import com.dosemate.app.alarm.AlarmContract.putDose
import com.dosemate.app.data.db.MedicineWithTimes
import com.dosemate.app.data.db.VibrationPattern
import com.dosemate.app.data.repo.MedicineRepository
import com.dosemate.app.data.repo.SettingsRepository
import com.dosemate.core.AlertStyle
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Foreground service that keeps an alarm ringing: loud looping sound on the alarm stream,
 * gradual volume increase, vibration, optional flashlight blinking, and the full-screen
 * notification that shows [AlarmActivity] over the lock screen.
 */
@AndroidEntryPoint
class AlarmService : Service() {

    @Inject lateinit var medicines: MedicineRepository
    @Inject lateinit var settingsRepo: SettingsRepository
    @Inject lateinit var notifications: NotificationHelper
    @Inject lateinit var tones: ToneLibrary

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var player: MediaPlayer? = null
    private var rampJob: Job? = null
    private var flashJob: Job? = null
    private var timeoutJob: Job? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var savedAlarmVolume: Int? = null
    private var savedFilter: Int? = null
    private var currentKey: DoseKey? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            AlarmContract.ACTION_RING -> {
                val key = intent.dose()
                if (key == null) {
                    stopIfIdle()
                } else {
                    // Must be in the foreground within seconds: post a notification right away.
                    goForeground(null, key)
                    RingingAlarms.add(key)
                    scope.launch { startRinging(key) }
                }
            }
            AlarmContract.ACTION_DISMISS_RING -> {
                intent.dose()?.let { key ->
                    RingingAlarms.removeDose(key.medicineId, key.slotId, key.scheduledAt)
                    if (key.test) RingingAlarms.remove(key)
                }
                onQueueChanged()
            }
            AlarmContract.ACTION_STOP_ALL -> {
                RingingAlarms.clear()
                onQueueChanged()
            }
            else -> stopIfIdle()
        }
        return START_NOT_STICKY
    }

    private fun goForeground(med: MedicineWithTimes?, key: DoseKey) {
        val notification = notifications.alarmNotification(med, key, (RingingAlarms.ringing.value.size - 1).coerceAtLeast(0))
        val type = when {
            Build.VERSION.SDK_INT >= 34 && canUseSystemExempted() -> ServiceInfo.FOREGROUND_SERVICE_TYPE_SYSTEM_EXEMPTED
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            else -> 0
        }
        try {
            ServiceCompat.startForeground(this, AlarmContract.ALARM_FOREGROUND_ID, notification, type)
        } catch (e: Exception) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                runCatching {
                    ServiceCompat.startForeground(
                        this, AlarmContract.ALARM_FOREGROUND_ID, notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
                    )
                }
            }
        }
    }

    private fun canUseSystemExempted(): Boolean =
        getSystemService(android.app.AlarmManager::class.java).canScheduleExactAlarms()

    private suspend fun startRinging(key: DoseKey) {
        val settings = settingsRepo.current()
        val med = medicines.get(key.medicineId)
        currentKey = key
        goForeground(med, key)
        maybeLaunchActivity()

        acquireWakeLock(settings.ringMinutes)
        stopOutputs()
        bypassDnd(settings.dndBypass)
        if (settings.forceAlarmVolume) forceAlarmVolume(settings.alarmMaxVolume)

        val uri = med?.let { tones.resolve(it.medicine.toneType, it.medicine.toneUri, forAlarm = true) } ?: tones.defaultUri(true)
        playLooping(uri, settings.alarmStartVolume, settings.alarmRampSeconds)
        Vibration.loop(this, med?.medicine?.vibration ?: VibrationPattern.STANDARD)
        if (med?.medicine?.flashlight == true) startFlashlight()

        timeoutJob?.cancel()
        timeoutJob = scope.launch {
            delay(settings.ringMinutes.coerceIn(1, 30) * 60_000L)
            autoSilence()
        }
    }

    /** Opens the alarm screen directly when the app is already in front (full-screen intents only show when locked). */
    private fun maybeLaunchActivity() {
        val foreground = ProcessLifecycleOwner.get().lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)
        if (foreground) {
            runCatching {
                startActivity(Intent(this, AlarmActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            }
        }
    }

    private fun playLooping(uri: Uri, startVolume: Int, rampSeconds: Int) {
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val candidates = listOf(uri, tones.defaultUri(true), tones.fallbackUri())
        for (candidate in candidates) {
            val started = runCatching {
                MediaPlayer().apply {
                    setAudioAttributes(attrs)
                    setDataSource(this@AlarmService, candidate)
                    isLooping = true
                    prepare()
                    val v = (startVolume.coerceIn(0, 100) / 100f)
                    setVolume(v, v)
                    start()
                }
            }.getOrNull()
            if (started != null) {
                player = started
                break
            }
        }
        val start = startVolume.coerceIn(0, 100) / 100f
        rampJob?.cancel()
        if (rampSeconds > 0 && start < 1f) {
            rampJob = scope.launch {
                val steps = (rampSeconds * 4).coerceAtLeast(1)
                for (i in 1..steps) {
                    delay(250)
                    val v = start + (1f - start) * i / steps
                    runCatching { player?.setVolume(v, v) }
                }
            }
        } else {
            runCatching { player?.setVolume(1f, 1f) }
        }
    }

    private fun forceAlarmVolume(percent: Int) {
        val audio = getSystemService(AudioManager::class.java)
        runCatching {
            if (savedAlarmVolume == null) savedAlarmVolume = audio.getStreamVolume(AudioManager.STREAM_ALARM)
            val max = audio.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            audio.setStreamVolume(AudioManager.STREAM_ALARM, (max * percent.coerceIn(10, 100) / 100).coerceAtLeast(1), 0)
        }
    }

    /** With notification-policy access, lifts "total silence" to "alarms only" while ringing. */
    private fun bypassDnd(enabled: Boolean) {
        if (!enabled) return
        val nm = getSystemService(NotificationManager::class.java)
        runCatching {
            if (nm.isNotificationPolicyAccessGranted &&
                nm.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_NONE
            ) {
                if (savedFilter == null) savedFilter = nm.currentInterruptionFilter
                nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALARMS)
            }
        }
    }

    private fun startFlashlight() {
        val camera = getSystemService(CameraManager::class.java)
        val id = runCatching {
            camera.cameraIdList.firstOrNull {
                camera.getCameraCharacteristics(it).get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
        }.getOrNull() ?: return
        flashJob?.cancel()
        flashJob = scope.launch {
            var on = false
            try {
                while (isActive) {
                    on = !on
                    runCatching { camera.setTorchMode(id, on) }
                    delay(450)
                }
            } finally {
                runCatching { camera.setTorchMode(id, false) }
            }
        }
    }

    private fun acquireWakeLock(minutes: Int) {
        if (wakeLock?.isHeld == true) return
        wakeLock = getSystemService(PowerManager::class.java)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "DoseMate:alarm")
            .apply { acquire((minutes.coerceIn(1, 30) + 1) * 60_000L) }
    }

    /** Nobody answered within the ring time: stop the noise but keep the dose open for re-alarms. */
    private suspend fun autoSilence() {
        val keys = RingingAlarms.ringing.value
        RingingAlarms.clear()
        for (key in keys) {
            if (key.test) continue
            val med = medicines.get(key.medicineId) ?: continue
            notifications.showDose(med, key, AlertStyle.NOTIFICATION, 1)
        }
        onQueueChanged()
    }

    private fun onQueueChanged() {
        val next = RingingAlarms.ringing.value.lastOrNull()
        if (next == null) {
            stopIfIdle()
        } else if (next != currentKey) {
            scope.launch { startRinging(next) }
        }
    }

    private fun stopOutputs() {
        rampJob?.cancel()
        flashJob?.cancel()
        runCatching { player?.stop() }
        runCatching { player?.release() }
        player = null
        Vibration.cancel(this)
    }

    private fun restoreSystem() {
        val audio = getSystemService(AudioManager::class.java)
        savedAlarmVolume?.let { runCatching { audio.setStreamVolume(AudioManager.STREAM_ALARM, it, 0) } }
        savedAlarmVolume = null
        savedFilter?.let { filter ->
            runCatching { getSystemService(NotificationManager::class.java).setInterruptionFilter(filter) }
        }
        savedFilter = null
    }

    private fun stopIfIdle() {
        if (RingingAlarms.isRinging) return
        timeoutJob?.cancel()
        stopOutputs()
        restoreSystem()
        currentKey = null
        runCatching { if (wakeLock?.isHeld == true) wakeLock?.release() }
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        stopOutputs()
        restoreSystem()
        runCatching { if (wakeLock?.isHeld == true) wakeLock?.release() }
        scope.cancel()
        super.onDestroy()
    }

    companion object {
        /** Starts ringing for [key]. Returns false when Android refuses to start the service. */
        fun start(context: Context, key: DoseKey): Boolean = runCatching {
            ContextCompat.startForegroundService(
                context,
                Intent(context, AlarmService::class.java).setAction(AlarmContract.ACTION_RING).putDose(key),
            )
        }.isSuccess

        fun dismiss(context: Context, key: DoseKey) {
            // The ringing list lives in this process, so an empty list means the service is not running.
            if (!RingingAlarms.isRinging) return
            RingingAlarms.removeDose(key.medicineId, key.slotId, key.scheduledAt)
            if (key.test) RingingAlarms.remove(key)
            runCatching {
                context.startService(
                    Intent(context, AlarmService::class.java).setAction(AlarmContract.ACTION_DISMISS_RING).putDose(key),
                )
            }
        }

        fun stopAll(context: Context) {
            if (!RingingAlarms.isRinging) return
            RingingAlarms.clear()
            runCatching {
                context.startService(Intent(context, AlarmService::class.java).setAction(AlarmContract.ACTION_STOP_ALL))
            }
        }
    }
}
