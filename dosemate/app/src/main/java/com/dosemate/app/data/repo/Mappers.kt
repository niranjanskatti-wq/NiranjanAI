package com.dosemate.app.data.repo

import com.dosemate.app.data.db.ActiveAlertEntity
import com.dosemate.app.data.db.DoseLogEntity
import com.dosemate.app.data.db.DoseTimeEntity
import com.dosemate.app.data.db.MedicineEntity
import com.dosemate.app.data.db.MedicineWithTimes
import com.dosemate.core.ActiveAlert
import com.dosemate.core.DoseRecord
import com.dosemate.core.DoseSlot
import com.dosemate.core.LinkRule
import com.dosemate.core.MedicineSpec
import com.dosemate.core.Schedule
import com.dosemate.core.ScheduleEngine
import java.time.DayOfWeek
import java.time.LocalTime

fun weekdaysFromMask(mask: Int): Set<DayOfWeek> =
    DayOfWeek.entries.filter { mask and (1 shl (it.value - 1)) != 0 }.toSet()

fun maskFromWeekdays(days: Set<DayOfWeek>): Int = days.fold(0) { acc, d -> acc or (1 shl (d.value - 1)) }

val DoseTimeEntity.time: LocalTime get() = LocalTime.of(minuteOfDay / 60, minuteOfDay % 60)

fun DoseTimeEntity.toSlot() = DoseSlot(id = id, time = time, enabled = enabled, alertStyle = alertStyle)

fun MedicineEntity.schedule(times: List<DoseTimeEntity>) = Schedule(
    type = scheduleType,
    slots = times.map { it.toSlot() },
    startDate = startDate,
    weekdays = weekdaysFromMask(weekdays),
    intervalDays = intervalDays,
    durationType = durationType,
    endDate = endDate,
    durationDays = durationDays,
    durationDoses = durationDoses,
)

fun MedicineWithTimes.toSpec() = MedicineSpec(
    id = medicine.id,
    schedule = medicine.schedule(times),
    alertStyle = medicine.alertStyle,
    preAlarmMinutes = medicine.preAlarmMinutes,
    paused = medicine.paused,
    archived = medicine.archived,
    link = medicine.linkedMedicineId?.let { LinkRule(it, medicine.linkedGapMinutes) },
)

fun MedicineWithTimes.engine() = ScheduleEngine(medicine.schedule(times))

fun MedicineWithTimes.slot(slotId: Long): DoseTimeEntity? = times.firstOrNull { it.id == slotId }

val MedicineWithTimes.sortedTimes: List<DoseTimeEntity> get() = times.sortedBy { it.minuteOfDay }

fun DoseLogEntity.toRecord() = DoseRecord(medicineId, slotId, scheduledAt, status, actionAt)

fun ActiveAlertEntity.toCore() = ActiveAlert(medicineId, slotId, scheduledAt, nextFireAt, repeatCount)
