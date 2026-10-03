package com.dosemate.app.alarm

import android.content.Context
import com.dosemate.app.data.db.ActiveAlertDao
import com.dosemate.app.data.db.ActiveAlertEntity
import com.dosemate.app.data.db.DoseLogDao
import com.dosemate.app.data.db.DoseLogEntity
import com.dosemate.app.data.db.MedicineDao
import com.dosemate.app.data.db.MedicineWithTimes
import com.dosemate.app.data.repo.SettingsRepository
import com.dosemate.app.data.repo.slot
import com.dosemate.app.data.repo.toCore
import com.dosemate.app.data.repo.toRecord
import com.dosemate.app.data.repo.toSpec
import com.dosemate.app.widget.WidgetUpdater
import com.dosemate.core.AlarmKind
import com.dosemate.core.AlertPolicy
import com.dosemate.core.AlertStyle
import com.dosemate.core.LogStatus
import com.dosemate.core.ReminderPlanner
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.time.LocalDateTime
import javax.inject.Inject
import javax.inject.Singleton

/**
 * The single place where dose state changes. Every change ends with [rescheduleLocked], which
 * recomputes the whole alarm plan from the database, so alarms can never drift out of sync.
 */
@Singleton
class ReminderEngine @Inject constructor(
    @ApplicationContext private val context: Context,
    private val medicineDao: MedicineDao,
    private val logDao: DoseLogDao,
    private val alertDao: ActiveAlertDao,
    private val settingsRepo: SettingsRepository,
    private val scheduler: AlarmScheduler,
    private val notifications: NotificationHelper,
    private val widgets: WidgetUpdater,
) {
    private val mutex = Mutex()
    private val planner = ReminderPlanner()

    private fun now(): LocalDateTime = LocalDateTime.now().withNano(0)

    suspend fun rescheduleAll() = mutex.withLock { rescheduleLocked() }

    private suspend fun rescheduleLocked() {
        val settings = settingsRepo.current()
        val now = now()
        val meds = medicineDao.getAll()
        val specs = meds.map { it.toSpec() }
        val active = alertDao.all()
        val logs = logDao.between(now.minusDays(16), now.plusDays(2))
        val records = logs.map { it.toRecord() }.toMutableList()

        // Record doses nobody answered (phone off, app killed, etc.) as missed.
        val missed = planner.findMissed(
            specs, records, active.map { it.toCore() }, now,
            missedAfterMinutes = settings.missedAfterMinutes.toLong(),
            trackFrom = meds.associate { it.medicine.id to it.medicine.trackFrom },
        )
        if (missed.isNotEmpty()) {
            val names = mutableListOf<String>()
            for ((spec, occ) in missed) {
                val log = DoseLogEntity(
                    medicineId = spec.id, slotId = occ.slotId, scheduledAt = occ.dateTime,
                    status = LogStatus.MISSED, actionAt = now,
                )
                if (logDao.insertIfAbsent(log) != -1L) {
                    records += log.toRecord()
                    meds.firstOrNull { it.medicine.id == spec.id }?.let { names += it.medicine.name }
                }
            }
            notifications.showMissedSummary(names)
        }

        val plan = planner.plan(specs, records, active.map { it.toCore() }, now)
        scheduler.apply(plan)
        scheduler.scheduleMaintenance(now)
        scheduler.scheduleJournal(settings, now)
        widgets.updateAll()
    }

    /** Called by [AlarmReceiver] when a registered alarm goes off. */
    suspend fun onAlarmFired(key: DoseKey, kind: AlarmKind) = mutex.withLock {
        val med = medicineDao.get(key.medicineId)
        val slot = med?.slot(key.slotId)
        val answered = logDao.find(key.medicineId, key.slotId, key.scheduledAt) != null
        if (med != null && slot != null && !med.medicine.paused && !med.medicine.archived && !answered) {
            when (kind) {
                AlarmKind.PRE -> notifications.showPreAlarm(med, key)
                AlarmKind.MAIN, AlarmKind.REPEAT -> ring(med, key, kind)
            }
        }
        rescheduleLocked()
    }

    private suspend fun ring(med: MedicineWithTimes, key: DoseKey, kind: AlarmKind) {
        val settings = settingsRepo.current()
        val existing = alertDao.find(key.medicineId, key.slotId, key.scheduledAt)
        if (kind == AlarmKind.REPEAT && existing == null) return

        if (kind == AlarmKind.MAIN) {
            // An older occurrence of the same dose time that is still open is now missed.
            alertDao.forSlot(key.slotId).filter { it.scheduledAt != key.scheduledAt }.forEach { finalizeMissed(med, it) }
        }

        val count = when {
            existing == null -> 0
            kind == AlarmKind.MAIN -> existing.repeatCount
            existing.snoozed -> 0
            else -> existing.repeatCount + 1
        }
        if (kind == AlarmKind.REPEAT && existing?.snoozed == false && AlertPolicy.exhausted(count - 1, med.medicine.repeatMax)) {
            finalizeMissed(med, existing)
            return
        }

        val now = now()
        alertDao.upsert(
            ActiveAlertEntity(
                id = existing?.id ?: 0,
                medicineId = key.medicineId,
                slotId = key.slotId,
                scheduledAt = key.scheduledAt,
                nextFireAt = AlertPolicy.nextRepeat(now, med.medicine.repeatIntervalMinutes),
                repeatCount = count,
            ),
        )

        val slot = med.slot(key.slotId)
        val base = slot?.alertStyle ?: med.medicine.alertStyle
        val escalated = AlertPolicy.styleForRepeat(base, count, settings.escalate)
        val style = AlertPolicy.applyQuietHours(
            escalated, settings.quietHours.contains(now.toLocalTime()), settings.quietAlarmsToo,
        )
        deliver(med, key, style, count)
    }

    private fun deliver(med: MedicineWithTimes, key: DoseKey, style: AlertStyle, count: Int) {
        if (style == AlertStyle.ALARM) {
            if (!AlarmService.start(context, key)) {
                // Could not start the ringing service (e.g. background start blocked): fall back to a loud notification.
                notifications.showDose(med, key, AlertStyle.SOUND, count)
            }
        } else {
            notifications.showDose(med, key, style, count)
        }
    }

    private suspend fun finalizeMissed(med: MedicineWithTimes, alert: ActiveAlertEntity) {
        val key = DoseKey(alert.medicineId, alert.slotId, alert.scheduledAt)
        logDao.insertIfAbsent(
            DoseLogEntity(
                medicineId = alert.medicineId, slotId = alert.slotId, scheduledAt = alert.scheduledAt,
                status = LogStatus.MISSED, actionAt = now(),
            ),
        )
        alertDao.delete(alert.medicineId, alert.slotId, alert.scheduledAt)
        notifications.cancelDose(alert.slotId)
        AlarmService.dismiss(context, key)
        notifications.showMissed(med, key)
    }

    suspend fun markTaken(key: DoseKey, at: LocalDateTime = now()) = record(key, LogStatus.TAKEN, at, null)

    suspend fun markSkipped(key: DoseKey, reason: String?) = record(key, LogStatus.SKIPPED, now(), reason)

    suspend fun markMissed(key: DoseKey) = record(key, LogStatus.MISSED, now(), null)

    private suspend fun record(key: DoseKey, status: LogStatus, at: LocalDateTime, reason: String?) {
        if (key.test) {
            stopAlerts(key)
            return
        }
        mutex.withLock {
            val previous = logDao.find(key.medicineId, key.slotId, key.scheduledAt)
            logDao.upsert(
                DoseLogEntity(
                    id = previous?.id ?: 0,
                    medicineId = key.medicineId, slotId = key.slotId, scheduledAt = key.scheduledAt,
                    status = status, actionAt = at, skipReason = reason,
                ),
            )
            alertDao.delete(key.medicineId, key.slotId, key.scheduledAt)
            stopAlerts(key)
            notifications.cancel(AlarmContract.missedNotificationId(key.slotId))
            val wasTaken = previous?.status == LogStatus.TAKEN
            val isTaken = status == LogStatus.TAKEN
            if (wasTaken != isTaken) adjustStock(key.medicineId, if (isTaken) -1 else 1)
            rescheduleLocked()
        }
    }

    /** Removes the record for a dose (undo). */
    suspend fun clear(key: DoseKey) = mutex.withLock {
        val previous = logDao.find(key.medicineId, key.slotId, key.scheduledAt)
        logDao.delete(key.medicineId, key.slotId, key.scheduledAt)
        if (previous?.status == LogStatus.TAKEN) adjustStock(key.medicineId, 1)
        rescheduleLocked()
    }

    private suspend fun adjustStock(medicineId: Long, direction: Int) {
        val med = medicineDao.get(medicineId) ?: return
        val m = med.medicine
        if (!m.stockEnabled) return
        val count = (m.stockCount + direction * m.stockPerDose).coerceAtLeast(0.0)
        val low = count <= m.refillThreshold
        if (low && !m.refillAlerted) notifications.showRefill(med, count)
        medicineDao.setStock(medicineId, count, alerted = low)
    }

    /** Snooze, or "remind me after I eat" when [afterFood] is true. */
    suspend fun snooze(key: DoseKey, minutes: Int, afterFood: Boolean = false) {
        if (key.test) {
            stopAlerts(key)
            return
        }
        mutex.withLock {
            val med = medicineDao.get(key.medicineId) ?: return@withLock
            val until = now().plusMinutes(minutes.coerceAtLeast(1).toLong())
            val existing = alertDao.find(key.medicineId, key.slotId, key.scheduledAt)
            alertDao.upsert(
                ActiveAlertEntity(
                    id = existing?.id ?: 0,
                    medicineId = key.medicineId, slotId = key.slotId, scheduledAt = key.scheduledAt,
                    nextFireAt = until, repeatCount = 0, waitingForFood = afterFood, snoozed = true,
                ),
            )
            stopAlerts(key)
            notifications.showSnoozed(med, key, until, afterFood)
            rescheduleLocked()
        }
    }

    private fun stopAlerts(key: DoseKey) {
        notifications.cancelDose(key.slotId)
        if (key.test) notifications.cancel(AlarmContract.TEST_NOTIFICATION_ID)
        AlarmService.dismiss(context, key)
    }

    /** "Test alarm now": rings exactly like a real dose but records nothing. */
    suspend fun testAlarm(medicineId: Long) {
        val med = medicineDao.get(medicineId) ?: return
        val slot = med.times.minByOrNull { it.minuteOfDay }
        deliver(med, DoseKey(medicineId, slot?.id ?: 0, now(), test = true), AlertStyle.ALARM, 0)
    }

    suspend fun testNotification(medicineId: Long) {
        val med = medicineDao.get(medicineId) ?: return
        val slot = med.times.minByOrNull { it.minuteOfDay }
        val style = if (med.medicine.alertStyle == AlertStyle.ALARM) AlertStyle.SOUND else med.medicine.alertStyle
        notifications.showDose(med, DoseKey(medicineId, slot?.id ?: 0, now(), test = true), style, 0)
    }

    /** Doses recorded as missed after [since], for the missed-dose summary. */
    suspend fun missedSince(since: LocalDateTime): List<DoseLogEntity> = logDao.missedSince(since)

    /** Stops everything (used by reset). */
    suspend fun cancelEverything() = mutex.withLock {
        scheduler.cancelAll()
        RingingAlarms.clear()
        AlarmService.stopAll(context)
    }
}
