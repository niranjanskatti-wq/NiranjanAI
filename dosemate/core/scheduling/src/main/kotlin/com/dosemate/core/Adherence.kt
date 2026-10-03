package com.dosemate.core

import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

/** A dose occurrence together with its display status. */
data class DoseOutcome(
    val medicineId: Long,
    val slotId: Long,
    val scheduledAt: LocalDateTime,
    val status: DoseStatus,
)

/** Summary colour of a calendar day. */
enum class DayAdherence { NO_DOSES, TAKEN, LATE, SKIPPED, MISSED, PENDING }

data class Streaks(val current: Int, val best: Int)

/** Adherence statistics for the History and Insights screens. */
object Adherence {

    fun classify(
        scheduledAt: LocalDateTime,
        record: DoseRecord?,
        now: LocalDateTime,
        lateAfterMinutes: Long,
        missedAfterMinutes: Long,
    ): DoseStatus {
        if (record != null) {
            return when (record.status) {
                LogStatus.TAKEN ->
                    if (record.actionAt.isAfter(scheduledAt.plusMinutes(lateAfterMinutes))) DoseStatus.LATE
                    else DoseStatus.TAKEN
                LogStatus.SKIPPED -> DoseStatus.SKIPPED
                LogStatus.MISSED -> DoseStatus.MISSED
            }
        }
        return when {
            now.isBefore(scheduledAt) -> DoseStatus.UPCOMING
            now.isBefore(scheduledAt.plusMinutes(missedAfterMinutes)) -> DoseStatus.DUE
            else -> DoseStatus.MISSED
        }
    }

    /** Builds outcomes for all doses of [medicines] between two dates. */
    fun outcomes(
        medicines: List<MedicineSpec>,
        records: List<DoseRecord>,
        from: LocalDate,
        to: LocalDate,
        now: LocalDateTime,
        lateAfterMinutes: Long = 30,
        missedAfterMinutes: Long = 120,
    ): List<DoseOutcome> {
        val byKey = records.associateBy { Triple(it.medicineId, it.slotId, it.scheduledAt) }
        val result = mutableListOf<DoseOutcome>()
        for (med in medicines) {
            val engine = ScheduleEngine(med.schedule)
            for (occ in engine.occurrencesBetween(from, to)) {
                val record = byKey[Triple(med.id, occ.slotId, occ.dateTime)]
                if (record == null && (med.paused || med.archived) && occ.dateTime.isAfter(now)) continue
                val status = classify(occ.dateTime, record, now, lateAfterMinutes, missedAfterMinutes)
                result += DoseOutcome(med.id, occ.slotId, occ.dateTime, status)
            }
        }
        return result.sortedBy { it.scheduledAt }
    }

    /** Taken (on time or late) as a percentage of doses that are already decided. */
    fun percent(outcomes: List<DoseOutcome>): Int? {
        val decided = outcomes.filter { it.status != DoseStatus.UPCOMING && it.status != DoseStatus.DUE }
        if (decided.isEmpty()) return null
        val taken = decided.count { it.status == DoseStatus.TAKEN || it.status == DoseStatus.LATE }
        return Math.round(taken * 100f / decided.size)
    }

    /** The worst status of the day wins: missed > skipped > late > taken. */
    fun dayAdherence(outcomes: List<DoseOutcome>): DayAdherence {
        if (outcomes.isEmpty()) return DayAdherence.NO_DOSES
        val statuses = outcomes.map { it.status }.toSet()
        return when {
            DoseStatus.MISSED in statuses -> DayAdherence.MISSED
            DoseStatus.SKIPPED in statuses -> DayAdherence.SKIPPED
            DoseStatus.UPCOMING in statuses || DoseStatus.DUE in statuses -> DayAdherence.PENDING
            DoseStatus.LATE in statuses -> DayAdherence.LATE
            else -> DayAdherence.TAKEN
        }
    }

    fun byDay(outcomes: List<DoseOutcome>): Map<LocalDate, DayAdherence> =
        outcomes.groupBy { it.scheduledAt.toLocalDate() }.mapValues { dayAdherence(it.value) }

    /**
     * Streak = consecutive days on which every dose was taken (late counts). A day that is still
     * in progress does not break the current streak.
     */
    fun streaks(days: Map<LocalDate, DayAdherence>, today: LocalDate): Streaks {
        val ordered = days.filterValues { it != DayAdherence.NO_DOSES }.toSortedMap()
        var best = 0
        var run = 0
        for ((date, status) in ordered) {
            if (date.isAfter(today)) break
            when (status) {
                DayAdherence.TAKEN, DayAdherence.LATE -> {
                    run++
                    best = maxOf(best, run)
                }
                DayAdherence.PENDING -> if (date != today) run = 0
                else -> run = 0
            }
        }
        return Streaks(current = run, best = best)
    }

    /** Dose times that were most often missed or skipped, most-missed first. */
    fun mostMissedTimes(outcomes: List<DoseOutcome>, limit: Int = 5): List<Pair<LocalTime, Int>> =
        outcomes.filter { it.status == DoseStatus.MISSED || it.status == DoseStatus.SKIPPED }
            .groupingBy { it.scheduledAt.toLocalTime() }
            .eachCount()
            .entries
            .sortedWith(compareByDescending<Map.Entry<LocalTime, Int>> { it.value }.thenBy { it.key })
            .take(limit)
            .map { it.key to it.value }

    /** Missed or skipped doses by part of the day. */
    fun missedByPeriod(outcomes: List<DoseOutcome>): Map<DayPeriod, Int> =
        outcomes.filter { it.status == DoseStatus.MISSED || it.status == DoseStatus.SKIPPED }
            .groupingBy { DayPeriod.of(it.scheduledAt.toLocalTime()) }
            .eachCount()
}
