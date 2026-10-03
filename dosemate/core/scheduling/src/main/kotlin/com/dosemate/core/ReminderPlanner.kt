package com.dosemate.core

import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZonedDateTime

enum class AlarmKind {
    /** Gentle heads-up a few minutes before the dose. */
    PRE,

    /** The dose itself. */
    MAIN,

    /** A snoozed, re-reminded or food-delayed dose that is still waiting for an answer. */
    REPEAT,
}

/** A dose reminder that has fired but has not yet been answered (or was snoozed). */
data class ActiveAlert(
    val medicineId: Long,
    val slotId: Long,
    val scheduledAt: LocalDateTime,
    val nextFireAt: LocalDateTime,
    val repeatCount: Int = 0,
)

/** One alarm the app should register with the system. */
data class PlannedAlarm(
    val medicineId: Long,
    val slotId: Long,
    /** Nominal time the dose is due (identifies the dose). */
    val scheduledAt: LocalDateTime,
    /** When the alarm should actually go off. */
    val fireAt: LocalDateTime,
    val kind: AlarmKind,
    val style: AlertStyle,
)

/** Rules for linked doses ("remind 30 min after Medicine A is marked taken"). */
object LinkedDoseRule {
    /**
     * The follower's dose that is tied to [leader]: the first follower dose on the same day at or
     * after the leader's nominal time.
     */
    fun followerOccurrence(follower: ScheduleEngine, leader: Occurrence): Occurrence? =
        follower.occurrencesOn(leader.date).firstOrNull { !it.time.isBefore(leader.time) }

    /** The leader's dose that a follower occurrence depends on (the last leader dose before it that day). */
    fun leaderOccurrence(leader: ScheduleEngine, follower: Occurrence): Occurrence? =
        leader.occurrencesOn(follower.date).lastOrNull { !it.time.isAfter(follower.time) }

    fun adjustedTime(leaderTakenAt: LocalDateTime, gapMinutes: Int): LocalDateTime =
        leaderTakenAt.plusMinutes(gapMinutes.toLong())
}

/**
 * Works out every alarm that should currently be registered. It is a pure function of the
 * medicines, the dose log and the active alerts, which makes rebooting, changing the time zone
 * or updating the app safe: the app simply cancels everything and registers this plan again.
 */
class ReminderPlanner(
    /** A dose whose alarm should have gone off up to this long ago still fires (e.g. after a reboot). */
    private val catchUpMinutes: Long = 15,
) {

    fun plan(
        medicines: List<MedicineSpec>,
        records: List<DoseRecord>,
        active: List<ActiveAlert>,
        now: LocalDateTime,
    ): List<PlannedAlarm> {
        val byId = medicines.associateBy { it.id }
        val engines = medicines.associate { it.id to ScheduleEngine(it.schedule) }
        val recorded = records.map { Triple(it.medicineId, it.slotId, it.scheduledAt) }.toHashSet()
        val activeKeys = active.map { Triple(it.medicineId, it.slotId, it.scheduledAt) }.toHashSet()
        val result = mutableListOf<PlannedAlarm>()

        for (alert in active) {
            val med = byId[alert.medicineId] ?: continue
            if (med.paused || med.archived) continue
            val slot = med.schedule.slots.firstOrNull { it.id == alert.slotId } ?: continue
            result += PlannedAlarm(
                medicineId = med.id,
                slotId = slot.id,
                scheduledAt = alert.scheduledAt,
                fireAt = maxOf(alert.nextFireAt, now),
                kind = AlarmKind.REPEAT,
                style = slot.alertStyle ?: med.alertStyle,
            )
        }

        val earliest = now.minusMinutes(catchUpMinutes)
        for (med in medicines) {
            if (med.paused || med.archived) continue
            val engine = engines.getValue(med.id)
            for (slot in med.schedule.slots) {
                if (!slot.enabled) continue
                // Look back one day so linked doses and catch-ups near midnight are considered.
                var cursor = earliest.minusDays(1)
                for (attempt in 0 until 8) {
                    val occ = engine.nextOccurrence(cursor, slot.id) ?: break
                    cursor = occ.dateTime
                    val key = Triple(med.id, slot.id, occ.dateTime)
                    if (key in recorded || key in activeKeys) continue
                    val fireAt = effectiveFireTime(med, occ, byId, engines, records)
                    if (fireAt.isBefore(earliest)) continue
                    val style = slot.alertStyle ?: med.alertStyle
                    result += PlannedAlarm(med.id, slot.id, occ.dateTime, maxOf(fireAt, now), AlarmKind.MAIN, style)
                    if (med.preAlarmMinutes > 0) {
                        val preAt = fireAt.minusMinutes(med.preAlarmMinutes.toLong())
                        if (preAt.isAfter(now)) {
                            result += PlannedAlarm(med.id, slot.id, occ.dateTime, preAt, AlarmKind.PRE, AlertStyle.NOTIFICATION)
                        }
                    }
                    break
                }
            }
        }
        return result.sortedBy { it.fireAt }
    }

    /** Nominal time, or the leader-taken time plus the gap when a linked rule applies. */
    fun effectiveFireTime(
        med: MedicineSpec,
        occ: Occurrence,
        byId: Map<Long, MedicineSpec>,
        engines: Map<Long, ScheduleEngine>,
        records: List<DoseRecord>,
    ): LocalDateTime {
        val link = med.link ?: return occ.dateTime
        val leaderEngine = engines[link.leaderMedicineId] ?: return occ.dateTime
        if (byId[link.leaderMedicineId] == null) return occ.dateTime
        val leaderOcc = LinkedDoseRule.leaderOccurrence(leaderEngine, occ) ?: return occ.dateTime
        // Only the first follower dose after the leader dose is linked.
        val linkedFollower = LinkedDoseRule.followerOccurrence(engines.getValue(med.id), leaderOcc)
        if (linkedFollower?.slotId != occ.slotId) return occ.dateTime
        val taken = records.firstOrNull {
            it.medicineId == link.leaderMedicineId && it.scheduledAt == leaderOcc.dateTime &&
                it.status == LogStatus.TAKEN
        } ?: return occ.dateTime
        return LinkedDoseRule.adjustedTime(taken.actionAt, link.gapMinutes)
    }

    /**
     * Doses that are now overdue by more than [missedAfterMinutes] with no answer and no alarm
     * still ringing. The app records them as missed.
     */
    fun findMissed(
        medicines: List<MedicineSpec>,
        records: List<DoseRecord>,
        active: List<ActiveAlert>,
        now: LocalDateTime,
        missedAfterMinutes: Long,
        trackFrom: Map<Long, LocalDateTime>,
        lookBackDays: Long = 14,
    ): List<Pair<MedicineSpec, Occurrence>> {
        val recorded = records.map { Triple(it.medicineId, it.slotId, it.scheduledAt) }.toHashSet()
        val activeKeys = active.map { Triple(it.medicineId, it.slotId, it.scheduledAt) }.toHashSet()
        val cutoff = now.minusMinutes(missedAfterMinutes)
        val result = mutableListOf<Pair<MedicineSpec, Occurrence>>()
        for (med in medicines) {
            if (med.paused || med.archived) continue
            val from = maxOf(trackFrom[med.id] ?: now.minusDays(lookBackDays), now.minusDays(lookBackDays))
            val engine = ScheduleEngine(med.schedule)
            for (occ in engine.occurrencesBetween(from.toLocalDate(), now.toLocalDate())) {
                if (occ.dateTime.isBefore(from) || !occ.dateTime.isBefore(cutoff)) continue
                val key = Triple(med.id, occ.slotId, occ.dateTime)
                if (key in recorded || key in activeKeys) continue
                result += med to occ
            }
        }
        return result
    }
}

/** Conversions between wall-clock time and instants. */
object TimeMath {
    /** Converts using [zone]; times inside a DST gap move forward, as an alarm clock would. */
    fun toEpochMillis(time: LocalDateTime, zone: ZoneId): Long =
        ZonedDateTime.of(time, zone).toInstant().toEpochMilli()

    fun fromEpochMillis(millis: Long, zone: ZoneId): LocalDateTime =
        LocalDateTime.ofInstant(java.time.Instant.ofEpochMilli(millis), zone)
}

/** Quiet hours window; may cross midnight (e.g. 10 PM – 7 AM). */
data class QuietHours(val enabled: Boolean, val start: LocalTime, val end: LocalTime) {
    fun contains(time: LocalTime): Boolean {
        if (!enabled || start == end) return false
        return if (start.isBefore(end)) !time.isBefore(start) && time.isBefore(end)
        else !time.isBefore(start) || time.isBefore(end)
    }
}

/** How a reminder should behave when it fires. */
object AlertPolicy {
    /**
     * Escalation: a gentle notification that is ignored comes back with sound. Alarm mode stays
     * alarm mode.
     */
    fun styleForRepeat(base: AlertStyle, repeatCount: Int, escalate: Boolean): AlertStyle =
        if (escalate && repeatCount >= 1 && base == AlertStyle.NOTIFICATION) AlertStyle.SOUND else base

    /** During quiet hours sound notifications become silent; alarms ring unless [alarmsToo]. */
    fun applyQuietHours(style: AlertStyle, inQuietHours: Boolean, alarmsToo: Boolean = false): AlertStyle = when {
        !inQuietHours -> style
        style == AlertStyle.SOUND -> AlertStyle.NOTIFICATION
        style == AlertStyle.ALARM && alarmsToo -> AlertStyle.NOTIFICATION
        else -> style
    }

    /** True once a reminder has been repeated [maxRepeats] times without an answer. */
    fun exhausted(repeatCount: Int, maxRepeats: Int): Boolean = repeatCount >= maxRepeats

    fun nextRepeat(now: LocalDateTime, intervalMinutes: Int): LocalDateTime =
        now.plusMinutes(intervalMinutes.coerceAtLeast(1).toLong())
}
