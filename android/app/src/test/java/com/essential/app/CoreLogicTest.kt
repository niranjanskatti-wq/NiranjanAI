package com.essential.app

import com.essential.app.core.Classifier
import com.essential.app.core.Metrics
import com.essential.app.core.TimeUtil
import com.essential.app.core.Timeline
import com.essential.app.data.Block
import com.essential.app.data.Cat
import com.essential.app.data.KeywordRule
import com.essential.app.data.Seed
import com.essential.app.data.Type
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.time.LocalDate
import java.time.ZonedDateTime

/** Pure JVM tests for time math, the 24-hour trade-off rule, scoring and voice keyword rules. */
class CoreLogicTest {
    private val ds = 4 * 60 // day starts 4:00 (earliest wake 4:30 floored)

    @Before fun zone() { TimeUtil.zone = TimeUtil.IST }

    private fun blocks(list: List<Seed.B>) = list.mapIndexed { i, b -> Block(i + 1L, 1, b.s, b.e, b.title, b.cat, null, b.prot) }

    @Test fun twelveHourFormatting() {
        assertEquals("5 AM", TimeUtil.fmtTime(300))
        assertEquals("7:30 AM", TimeUtil.fmtTime(450))
        assertEquals("12 PM", TimeUtil.fmtTime(720))
        assertEquals("10:45 PM", TimeUtil.fmtTime(22 * 60 + 45))
        assertEquals("12 AM", TimeUtil.fmtTime(0))
        assertEquals(22 * 60 + 15, TimeUtil.parseTime("10:15 PM"))
        assertEquals(0, TimeUtil.parseTime("12 AM"))
    }

    @Test fun indianRupeeGrouping() {
        assertEquals("₹1,25,000", TimeUtil.rupees(125000.0))
        assertEquals("₹999", TimeUtil.rupees(999.0))
        assertEquals("₹12,34,567", TimeUtil.rupees(1234567.0))
        assertEquals("−₹4,500", TimeUtil.rupees(-4500.0))
        assertEquals("+₹2,100", TimeUtil.rupees(2100.0, sign = true))
    }

    @Test fun midnightBelongsToPreviousDay() {
        val t = ZonedDateTime.of(2026, 10, 6, 0, 30, 0, 0, TimeUtil.IST)
        assertEquals(LocalDate.of(2026, 10, 5), TimeUtil.logicalDate(t, ds))
        val t2 = ZonedDateTime.of(2026, 10, 6, 3, 59, 0, 0, TimeUtil.IST)
        assertEquals(LocalDate.of(2026, 10, 5), TimeUtil.logicalDate(t2, ds))
        val t3 = ZonedDateTime.of(2026, 10, 6, 4, 0, 0, 0, TimeUtil.IST)
        assertEquals(LocalDate.of(2026, 10, 6), TimeUtil.logicalDate(t3, ds))
        // 1 AM slot of Oct 5 starts on the calendar day Oct 6
        assertEquals(6, TimeUtil.slotStart(LocalDate.of(2026, 10, 5), 1, ds).dayOfMonth)
    }

    @Test fun trackedHoursNormalAndMax() {
        val normal = TimeUtil.trackedHours(5 * 60, 22 * 60, ds)
        assertEquals(5, normal.first()); assertEquals(21, normal.last()); assertEquals(17, normal.size)
        val max = TimeUtil.trackedHours(4 * 60 + 30, 23 * 60, ds)
        assertEquals(4, max.first()); assertEquals(22, max.last()); assertEquals(19, max.size)
        val late = TimeUtil.trackedHours(5 * 60, 30, ds) // sleep at 00:30
        assertEquals(listOf(23, 0), late.takeLast(2))
    }

    @Test fun defaultTemplatesCoverExactly24Hours() {
        for (t in listOf(Seed.NORMAL, Seed.MAX, Seed.SUNDAY, Seed.TRAVEL)) {
            val b = blocks(t)
            assertEquals(1440, b.sumOf { it.duration })
            assertFalse(Timeline.overlaps(b))
            assertTrue(Timeline.gaps(b, ds).isEmpty())
        }
        // Max Mode: ~18.5h awake, ~15h of work blocks
        val max = blocks(Seed.MAX)
        assertEquals(5.5, max.first { it.category == Cat.SLEEP }.duration / 60.0, 0.01)
        assertTrue(Seed.SUNDAY.any { it.cat == Cat.THINK && it.e - it.s == 120 })
    }

    @Test fun tradeOffRuleTakesTimeFromNeighbours() {
        val b = blocks(Seed.NORMAL)
        val brk = b.first { it.title == "Break" }  // 10:30–10:45
        // Extend Break to 11:15: Real estate (10:45–13:00) loses 30 minutes
        val res = Timeline.place(b, brk.copy(end = 11 * 60 + 15))
        assertEquals(1, res.affected.size)
        assertEquals("Real estate: calls, visits, meetings", res.affected[0].block.title)
        assertEquals(30, res.affected[0].lostMinutes)
        assertFalse(res.touchesProtected)
        assertEquals(1440, res.blocks.sumOf { it.duration })
        assertFalse(Timeline.overlaps(res.blocks))
    }

    @Test fun tradeOffNeverSilentlySqueezesSleep() {
        val b = blocks(Seed.NORMAL)
        val review = b.first { it.title == "Daily review" } // 21:30–22:00
        val res = Timeline.place(b, review.copy(end = 22 * 60 + 45))
        assertTrue("sleep must be reported", res.affected.any { it.block.category == Cat.SLEEP && it.lostMinutes == 45 })
        assertTrue(res.touchesProtected)
    }

    @Test fun insertingInsideABlockSplitsIt() {
        val b = blocks(Seed.NORMAL)
        val call = Block(0, 1, 8 * 60, 8 * 60 + 30, "Bank call", Cat.ADMIN, null, false)
        val res = Timeline.place(b, call)
        val ess = res.blocks.filter { it.title == "Essential Block 1" }
        assertEquals(2, ess.size)
        assertEquals(150, ess.sumOf { it.duration })
        assertTrue(res.touchesProtected)
    }

    @Test fun swapKeepsDurations() {
        val b = blocks(Seed.NORMAL)
        val s = Timeline.sorted(b, ds)
        val i = s.indexOfFirst { it.title == "Break" }
        val swapped = Timeline.swapAdjacent(b, s[i], s[i + 1])
        val brk = swapped.first { it.title == "Break" }
        val re = swapped.first { it.title.startsWith("Real estate") }
        assertEquals(10 * 60 + 30, re.start); assertEquals(15, brk.duration); assertEquals(12 * 60 + 45, brk.start)
        assertFalse(Timeline.overlaps(swapped))
    }

    @Test fun gapDetection() {
        val b = blocks(Seed.NORMAL).filter { it.title != "Break" }
        val g = Timeline.gaps(b, ds)
        assertEquals(listOf(10 * 60 + 30 to 10 * 60 + 45), g)
    }

    @Test fun blockForHourPicksMajority() {
        val b = blocks(Seed.NORMAL)
        assertEquals("Essential Block 1", Timeline.blockForHour(b, 9)?.title)
        assertEquals("Real estate: calls, visits, meetings", Timeline.blockForHour(b, 11)?.title)
        assertEquals(Cat.SLEEP, Timeline.blockForHour(b, 23)?.category)
    }

    @Test fun dailyScoreWeights() {
        val s = Metrics.score(Metrics.ScoreInput(6.0, 6.0, 10.0, 10.0, true, true, 1.0, 7, 7, true, intArrayOf(35, 10, 15, 15, 15, 10)))
        assertEquals(100, s.total)
        val half = Metrics.score(Metrics.ScoreInput(3.0, 6.0, 5.0, 10.0, true, false, 0.5, 0, 7, false, intArrayOf(35, 10, 15, 15, 15, 10)))
        assertEquals(30, half.total) // 35×0.5 + 10×0.5 + 15×0.5 = 30
    }

    @Test fun keywordRulesPickLongestMatch() {
        val rules = listOf(
            KeywordRule(1, "site visit, jv, plot", Cat.BUSINESS, 1, null),
            KeywordRule(2, "gold, crude, trade", Cat.TRADING, 3, null),
            KeywordRule(3, "client reading, consultation", Cat.BUSINESS, 2, null),
            KeywordRule(4, "youtube, instagram", Cat.OTHER, null, Type.TRIVIAL)
        )
        assertEquals(1L, Classifier.parse("Site visit at Hebbal plot", rules)?.ventureId)
        assertEquals(3L, Classifier.parse("crude short trade", rules)?.ventureId)
        assertEquals(2L, Classifier.parse("Client reading for Mrs. Rao", rules)?.ventureId)
        assertEquals(Type.TRIVIAL, Classifier.parse("watched YouTube", rules)?.type)
        assertNull(Classifier.parse("lunch", rules))
        assertNull("no partial-word matches", Classifier.parse("golden retriever walk", rules))
    }
}
