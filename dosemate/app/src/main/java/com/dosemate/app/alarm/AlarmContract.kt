package com.dosemate.app.alarm

import android.content.Intent
import com.dosemate.core.AlarmKind
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import java.time.LocalDateTime
import java.time.ZoneOffset

/** Intent actions and extras shared by receivers, the alarm service and notifications. */
object AlarmContract {
    const val ACTION_FIRE = "com.dosemate.app.action.FIRE"
    const val ACTION_MAINTENANCE = "com.dosemate.app.action.MAINTENANCE"
    const val ACTION_JOURNAL = "com.dosemate.app.action.JOURNAL"

    const val ACTION_TAKEN = "com.dosemate.app.action.TAKEN"
    const val ACTION_SNOOZE = "com.dosemate.app.action.SNOOZE"
    const val ACTION_SKIP = "com.dosemate.app.action.SKIP"

    const val ACTION_RING = "com.dosemate.app.action.RING"
    const val ACTION_DISMISS_RING = "com.dosemate.app.action.DISMISS_RING"
    const val ACTION_STOP_ALL = "com.dosemate.app.action.STOP_ALL"

    const val EXTRA_MEDICINE = "medicineId"
    const val EXTRA_SLOT = "slotId"
    const val EXTRA_SCHEDULED = "scheduledAt"
    const val EXTRA_KIND = "kind"
    const val EXTRA_TEST = "test"
    const val EXTRA_MINUTES = "minutes"
    const val EXTRA_NOTIFICATION_ID = "notificationId"
    const val KEY_SKIP_REASON = "skipReason"

    fun encode(time: LocalDateTime): Long = time.toEpochSecond(ZoneOffset.UTC)
    fun decode(value: Long): LocalDateTime = LocalDateTime.ofEpochSecond(value, 0, ZoneOffset.UTC)

    fun Intent.putDose(dose: DoseKey): Intent = apply {
        putExtra(EXTRA_MEDICINE, dose.medicineId)
        putExtra(EXTRA_SLOT, dose.slotId)
        putExtra(EXTRA_SCHEDULED, encode(dose.scheduledAt))
        putExtra(EXTRA_TEST, dose.test)
    }

    fun Intent.dose(): DoseKey? {
        val med = getLongExtra(EXTRA_MEDICINE, -1)
        if (med < 0) return null
        return DoseKey(
            medicineId = med,
            slotId = getLongExtra(EXTRA_SLOT, -1),
            scheduledAt = decode(getLongExtra(EXTRA_SCHEDULED, 0)),
            test = getBooleanExtra(EXTRA_TEST, false),
        )
    }

    fun Intent.kind(): AlarmKind =
        getStringExtra(EXTRA_KIND)?.let { k -> AlarmKind.entries.firstOrNull { it.name == k } } ?: AlarmKind.MAIN

    // Notification ids
    fun doseNotificationId(slotId: Long) = 10_000 + (slotId % 9_000).toInt()
    fun preNotificationId(slotId: Long) = 20_000 + (slotId % 9_000).toInt()
    fun missedNotificationId(slotId: Long) = 30_000 + (slotId % 9_000).toInt()
    const val MISSED_SUMMARY_ID = 40_000
    fun refillNotificationId(medicineId: Long) = 50_000 + (medicineId % 9_000).toInt()
    const val JOURNAL_ID = 60_000
    const val ALARM_FOREGROUND_ID = 9_000
    const val TEST_NOTIFICATION_ID = 9_001
}

/** Identifies one dose occurrence. */
data class DoseKey(
    val medicineId: Long,
    val slotId: Long,
    val scheduledAt: LocalDateTime,
    val test: Boolean = false,
) {
    val id: String get() = "$medicineId/$slotId/${AlarmContract.encode(scheduledAt)}/$test"
}

/** Alarms that are currently ringing; observed by the full-screen alarm activity. */
object RingingAlarms {
    private val _ringing = MutableStateFlow<List<DoseKey>>(emptyList())
    val ringing: StateFlow<List<DoseKey>> = _ringing

    fun add(key: DoseKey) = _ringing.update { list -> list.filterNot { it.id == key.id } + key }
    fun remove(key: DoseKey) = _ringing.update { list -> list.filterNot { it.id == key.id } }
    fun removeDose(medicineId: Long, slotId: Long, scheduledAt: LocalDateTime) = _ringing.update { list ->
        list.filterNot { it.medicineId == medicineId && it.slotId == slotId && it.scheduledAt == scheduledAt }
    }
    fun clear() = _ringing.update { emptyList() }
    val isRinging: Boolean get() = _ringing.value.isNotEmpty()
}
