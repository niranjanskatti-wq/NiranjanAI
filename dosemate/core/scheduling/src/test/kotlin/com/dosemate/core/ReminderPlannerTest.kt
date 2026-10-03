package com.dosemate.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneId

class ReminderPlannerTest {

    private val start = LocalDate.of(2026, 10, 3)
    private val planner = ReminderPlanner()

    private fun at(day: Long, h: Int, m: Int = 0) = LocalDateTime.of(start.plusDays(day), LocalTime.of(h, m))

    private val pacroma = MedicineSpec(
        id = 2,
        schedule = Schedule(
            ScheduleType.DAILY, listOf(DoseSlot(20, LocalTime.of(21, 30))), start,
            durationType = DurationType.DAYS, durationDays = 42,
        ),
        alertStyle = AlertStyle.SOUND,
    )
    private val cetaphil = MedicineSpec(
        id = 3,
        schedule = Schedule(
            ScheduleType.CUSTOM_TIMES,
            listOf(
                DoseSlot(30, LocalTime.of(13, 0), enabled = false),
                DoseSlot(31, LocalTime.of(18, 0), enabled = false),
                DoseSlot(32, LocalTime.of(22, 0)),
            ),
            start, durationType = DurationType.DAYS, durationDays = 30,
        ),
        alertStyle = AlertStyle.NOTIFICATION,
        link = LinkRule(leaderMedicineId = 2, gapMinutes = 30),
    )
    private val teczine = MedicineSpec(
        id = 4,
        schedule = Schedule(
            ScheduleType.DAILY, listOf(DoseSlot(40, LocalTime.of(21, 0))), start,
            durationType = DurationType.DAYS, durationDays = 10,
        ),
        alertStyle = AlertStyle.ALARM,
        preAlarmMinutes = 30,
    )

    @Test
    fun `plans next dose of every slot with pre-alarm`() {
        val plan = planner.plan(listOf(pacroma, cetaphil, teczine), emptyList(), emptyList(), at(0, 12))
        val main = plan.filter { it.kind == AlarmKind.MAIN }
        assertEquals(setOf(at(0, 21, 30), at(0, 22), at(0, 21)), main.map { it.fireAt }.toSet())
        val pre = plan.single { it.kind == AlarmKind.PRE }
        assertEquals(at(0, 20, 30), pre.fireAt)
        assertEquals(4L, pre.medicineId)
        assertEquals(AlertStyle.ALARM, main.single { it.medicineId == 4L }.style)
    }

    @Test
    fun `linked dose fires gap minutes after leader is taken`() {
        val taken = DoseRecord(2, 20, at(0, 21, 30), LogStatus.TAKEN, actionAt = at(0, 21, 40))
        val plan = planner.plan(listOf(pacroma, cetaphil), listOf(taken), emptyList(), at(0, 21, 41))
        val cet = plan.single { it.medicineId == 3L }
        assertEquals(at(0, 22, 10), cet.fireAt)
        assertEquals(at(0, 22), cet.scheduledAt)
        // Pacroma's next dose is tomorrow.
        assertEquals(at(1, 21, 30), plan.single { it.medicineId == 2L }.fireAt)
    }

    @Test
    fun `linked dose can come earlier than nominal time`() {
        val taken = DoseRecord(2, 20, at(0, 21, 30), LogStatus.TAKEN, actionAt = at(0, 21, 0))
        val plan = planner.plan(listOf(pacroma, cetaphil), listOf(taken), emptyList(), at(0, 21, 1))
        assertEquals(at(0, 21, 30), plan.single { it.medicineId == 3L }.fireAt)
    }

    @Test
    fun `linked dose keeps nominal time when leader skipped or not taken`() {
        val skipped = DoseRecord(2, 20, at(0, 21, 30), LogStatus.SKIPPED, actionAt = at(0, 21, 35))
        val plan = planner.plan(listOf(pacroma, cetaphil), listOf(skipped), emptyList(), at(0, 21, 36))
        assertEquals(at(0, 22), plan.single { it.medicineId == 3L }.fireAt)
    }

    @Test
    fun `only the dose after the leader is linked`() {
        val withExtras = cetaphil.copy(
            schedule = cetaphil.schedule.copy(
                slots = cetaphil.schedule.slots.map { it.copy(enabled = true) },
            ),
        )
        val taken = DoseRecord(2, 20, at(0, 21, 30), LogStatus.TAKEN, actionAt = at(0, 21, 30))
        val plan = planner.plan(listOf(pacroma, withExtras), listOf(taken), emptyList(), at(0, 9))
        val cet = plan.filter { it.medicineId == 3L }.associateBy { it.slotId }
        assertEquals(at(0, 13), cet.getValue(30).fireAt)
        assertEquals(at(0, 18), cet.getValue(31).fireAt)
        assertEquals(at(0, 22), cet.getValue(32).fireAt)
    }

    @Test
    fun `answered doses are not re-planned`() {
        val taken = DoseRecord(4, 40, at(0, 21), LogStatus.TAKEN, actionAt = at(0, 20, 50))
        val plan = planner.plan(listOf(teczine), listOf(taken), emptyList(), at(0, 20, 55))
        assertEquals(at(1, 21), plan.single { it.kind == AlarmKind.MAIN }.fireAt)
    }

    @Test
    fun `reboot restores snoozed alert and keeps future doses`() {
        // Phone rebooted at 21:07 while Teczine was snoozed until 21:10.
        val active = ActiveAlert(4, 40, at(0, 21), nextFireAt = at(0, 21, 10), repeatCount = 1)
        val plan = planner.plan(listOf(teczine), emptyList(), listOf(active), at(0, 21, 7))
        val repeat = plan.single { it.kind == AlarmKind.REPEAT }
        assertEquals(at(0, 21, 10), repeat.fireAt)
        assertEquals(at(1, 21), plan.single { it.kind == AlarmKind.MAIN }.fireAt)
    }

    @Test
    fun `reboot after a missed alert time catches up within window`() {
        // The phone was off at 21:00 and came back at 21:05: the alarm still rings, immediately.
        val plan = planner.plan(listOf(teczine), emptyList(), emptyList(), at(0, 21, 5))
        assertEquals(at(0, 21, 5), plan.single { it.kind == AlarmKind.MAIN }.fireAt)
        assertEquals(at(0, 21), plan.single { it.kind == AlarmKind.MAIN }.scheduledAt)
        // ...but not hours later.
        val later = planner.plan(listOf(teczine), emptyList(), emptyList(), at(0, 23))
        assertEquals(at(1, 21), later.single { it.kind == AlarmKind.MAIN }.fireAt)
    }

    @Test
    fun `overdue snooze after reboot fires now`() {
        val active = ActiveAlert(4, 40, at(0, 21), nextFireAt = at(0, 21, 10))
        val plan = planner.plan(listOf(teczine), emptyList(), listOf(active), at(0, 22))
        assertEquals(at(0, 22), plan.single { it.kind == AlarmKind.REPEAT }.fireAt)
    }

    @Test
    fun `paused and finished medicines are not planned`() {
        assertTrue(planner.plan(listOf(teczine.copy(paused = true)), emptyList(), emptyList(), at(0, 12)).isEmpty())
        assertTrue(planner.plan(listOf(teczine), emptyList(), emptyList(), at(10, 12)).isEmpty())
    }

    @Test
    fun `weekly forcan plans the following week after a dose`() {
        val forcan = MedicineSpec(
            5,
            Schedule(
                ScheduleType.WEEKLY, listOf(DoseSlot(50, LocalTime.of(9, 0))), start,
                durationType = DurationType.DOSES, durationDoses = 4,
            ),
            AlertStyle.ALARM,
        )
        val taken = DoseRecord(5, 50, at(0, 9), LogStatus.TAKEN, at(0, 9, 2))
        assertEquals(at(7, 9), planner.plan(listOf(forcan), listOf(taken), emptyList(), at(0, 9, 3)).single().fireAt)
        // After the 4th dose there is nothing left.
        assertTrue(planner.plan(listOf(forcan), emptyList(), emptyList(), at(21, 10)).isEmpty())
    }

    @Test
    fun `timezone change keeps wall clock time`() {
        val now = at(0, 12)
        val plan = planner.plan(listOf(teczine), emptyList(), emptyList(), now).single { it.kind == AlarmKind.MAIN }
        val india = TimeMath.toEpochMillis(plan.fireAt, ZoneId.of("Asia/Kolkata"))
        val london = TimeMath.toEpochMillis(plan.fireAt, ZoneId.of("Europe/London"))
        // 9 PM in London is 4.5 hours after 9 PM in India (BST, early October).
        assertEquals(4.5 * 3600_000, (london - india).toDouble(), 0.0)
        assertEquals(LocalTime.of(21, 0), TimeMath.fromEpochMillis(london, ZoneId.of("Europe/London")).toLocalTime())
    }

    @Test
    fun `alarm inside a DST gap moves forward`() {
        val zone = ZoneId.of("Europe/London")
        val gap = LocalDateTime.of(2027, 3, 28, 1, 30) // clocks jump 01:00 -> 02:00
        val millis = TimeMath.toEpochMillis(gap, zone)
        assertEquals(LocalTime.of(2, 30), TimeMath.fromEpochMillis(millis, zone).toLocalTime())
    }

    @Test
    fun `missed doses are found after the grace period only`() {
        val records = listOf(DoseRecord(4, 40, at(0, 21), LogStatus.TAKEN, at(0, 21)))
        val missed = planner.findMissed(
            listOf(teczine), records, emptyList(), now = at(2, 22), missedAfterMinutes = 120,
            trackFrom = mapOf(4L to at(0, 0)),
        )
        // Day 1 missed; day 2 (21:00) is only 1 hour overdue.
        assertEquals(listOf(at(1, 21)), missed.map { it.second.dateTime })
    }

    @Test
    fun `quiet hours across midnight and escalation`() {
        val quiet = QuietHours(true, LocalTime.of(22, 0), LocalTime.of(7, 0))
        assertTrue(quiet.contains(LocalTime.of(23, 0)))
        assertTrue(quiet.contains(LocalTime.of(6, 59)))
        assertFalse(quiet.contains(LocalTime.of(7, 0)))
        assertFalse(quiet.contains(LocalTime.of(21, 59)))
        assertEquals(AlertStyle.NOTIFICATION, AlertPolicy.applyQuietHours(AlertStyle.SOUND, true))
        assertEquals(AlertStyle.ALARM, AlertPolicy.applyQuietHours(AlertStyle.ALARM, true))
        assertEquals(AlertStyle.SOUND, AlertPolicy.styleForRepeat(AlertStyle.NOTIFICATION, 1, escalate = true))
        assertEquals(AlertStyle.NOTIFICATION, AlertPolicy.styleForRepeat(AlertStyle.NOTIFICATION, 0, escalate = true))
        assertTrue(AlertPolicy.exhausted(3, 3))
    }
}
