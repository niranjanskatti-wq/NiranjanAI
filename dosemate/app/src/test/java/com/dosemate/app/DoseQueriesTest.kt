package com.dosemate.app

import com.dosemate.app.data.db.ActiveAlertEntity
import com.dosemate.app.data.db.DoseLogEntity
import com.dosemate.app.data.db.DoseTimeEntity
import com.dosemate.app.data.db.MedicineEntity
import com.dosemate.app.data.db.MedicineWithTimes
import com.dosemate.app.data.repo.AppSettings
import com.dosemate.app.data.repo.DoseQueries
import com.dosemate.app.data.repo.maskFromWeekdays
import com.dosemate.app.data.repo.toSpec
import com.dosemate.app.data.repo.weekdaysFromMask
import com.dosemate.core.AlertStyle
import com.dosemate.core.DoseStatus
import com.dosemate.core.DurationType
import com.dosemate.core.LogStatus
import com.dosemate.core.ReminderPlanner
import com.dosemate.core.ScheduleType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

/** Tests the app-level mapping from Room entities to the scheduling engine. */
class DoseQueriesTest {

    private val start = LocalDate.of(2026, 10, 3)
    private val settings = AppSettings()
    private fun at(day: Long, h: Int, m: Int = 0) = LocalDateTime.of(start.plusDays(day), LocalTime.of(h, m))

    private fun med(
        id: Long,
        name: String,
        times: List<Int>,
        type: ScheduleType = ScheduleType.DAILY,
        days: Int = 10,
        linked: Long? = null,
        paused: Boolean = false,
        trackFrom: LocalDateTime = at(0, 0),
        enabled: List<Boolean> = times.map { true },
    ) = MedicineWithTimes(
        MedicineEntity(
            id = id, name = name, scheduleType = type, startDate = start, durationType = DurationType.DAYS,
            durationDays = days, linkedMedicineId = linked, linkedGapMinutes = 30, paused = paused,
            trackFrom = trackFrom, alertStyle = AlertStyle.ALARM,
        ),
        times.mapIndexed { i, minute -> DoseTimeEntity(id = id * 10 + i, medicineId = id, minuteOfDay = minute, enabled = enabled[i]) },
    )

    private val pacroma = med(2, "Pacroma", listOf(21 * 60 + 30), days = 42)
    private val cetaphil = med(3, "Cetaphil", listOf(13 * 60, 18 * 60, 22 * 60), ScheduleType.CUSTOM_TIMES, 30, linked = 2,
        enabled = listOf(false, false, true))

    @Test
    fun `weekday mask round trip`() {
        val days = setOf(DayOfWeek.MONDAY, DayOfWeek.THURSDAY, DayOfWeek.SUNDAY)
        assertEquals(days, weekdaysFromMask(maskFromWeekdays(days)))
    }

    @Test
    fun `linked dose shows adjusted time on today`() {
        val logs = listOf(DoseLogEntity(1, 2, 20, at(0, 21, 30), LogStatus.TAKEN, at(0, 21, 40)))
        val items = DoseQueries.dosesOn(start, listOf(pacroma, cetaphil), logs, emptyList(), at(0, 21, 45), settings)
        val cet = items.single { it.med.medicine.id == 3L }
        assertEquals(at(0, 22, 10), cet.dueAt)
        assertEquals(at(0, 22), cet.scheduledAt)
        assertEquals(DoseStatus.UPCOMING, cet.status)
        assertEquals(DoseStatus.TAKEN, items.single { it.med.medicine.id == 2L }.status)
    }

    @Test
    fun `doses before the medicine was added are not counted as missed`() {
        val m = med(1, "HHzole", listOf(8 * 60), trackFrom = at(0, 15))
        val items = DoseQueries.dosesOn(start, listOf(m), emptyList(), emptyList(), at(0, 16), settings)
        assertEquals(DoseStatus.DUE, items.single().status)
    }

    @Test
    fun `paused medicine hides unanswered doses and next dose skips it`() {
        val paused = med(4, "Teczine", listOf(21 * 60), paused = true)
        assertTrue(DoseQueries.dosesOn(start, listOf(paused), emptyList(), emptyList(), at(0, 12), settings).isEmpty())
        assertNull(DoseQueries.nextDose(listOf(paused), emptyList(), emptyList(), at(0, 12), settings))
    }

    @Test
    fun `snoozed dose reports snooze time and next dose uses it`() {
        val m = med(4, "Teczine", listOf(21 * 60))
        val active = listOf(ActiveAlertEntity(1, 4, 40, at(0, 21), at(0, 21, 10), snoozed = true))
        val next = DoseQueries.nextDose(listOf(m), emptyList(), active, at(0, 21, 2), settings)
        assertEquals(at(0, 21, 10), next?.snoozedUntil)
    }

    @Test
    fun `entities map to a plan that respects disabled extra reminders`() {
        val plan = ReminderPlanner().plan(listOf(pacroma.toSpec(), cetaphil.toSpec()), emptyList(), emptyList(), at(0, 9))
        assertEquals(setOf(20L, 32L), plan.map { it.slotId }.toSet())
    }
}
