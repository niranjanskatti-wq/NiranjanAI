package com.dosemate.app.alarm

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.RemoteInput
import androidx.core.content.ContextCompat
import com.dosemate.app.MainActivity
import com.dosemate.app.R
import com.dosemate.app.alarm.AlarmContract.putDose
import com.dosemate.app.data.db.MedicineWithTimes
import com.dosemate.app.data.db.ToneType
import com.dosemate.app.data.db.VibrationPattern
import com.dosemate.app.data.repo.PhotoStore
import com.dosemate.app.data.repo.SettingsRepository
import com.dosemate.app.util.LocaleHelper
import com.dosemate.app.util.TimeFormat
import com.dosemate.app.util.doseLine
import com.dosemate.app.data.db.FoodRelation
import com.dosemate.core.AlertStyle
import dagger.hilt.android.qualifiers.ApplicationContext
import java.time.LocalDateTime
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NotificationHelper @Inject constructor(
    @ApplicationContext private val appContext: Context,
    private val settingsRepo: SettingsRepository,
    private val photos: PhotoStore,
    private val tones: ToneLibrary,
) {
    private val manager = appContext.getSystemService(NotificationManager::class.java)
    private val oneShot by lazy { OneShotPlayer(appContext) }

    /** Context whose strings follow the in-app language choice. */
    private val ctx: Context get() = LocaleHelper.wrap(appContext, settingsRepo.current().language)

    fun createChannels() {
        val c = ctx
        val channels = listOf(
            NotificationChannel(CH_GENTLE, c.getString(R.string.channel_gentle), NotificationManager.IMPORTANCE_DEFAULT).apply {
                setSound(null, null)
                enableVibration(true)
                vibrationPattern = VibrationPattern.GENTLE.timings
            },
            NotificationChannel(CH_SOUND, c.getString(R.string.channel_sound), NotificationManager.IMPORTANCE_HIGH).apply {
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                    AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION_EVENT).build(),
                )
                enableVibration(true)
                vibrationPattern = VibrationPattern.STANDARD.timings
            },
            NotificationChannel(CH_CUSTOM, c.getString(R.string.channel_custom), NotificationManager.IMPORTANCE_HIGH).apply {
                // The app plays the medicine's own tone and vibration.
                setSound(null, null)
                enableVibration(false)
            },
            NotificationChannel(CH_ALARM, c.getString(R.string.channel_alarm), NotificationManager.IMPORTANCE_HIGH).apply {
                setSound(null, null)
                enableVibration(false)
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            },
            NotificationChannel(CH_PRE, c.getString(R.string.channel_pre), NotificationManager.IMPORTANCE_DEFAULT).apply {
                setSound(null, null)
            },
            NotificationChannel(CH_MISSED, c.getString(R.string.channel_missed), NotificationManager.IMPORTANCE_DEFAULT),
            NotificationChannel(CH_REFILL, c.getString(R.string.channel_refill), NotificationManager.IMPORTANCE_DEFAULT),
            NotificationChannel(CH_JOURNAL, c.getString(R.string.channel_journal), NotificationManager.IMPORTANCE_DEFAULT),
        )
        manager.createNotificationChannels(channels)
    }

    fun canPost(): Boolean =
        (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(appContext, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) &&
            NotificationManagerCompat.from(appContext).areNotificationsEnabled()

    fun canUseFullScreen(): Boolean =
        Build.VERSION.SDK_INT < 34 || manager.canUseFullScreenIntent()

    private fun post(id: Int, notification: Notification) {
        if (!canPost()) return
        runCatching { manager.notify(id, notification) }
    }

    fun cancel(id: Int) = manager.cancel(id)

    fun cancelDose(slotId: Long) {
        manager.cancel(AlarmContract.doseNotificationId(slotId))
        manager.cancel(AlarmContract.preNotificationId(slotId))
        oneShot.stop()
    }

    private fun title(m: MedicineWithTimes): String =
        if (settingsRepo.current().hideNames) ctx.getString(R.string.notif_private_title) else m.medicine.name

    private fun timeText(at: LocalDateTime) =
        TimeFormat.time(at.toLocalTime(), settingsRepo.current().use24h, LocaleHelper.locale(settingsRepo.current().language))

    fun openAppIntent(): PendingIntent = PendingIntent.getActivity(
        appContext, 0,
        Intent(appContext, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun actionIntent(action: String, key: DoseKey, code: Int, minutes: Int = 0, mutable: Boolean = false): PendingIntent {
        val intent = Intent(appContext, ActionReceiver::class.java)
            .setAction(action)
            .setData(Uri.parse("dosemate://action/${key.id}/$action"))
            .putDose(key)
            .putExtra(AlarmContract.EXTRA_MINUTES, minutes)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (mutable) PendingIntent.FLAG_MUTABLE else PendingIntent.FLAG_IMMUTABLE)
        return PendingIntent.getBroadcast(appContext, code, intent, flags)
    }

    private fun NotificationCompat.Builder.addDoseActions(key: DoseKey): NotificationCompat.Builder {
        val c = ctx
        val snooze = settingsRepo.current().defaultSnooze
        val code = (key.slotId % 100_000).toInt() * 10
        val reasons = c.resources.getStringArray(R.array.skip_reasons)
        val remoteInput = RemoteInput.Builder(AlarmContract.KEY_SKIP_REASON)
            .setLabel(c.getString(R.string.skip_reason_hint))
            .setChoices(arrayOf<CharSequence>(*reasons))
            .build()
        val skipAction = NotificationCompat.Action.Builder(
            R.drawable.ic_skip, c.getString(R.string.action_skip),
            actionIntent(AlarmContract.ACTION_SKIP, key, code + 3, mutable = true),
        ).addRemoteInput(remoteInput).setAllowGeneratedReplies(false).build()
        return addAction(R.drawable.ic_check, c.getString(R.string.action_taken), actionIntent(AlarmContract.ACTION_TAKEN, key, code + 1))
            .addAction(R.drawable.ic_snooze, c.getString(R.string.action_snooze_min, snooze), actionIntent(AlarmContract.ACTION_SNOOZE, key, code + 2, snooze))
            .addAction(skipAction)
    }

    private fun base(channel: String, m: MedicineWithTimes?): NotificationCompat.Builder =
        NotificationCompat.Builder(appContext, channel)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(ContextCompat.getColor(appContext, R.color.brand))
            .setContentIntent(openAppIntent())
            .setAutoCancel(true)
            .apply {
                if (m != null && !settingsRepo.current().hideNames) {
                    m.medicine.photoPath?.let { name ->
                        runCatching { BitmapFactory.decodeFile(photos.file(PhotoStore.MEDICINE, name).absolutePath) }
                            .getOrNull()?.let { setLargeIcon(it) }
                    }
                }
            }

    private fun privatePublicVersion(channel: String): Notification =
        NotificationCompat.Builder(appContext, channel)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(ctx.getString(R.string.notif_private_title))
            .setContentText(ctx.getString(R.string.notif_private_text))
            .build()

    /** Notification-only or notification + sound reminder. */
    fun showDose(m: MedicineWithTimes, key: DoseKey, style: AlertStyle, repeatCount: Int) {
        val c = ctx
        val med = m.medicine
        val custom = style == AlertStyle.SOUND && (med.toneType != ToneType.DEFAULT || med.vibration != VibrationPattern.STANDARD)
        val channel = when {
            style == AlertStyle.NOTIFICATION -> CH_GENTLE
            custom -> CH_CUSTOM
            else -> CH_SOUND
        }
        val line = c.doseLine(med)
        val text = if (settingsRepo.current().hideNames) c.getString(R.string.notif_private_text)
        else listOf(line, timeText(key.scheduledAt)).filter { it.isNotBlank() }.joinToString(" · ")
        val big = buildString {
            append(text)
            if (!settingsRepo.current().hideNames) {
                if (med.instructions.isNotBlank()) append("\n").append(med.instructions)
                if (med.warning.isNotBlank()) append("\n⚠ ").append(med.warning)
            }
            if (repeatCount > 0) append("\n").append(c.getString(R.string.notif_reminder_n, repeatCount))
        }
        val builder = base(channel, m)
            .setContentTitle(if (repeatCount > 0) c.getString(R.string.notif_still_due, title(m)) else title(m))
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(big))
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setPriority(if (style == AlertStyle.NOTIFICATION) NotificationCompat.PRIORITY_DEFAULT else NotificationCompat.PRIORITY_HIGH)
            .setWhen(System.currentTimeMillis())
            .setVisibility(if (settingsRepo.current().hideNames) NotificationCompat.VISIBILITY_PRIVATE else NotificationCompat.VISIBILITY_PUBLIC)
            .setPublicVersion(privatePublicVersion(channel))
            .addDoseActions(key)
        val id = if (key.test) AlarmContract.TEST_NOTIFICATION_ID else AlarmContract.doseNotificationId(key.slotId)
        post(id, builder.build())
        if (custom) oneShot.play(tones.resolve(med.toneType, med.toneUri, forAlarm = false), med.vibration)
    }

    /** The full-screen alarm notification posted by [AlarmService]. */
    fun alarmNotification(m: MedicineWithTimes?, key: DoseKey, extra: Int): Notification {
        val c = ctx
        val fullScreen = PendingIntent.getActivity(
            appContext, 7,
            Intent(appContext, AlarmActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val title = m?.let { title(it) } ?: c.getString(R.string.notif_private_title)
        val text = buildString {
            if (m != null && !settingsRepo.current().hideNames) append(c.doseLine(m.medicine)).append(" · ")
            append(timeText(key.scheduledAt))
            if (extra > 0) append(" · ").append(c.getString(R.string.alarm_more, extra))
        }
        return base(CH_ALARM, m)
            .setContentTitle(title)
            .setContentText(text)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setFullScreenIntent(fullScreen, true)
            .setContentIntent(fullScreen)
            .setOngoing(true)
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addDoseActions(key)
            .build()
    }

    fun showPreAlarm(m: MedicineWithTimes, key: DoseKey) {
        val c = ctx
        val time = timeText(key.scheduledAt)
        val text = when {
            settingsRepo.current().hideNames -> c.getString(R.string.pre_private, time)
            m.medicine.food == FoodRelation.AFTER -> c.getString(R.string.pre_after_food, m.medicine.name, time)
            m.medicine.food == FoodRelation.BEFORE -> c.getString(R.string.pre_before_food, m.medicine.name, time)
            else -> c.getString(R.string.pre_generic, m.medicine.name, time)
        }
        post(
            AlarmContract.preNotificationId(key.slotId),
            base(CH_PRE, null)
                .setContentTitle(c.getString(R.string.pre_title))
                .setContentText(text)
                .setStyle(NotificationCompat.BigTextStyle().bigText(text))
                .setTimeoutAfter(4 * 60 * 60 * 1000L)
                .build(),
        )
    }

    fun showSnoozed(m: MedicineWithTimes, key: DoseKey, until: LocalDateTime, food: Boolean) {
        val c = ctx
        val text = c.getString(if (food) R.string.notif_after_food_until else R.string.notif_snoozed_until, timeText(until))
        post(
            AlarmContract.doseNotificationId(key.slotId),
            base(CH_PRE, m)
                .setContentTitle(title(m))
                .setContentText(text)
                .setOnlyAlertOnce(true)
                .setSilent(true)
                .addAction(R.drawable.ic_check, c.getString(R.string.action_taken),
                    actionIntent(AlarmContract.ACTION_TAKEN, key, (key.slotId % 100_000).toInt() * 10 + 1))
                .build(),
        )
    }

    fun showMissed(m: MedicineWithTimes, key: DoseKey) {
        val c = ctx
        post(
            AlarmContract.missedNotificationId(key.slotId),
            base(CH_MISSED, m)
                .setContentTitle(c.getString(R.string.notif_missed_title, title(m)))
                .setContentText(c.getString(R.string.notif_missed_text, timeText(key.scheduledAt)))
                .addAction(R.drawable.ic_check, c.getString(R.string.action_took_it),
                    actionIntent(AlarmContract.ACTION_TAKEN, key, (key.slotId % 100_000).toInt() * 10 + 5))
                .build(),
        )
    }

    fun showMissedSummary(names: List<String>) {
        if (names.isEmpty()) return
        val c = ctx
        val hidden = settingsRepo.current().hideNames
        val text = if (hidden) c.getString(R.string.notif_private_text) else names.distinct().joinToString(", ")
        post(
            AlarmContract.MISSED_SUMMARY_ID,
            base(CH_MISSED, null)
                .setContentTitle(c.resources.getQuantityString(R.plurals.missed_summary, names.size, names.size))
                .setContentText(text)
                .setStyle(NotificationCompat.BigTextStyle().bigText(text))
                .build(),
        )
    }

    fun showRefill(m: MedicineWithTimes, remaining: Double) {
        val c = ctx
        post(
            AlarmContract.refillNotificationId(m.medicine.id),
            base(CH_REFILL, m)
                .setContentTitle(c.getString(R.string.notif_refill_title, title(m)))
                .setContentText(c.getString(R.string.notif_refill_text, com.dosemate.app.util.formatAmount(remaining)))
                .build(),
        )
    }

    fun showJournalReminder() {
        val c = ctx
        post(
            AlarmContract.JOURNAL_ID,
            base(CH_JOURNAL, null)
                .setContentTitle(c.getString(R.string.notif_journal_title))
                .setContentText(c.getString(R.string.notif_journal_text))
                .build(),
        )
    }

    companion object {
        const val CH_GENTLE = "dose_gentle"
        const val CH_SOUND = "dose_sound"
        const val CH_CUSTOM = "dose_custom"
        const val CH_ALARM = "dose_alarm"
        const val CH_PRE = "pre_alarm"
        const val CH_MISSED = "missed"
        const val CH_REFILL = "refill"
        const val CH_JOURNAL = "journal"
    }
}
