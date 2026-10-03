package com.dosemate.core

import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

/** How often a medicine repeats. */
enum class ScheduleType {
    /** Every day at the configured dose times. */
    DAILY,

    /** Only on the selected weekdays. */
    SPECIFIC_WEEKDAYS,

    /** Every N days counted from the start date. */
    EVERY_X_DAYS,

    /** Once a week on the selected weekday (defaults to the start-date weekday). */
    WEEKLY,

    /** N times a day, evenly spread across a waking window. */
    TIMES_PER_DAY,

    /** Daily at an arbitrary list of times. */
    CUSTOM_TIMES,
}

/** How long a course lasts. */
enum class DurationType { ONGOING, END_DATE, DAYS, DOSES }

/** How loudly a dose demands attention. */
enum class AlertStyle { NOTIFICATION, SOUND, ALARM }

/** What the user recorded for a dose. */
enum class LogStatus { TAKEN, SKIPPED, MISSED }

/** Display status of a single dose occurrence. */
enum class DoseStatus { TAKEN, LATE, SKIPPED, MISSED, DUE, UPCOMING }

/** Part of the day, used to group the Today timeline and in insights. */
enum class DayPeriod {
    MORNING, AFTERNOON, EVENING, NIGHT;

    companion object {
        fun of(time: LocalTime): DayPeriod = when (time.hour) {
            in 4..11 -> MORNING
            in 12..16 -> AFTERNOON
            in 17..20 -> EVENING
            else -> NIGHT
        }
    }
}

/** A configured time of day at which a dose is due. */
data class DoseSlot(
    val id: Long,
    val time: LocalTime,
    val enabled: Boolean = true,
    /** Overrides the medicine's alert style for this time when set. */
    val alertStyle: AlertStyle? = null,
)

/** Everything needed to work out when a medicine is due. */
data class Schedule(
    val type: ScheduleType,
    val slots: List<DoseSlot>,
    val startDate: LocalDate,
    val weekdays: Set<DayOfWeek> = emptySet(),
    val intervalDays: Int = 1,
    val durationType: DurationType = DurationType.ONGOING,
    val endDate: LocalDate? = null,
    val durationDays: Int? = null,
    val durationDoses: Int? = null,
)

/** A single concrete dose: a slot on a date. */
data class Occurrence(
    val slotId: Long,
    val date: LocalDate,
    val time: LocalTime,
    /** 1-based index of this dose counted from the start of the course. */
    val doseNumber: Int,
) {
    val dateTime: LocalDateTime get() = LocalDateTime.of(date, time)
}

/** Linked gap rule: remind [gapMinutes] after the leader medicine is marked taken. */
data class LinkRule(val leaderMedicineId: Long, val gapMinutes: Int)

/** Scheduling view of a medicine used by the reminder planner. */
data class MedicineSpec(
    val id: Long,
    val schedule: Schedule,
    val alertStyle: AlertStyle,
    val preAlarmMinutes: Int = 0,
    val paused: Boolean = false,
    val archived: Boolean = false,
    val link: LinkRule? = null,
)

/** A recorded dose action. */
data class DoseRecord(
    val medicineId: Long,
    val slotId: Long,
    val scheduledAt: LocalDateTime,
    val status: LogStatus,
    val actionAt: LocalDateTime,
)
