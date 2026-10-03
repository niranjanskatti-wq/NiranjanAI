package com.dosemate.app.data.repo

import com.dosemate.app.data.db.ActiveAlertEntity
import com.dosemate.app.data.db.DoseLogEntity
import com.dosemate.app.data.db.DoseTimeEntity
import com.dosemate.app.data.db.MedicineWithTimes
import com.dosemate.app.alarm.DoseKey
import com.dosemate.core.Adherence
import com.dosemate.core.DoseStatus
import com.dosemate.core.ReminderPlanner
import com.dosemate.core.ScheduleEngine
import java.time.LocalDate
import java.time.LocalDateTime

/** One dose as shown on Today, the calendar, widgets and the report. */
data class DoseItem(
    val med: MedicineWithTimes,
    val slot: DoseTimeEntity,
    val scheduledAt: LocalDateTime,
    /** When the reminder actually fires (differs for linked doses). */
    val dueAt: LocalDateTime,
    val status: DoseStatus,
    val log: DoseLogEntity?,
    val snoozedUntil: LocalDateTime?,
    val doseNumber: Int,
) {
    val key: DoseKey get() = DoseKey(med.medicine.id, slot.id, scheduledAt)
    val isOpen: Boolean get() = status == DoseStatus.DUE || status == DoseStatus.UPCOMING
}

object DoseQueries {
    private val planner = ReminderPlanner()

    fun dosesOn(
        date: LocalDate,
        meds: List<MedicineWithTimes>,
        logs: List<DoseLogEntity>,
        active: List<ActiveAlertEntity>,
        now: LocalDateTime,
        settings: AppSettings,
    ): List<DoseItem> {
        val specs = meds.associate { it.medicine.id to it.toSpec() }
        val engines = meds.associate { it.medicine.id to it.engine() }
        val records = logs.map { it.toRecord() }
        val logByKey = logs.associateBy { Triple(it.medicineId, it.slotId, it.scheduledAt) }
        val activeByKey = active.associateBy { Triple(it.medicineId, it.slotId, it.scheduledAt) }
        val result = mutableListOf<DoseItem>()
        for (med in meds) {
            val m = med.medicine
            if (m.archived) continue
            val engine: ScheduleEngine = engines.getValue(m.id)
            for (occ in engine.occurrencesOn(date)) {
                val slot = med.slot(occ.slotId) ?: continue
                val k = Triple(m.id, occ.slotId, occ.dateTime)
                val log = logByKey[k]
                if (m.paused && log == null) continue
                val due = planner.effectiveFireTime(specs.getValue(m.id), occ, specs, engines, records)
                val status = Adherence.classify(
                    due, log?.toRecord(), now,
                    settings.lateAfterMinutes.toLong(), settings.missedAfterMinutes.toLong(),
                ).let { s ->
                    // A dose before tracking started (e.g. earlier today, before it was added) is not "missed".
                    if (s == DoseStatus.MISSED && log == null && occ.dateTime.isBefore(m.trackFrom)) DoseStatus.DUE else s
                }
                result += DoseItem(
                    med = med, slot = slot, scheduledAt = occ.dateTime, dueAt = due, status = status,
                    log = log, snoozedUntil = activeByKey[k]?.takeIf { it.snoozed }?.nextFireAt,
                    doseNumber = occ.doseNumber,
                )
            }
        }
        return result.sortedBy { it.dueAt }
    }

    /** The next dose that has not happened yet, looking up to a week ahead. */
    fun nextDose(
        meds: List<MedicineWithTimes>,
        logs: List<DoseLogEntity>,
        active: List<ActiveAlertEntity>,
        now: LocalDateTime,
        settings: AppSettings,
    ): DoseItem? {
        for (offset in 0L..7L) {
            val items = dosesOn(now.toLocalDate().plusDays(offset), meds, logs, active, now, settings)
            items.firstOrNull { it.log == null && (it.snoozedUntil ?: it.dueAt).isAfter(now) }?.let { return it }
        }
        return null
    }
}
