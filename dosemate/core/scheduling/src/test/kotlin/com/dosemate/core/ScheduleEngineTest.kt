package com.dosemate.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

class ScheduleEngineTest {

    private val start = LocalDate.of(2026, 10, 3) // a Saturday
    private fun slot(id: Long, h: Int, m: Int = 0, enabled: Boolean = true) =
        DoseSlot(id, LocalTime.of(h, m), enabled)

    @Test
    fun `daily course for 3 weeks ends on day 21`() {
        val engine = ScheduleEngine(
            Schedule(ScheduleType.DAILY, listOf(slot(1, 8)), start, durationType = DurationType.DAYS, durationDays = 21),
        )
        assertEquals(start.plusDays(20), engine.lastDate)
        assertEquals(21, engine.totalDoses)
        assertTrue(engine.occurrencesOn(start.plusDays(20)).isNotEmpty())
        assertTrue(engine.occurrencesOn(start.plusDays(21)).isEmpty())
        assertTrue(engine.occurrencesOn(start.minusDays(1)).isEmpty())
    }

    @Test
    fun `weekly dose on start weekday gives exactly four doses`() {
        val engine = ScheduleEngine(
            Schedule(ScheduleType.WEEKLY, listOf(slot(1, 9)), start, durationType = DurationType.DOSES, durationDoses = 4),
        )
        val all = engine.occurrencesBetween(start, start.plusDays(60))
        assertEquals(4, all.size)
        assertTrue(all.all { it.date.dayOfWeek == DayOfWeek.SATURDAY })
        assertEquals(listOf(1, 2, 3, 4), all.map { it.doseNumber })
        assertEquals(start.plusWeeks(3), engine.lastDate)
        assertEquals(4, engine.totalDoses)
    }

    @Test
    fun `weekly on a chosen weekday starts on the first matching day`() {
        val engine = ScheduleEngine(
            Schedule(
                ScheduleType.WEEKLY, listOf(slot(1, 9)), start,
                weekdays = setOf(DayOfWeek.MONDAY), durationType = DurationType.DOSES, durationDoses = 2,
            ),
        )
        val all = engine.occurrencesBetween(start, start.plusDays(30))
        assertEquals(listOf(LocalDate.of(2026, 10, 5), LocalDate.of(2026, 10, 12)), all.map { it.date })
    }

    @Test
    fun `weekly next occurrence skips to next week after this week's dose time`() {
        val engine = ScheduleEngine(Schedule(ScheduleType.WEEKLY, listOf(slot(1, 9)), start))
        val next = engine.nextOccurrence(LocalDateTime.of(start, LocalTime.of(9, 0)))
        assertEquals(LocalDateTime.of(start.plusWeeks(1), LocalTime.of(9, 0)), next?.dateTime)
    }

    @Test
    fun `specific weekdays only`() {
        val engine = ScheduleEngine(
            Schedule(
                ScheduleType.SPECIFIC_WEEKDAYS, listOf(slot(1, 8)), start,
                weekdays = setOf(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY),
                durationType = DurationType.DAYS, durationDays = 14,
            ),
        )
        val dates = engine.occurrencesBetween(start, start.plusDays(30)).map { it.date.dayOfWeek }
        assertEquals(6, dates.size)
        assertTrue(dates.all { it in setOf(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY) })
    }

    @Test
    fun `every third day with dose numbers`() {
        val engine = ScheduleEngine(
            Schedule(ScheduleType.EVERY_X_DAYS, listOf(slot(1, 8), slot(2, 20)), start, intervalDays = 3),
        )
        assertTrue(engine.matchesPattern(start))
        assertFalse(engine.matchesPattern(start.plusDays(1)))
        assertTrue(engine.matchesPattern(start.plusDays(6)))
        val day6 = engine.occurrencesOn(start.plusDays(6))
        assertEquals(listOf(5, 6), day6.map { it.doseNumber })
    }

    @Test
    fun `dose cap can end part way through a day`() {
        val engine = ScheduleEngine(
            Schedule(
                ScheduleType.TIMES_PER_DAY, listOf(slot(1, 8), slot(2, 14), slot(3, 20)), start,
                durationType = DurationType.DOSES, durationDoses = 5,
            ),
        )
        assertEquals(start.plusDays(1), engine.lastDate)
        assertEquals(2, engine.occurrencesOn(start.plusDays(1)).size)
        assertNull(engine.nextOccurrence(LocalDateTime.of(start.plusDays(1), LocalTime.of(15, 0))))
    }

    @Test
    fun `end date course and disabled slots`() {
        val engine = ScheduleEngine(
            Schedule(
                ScheduleType.CUSTOM_TIMES,
                listOf(slot(1, 13, enabled = false), slot(2, 18, enabled = false), slot(3, 22)),
                start, durationType = DurationType.END_DATE, endDate = start.plusMonths(1).minusDays(1),
            ),
        )
        assertEquals(LocalDate.of(2026, 11, 2), engine.lastDate)
        assertEquals(listOf(LocalTime.of(22, 0)), engine.occurrencesOn(start).map { it.time })
        assertEquals(31, engine.totalDoses)
    }

    @Test
    fun `progress reads day 5 of 21`() {
        val engine = ScheduleEngine(
            Schedule(ScheduleType.DAILY, listOf(slot(1, 8)), start, durationType = DurationType.DAYS, durationDays = 21),
        )
        val p = engine.progress(start.plusDays(4))
        assertEquals(5, p.dayNumber)
        assertEquals(21, p.totalDays)
        assertEquals(16, p.daysRemaining)
        assertFalse(p.finished)
        assertTrue(engine.progress(start.plusDays(21)).finished)
        assertTrue(engine.progress(start.minusDays(2)).notStarted)
        assertEquals(2, engine.progress(start.minusDays(2)).daysUntilStart)
    }

    @Test
    fun `ongoing course never ends`() {
        val engine = ScheduleEngine(Schedule(ScheduleType.DAILY, listOf(slot(1, 8)), start))
        assertNull(engine.lastDate)
        assertNull(engine.totalDoses)
        assertTrue(engine.occurrencesOn(start.plusYears(3)).isNotEmpty())
    }

    @Test
    fun `evenly spaced times`() {
        assertEquals(
            listOf(LocalTime.of(8, 0), LocalTime.of(15, 0), LocalTime.of(22, 0)),
            SlotTimes.evenlySpaced(3, LocalTime.of(8, 0), LocalTime.of(22, 0)),
        )
    }
}
