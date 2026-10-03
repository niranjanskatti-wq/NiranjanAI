package com.dosemate.core

import java.time.Duration
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.temporal.ChronoUnit

/**
 * Pure calculation of when doses fall for a single [Schedule].
 *
 * All calculations are done in local wall-clock time, so a medicine due at 9:00 PM stays at
 * 9:00 PM after the user travels to another timezone or when daylight saving changes.
 */
class ScheduleEngine(val schedule: Schedule) {

    private val activeSlots: List<DoseSlot> =
        schedule.slots.filter { it.enabled }.sortedBy { it.time }

    private val doseCap: Int? =
        if (schedule.durationType == DurationType.DOSES) schedule.durationDoses?.coerceAtLeast(1) else null

    /** Weekday used for [ScheduleType.WEEKLY]; the start date's weekday unless one was chosen. */
    private val weeklyDay = schedule.weekdays.firstOrNull() ?: schedule.startDate.dayOfWeek

    /** True when the repeat pattern lands on [date] (ignores the course end). */
    fun matchesPattern(date: LocalDate): Boolean {
        val start = schedule.startDate
        if (date.isBefore(start)) return false
        return when (schedule.type) {
            ScheduleType.DAILY, ScheduleType.TIMES_PER_DAY, ScheduleType.CUSTOM_TIMES -> true
            ScheduleType.SPECIFIC_WEEKDAYS ->
                date.dayOfWeek in schedule.weekdays.ifEmpty { setOf(start.dayOfWeek) }
            ScheduleType.EVERY_X_DAYS ->
                ChronoUnit.DAYS.between(start, date) % schedule.intervalDays.coerceAtLeast(1) == 0L
            ScheduleType.WEEKLY -> date.dayOfWeek == weeklyDay
        }
    }

    /** The last calendar day of the course, or null for an ongoing course. */
    val lastDate: LocalDate? by lazy { computeLastDate() }

    private fun computeLastDate(): LocalDate? = when (schedule.durationType) {
        DurationType.ONGOING -> null
        DurationType.END_DATE -> schedule.endDate?.let { maxOf(it, schedule.startDate) }
        DurationType.DAYS -> schedule.startDate.plusDays((schedule.durationDays ?: 1).coerceAtLeast(1) - 1L)
        DurationType.DOSES -> {
            val cap = doseCap ?: 1
            if (activeSlots.isEmpty()) {
                schedule.startDate
            } else {
                var count = 0
                var date = schedule.startDate
                var result: LocalDate = date
                for (i in 0 until MAX_SCAN_DAYS) {
                    if (matchesPattern(date)) {
                        count += activeSlots.size
                        if (count >= cap) {
                            result = date
                            break
                        }
                    }
                    date = date.plusDays(1)
                    result = date
                }
                result
            }
        }
    }

    /** True if the course covers [date] (between start and end, inclusive). */
    fun inCourse(date: LocalDate): Boolean {
        if (date.isBefore(schedule.startDate)) return false
        val last = lastDate ?: return true
        return !date.isAfter(last)
    }

    /** Number of pattern days in [start, date). */
    private fun matchingDaysBefore(date: LocalDate): Int {
        val start = schedule.startDate
        if (!date.isAfter(start)) return 0
        val days = ChronoUnit.DAYS.between(start, date)
        return when (schedule.type) {
            ScheduleType.DAILY, ScheduleType.TIMES_PER_DAY, ScheduleType.CUSTOM_TIMES -> days.toInt()
            ScheduleType.EVERY_X_DAYS -> {
                val interval = schedule.intervalDays.coerceAtLeast(1)
                ((days - 1) / interval + 1).toInt()
            }
            else -> {
                var count = 0
                var d = start
                while (d.isBefore(date)) {
                    if (matchesPattern(d)) count++
                    d = d.plusDays(1)
                }
                count
            }
        }
    }

    /** All doses due on [date], in time order. */
    fun occurrencesOn(date: LocalDate): List<Occurrence> {
        if (!inCourse(date) || !matchesPattern(date) || activeSlots.isEmpty()) return emptyList()
        val before = matchingDaysBefore(date) * activeSlots.size
        return activeSlots.mapIndexedNotNull { index, slot ->
            val number = before + index + 1
            if (doseCap != null && number > doseCap) null
            else Occurrence(slot.id, date, slot.time, number)
        }
    }

    /** All doses between two dates, inclusive. */
    fun occurrencesBetween(from: LocalDate, to: LocalDate): List<Occurrence> {
        val result = mutableListOf<Occurrence>()
        var date = maxOf(from, schedule.startDate)
        val end = lastDate?.let { minOf(it, to) } ?: to
        while (!date.isAfter(end)) {
            result += occurrencesOn(date)
            date = date.plusDays(1)
        }
        return result
    }

    /** The first dose strictly after [after], or null when the course has ended. */
    fun nextOccurrence(after: LocalDateTime, slotId: Long? = null): Occurrence? {
        var date = maxOf(after.toLocalDate(), schedule.startDate)
        val last = lastDate
        for (i in 0 until MAX_SCAN_DAYS) {
            if (last != null && date.isAfter(last)) return null
            val hit = occurrencesOn(date).firstOrNull {
                (slotId == null || it.slotId == slotId) && it.dateTime.isAfter(after)
            }
            if (hit != null) return hit
            date = date.plusDays(1)
        }
        return null
    }

    /** Finds the occurrence of [slotId] that was nominally due at [at], if it is a real dose. */
    fun occurrenceAt(slotId: Long, at: LocalDateTime): Occurrence? =
        occurrencesOn(at.toLocalDate()).firstOrNull { it.slotId == slotId && it.time == at.toLocalTime() }

    /** Total number of doses in the course, or null when ongoing. */
    val totalDoses: Int? by lazy {
        when {
            doseCap != null -> doseCap
            lastDate == null -> null
            else -> (matchingDaysBefore(lastDate!!.plusDays(1))) * activeSlots.size
        }
    }

    /** Progress of the course on [today]. */
    fun progress(today: LocalDate): CourseProgress {
        val start = schedule.startDate
        val last = lastDate
        val totalDays = last?.let { (ChronoUnit.DAYS.between(start, it) + 1).toInt() }
        if (today.isBefore(start)) {
            return CourseProgress(
                dayNumber = 0, totalDays = totalDays, daysRemaining = totalDays,
                fraction = 0f, notStarted = true, finished = false,
                daysUntilStart = ChronoUnit.DAYS.between(today, start).toInt(),
            )
        }
        val elapsed = (ChronoUnit.DAYS.between(start, today) + 1).toInt()
        if (totalDays == null) {
            return CourseProgress(elapsed, null, null, 0f, notStarted = false, finished = false)
        }
        val finished = today.isAfter(last)
        val day = elapsed.coerceAtMost(totalDays)
        return CourseProgress(
            dayNumber = day,
            totalDays = totalDays,
            daysRemaining = (totalDays - day).coerceAtLeast(0),
            fraction = if (finished) 1f else day.toFloat() / totalDays,
            notStarted = false,
            finished = finished,
        )
    }

    companion object {
        /** Upper bound on day-by-day scans (about ten years). */
        const val MAX_SCAN_DAYS = 3660
    }
}

/** Course progress shown as "Day 5 of 21". */
data class CourseProgress(
    val dayNumber: Int,
    val totalDays: Int?,
    val daysRemaining: Int?,
    val fraction: Float,
    val notStarted: Boolean,
    val finished: Boolean,
    val daysUntilStart: Int = 0,
)

/** Helpers for building dose times. */
object SlotTimes {
    /** [count] times evenly spread from [first] to [last] (e.g. 3 times between 8 AM and 10 PM). */
    fun evenlySpaced(count: Int, first: LocalTime, last: LocalTime): List<LocalTime> {
        if (count <= 1) return listOf(first)
        var span = Duration.between(first, last).toMinutes()
        if (span <= 0) span += 24 * 60
        val step = span / (count - 1)
        return (0 until count).map { first.plusMinutes(step * it) }
    }
}
