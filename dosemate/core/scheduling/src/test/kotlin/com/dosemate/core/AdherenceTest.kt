package com.dosemate.core

import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

class AdherenceTest {

    private val start = LocalDate.of(2026, 10, 3)
    private fun at(day: Long, h: Int, m: Int = 0) = LocalDateTime.of(start.plusDays(day), LocalTime.of(h, m))

    private val med = MedicineSpec(
        1,
        Schedule(ScheduleType.DAILY, listOf(DoseSlot(10, LocalTime.of(9, 0))), start, durationType = DurationType.DAYS, durationDays = 10),
        AlertStyle.ALARM,
    )

    @Test
    fun `classifies taken late skipped missed due and upcoming`() {
        val now = at(5, 10)
        val records = listOf(
            DoseRecord(1, 10, at(0, 9), LogStatus.TAKEN, at(0, 9, 5)),
            DoseRecord(1, 10, at(1, 9), LogStatus.TAKEN, at(1, 10, 30)),
            DoseRecord(1, 10, at(2, 9), LogStatus.SKIPPED, at(2, 9, 1)),
        )
        val outcomes = Adherence.outcomes(listOf(med), records, start, start.plusDays(6), now)
        assertEquals(
            listOf(
                DoseStatus.TAKEN, DoseStatus.LATE, DoseStatus.SKIPPED, DoseStatus.MISSED,
                DoseStatus.MISSED, DoseStatus.DUE, DoseStatus.UPCOMING,
            ),
            outcomes.map { it.status },
        )
        // 2 taken of 5 decided.
        assertEquals(40, Adherence.percent(outcomes))
        assertEquals(DayAdherence.LATE, Adherence.byDay(outcomes)[start.plusDays(1)])
        assertEquals(listOf(LocalTime.of(9, 0) to 3), Adherence.mostMissedTimes(outcomes))
    }

    @Test
    fun `streak counts consecutive good days and ignores today in progress`() {
        val days = mapOf(
            start to DayAdherence.TAKEN,
            start.plusDays(1) to DayAdherence.MISSED,
            start.plusDays(2) to DayAdherence.TAKEN,
            start.plusDays(3) to DayAdherence.LATE,
            start.plusDays(4) to DayAdherence.TAKEN,
            start.plusDays(5) to DayAdherence.PENDING,
        )
        assertEquals(Streaks(current = 3, best = 3), Adherence.streaks(days, start.plusDays(5)))
    }
}
