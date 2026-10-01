package com.essential.app.core

import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.time.temporal.TemporalAdjusters
import java.util.Locale
import kotlin.math.abs
import kotlin.math.roundToLong

/**
 * Time helpers. Pure functions (no Android types) so they can be unit-tested on the JVM.
 *
 * "Logical day": the day starts at [dayStart] minutes (the earliest wake time, floored to the hour).
 * An hour logged at 01:00 belongs to the previous day.
 */
object TimeUtil {
    val IST: ZoneId = ZoneId.of("Asia/Kolkata")
    var zone: ZoneId = IST

    /** Single time source for the whole app (replaceable in tests). */
    @JvmStatic var clock: () -> Long = { System.currentTimeMillis() }
    fun now(): ZonedDateTime = Instant.ofEpochMilli(clock()).atZone(zone)
    fun nowMillis(): Long = clock()
    fun at(millis: Long): ZonedDateTime = Instant.ofEpochMilli(millis).atZone(zone)

    fun dayStartFrom(wakeA: Int, wakeB: Int): Int = (minOf(wakeA, wakeB) / 60) * 60

    fun logicalDate(t: ZonedDateTime, dayStart: Int): LocalDate = t.minusMinutes(dayStart.toLong()).toLocalDate()

    /** Absolute start of clock-hour [hour] on logical day [date]. */
    fun slotStart(date: LocalDate, hour: Int, dayStart: Int): ZonedDateTime {
        val d = if (hour * 60 >= dayStart) date else date.plusDays(1)
        return d.atTime(hour, 0).atZone(zone)
    }

    /** Absolute time for minute-of-day [min] within logical day [date]. */
    fun timeOn(date: LocalDate, min: Int, dayStart: Int): ZonedDateTime {
        val m = ((min % 1440) + 1440) % 1440
        val d = if (m >= dayStart) date else date.plusDays(1)
        return d.atTime(m / 60, m % 60).atZone(zone)
    }

    /** Minutes since the logical day start, for ordering. */
    fun offset(minOfDay: Int, dayStart: Int): Int = ((minOfDay - dayStart) % 1440 + 1440) % 1440

    /** Clock hours tracked on a day running from [wake] to [sleep] (minutes of day). */
    fun trackedHours(wake: Int, sleep: Int, dayStart: Int): List<Int> {
        val wOff = (offset(wake, dayStart) / 60) * 60
        var sOff = offset(sleep, dayStart)
        if (sOff <= wOff) sOff += 1440
        val out = ArrayList<Int>()
        var o = wOff
        while (o < sOff && o < 1440) { out.add(((dayStart + o) / 60) % 24); o += 60 }
        return out
    }

    fun minuteOfDay(t: ZonedDateTime): Int = t.hour * 60 + t.minute

    fun fmtTime(min: Int): String {
        val m = ((min % 1440) + 1440) % 1440
        val h = m / 60; val mm = m % 60
        val h12 = if (h % 12 == 0) 12 else h % 12
        val ap = if (h < 12) "AM" else "PM"
        return if (mm == 0) "$h12 $ap" else "$h12:${mm.toString().padStart(2, '0')} $ap"
    }

    fun fmtTimeFull(min: Int): String {
        val m = ((min % 1440) + 1440) % 1440
        val h = m / 60; val mm = m % 60
        val h12 = if (h % 12 == 0) 12 else h % 12
        return "$h12:${mm.toString().padStart(2, '0')} ${if (h < 12) "AM" else "PM"}"
    }

    fun fmtClock(t: ZonedDateTime): String = fmtTime(minuteOfDay(t))

    fun fmtHourRange(hour: Int): String = "${fmtTime(hour * 60)} – ${fmtTime((hour + 1) * 60)}"

    private val dayFmt = DateTimeFormatter.ofPattern("EEE, d MMM", Locale.ENGLISH)
    private val longFmt = DateTimeFormatter.ofPattern("EEEE, d MMMM", Locale.ENGLISH)
    private val shortFmt = DateTimeFormatter.ofPattern("d MMM", Locale.ENGLISH)
    private val dowFmt = DateTimeFormatter.ofPattern("EEE", Locale.ENGLISH)
    private val monthFmt = DateTimeFormatter.ofPattern("MMMM yyyy", Locale.ENGLISH)
    fun fmtDay(d: LocalDate): String = d.format(dayFmt)
    fun fmtDayLong(d: LocalDate): String = d.format(longFmt)
    fun fmtShort(d: LocalDate): String = d.format(shortFmt)
    fun fmtDow(d: LocalDate): String = d.format(dowFmt)
    fun fmtMonth(d: LocalDate): String = d.format(monthFmt)

    fun fmtDuration(mins: Long): String {
        val m = abs(mins)
        val h = m / 60; val r = m % 60
        return when { h == 0L -> "${r}m"; r == 0L -> "${h}h"; else -> "${h}h ${r}m" }
    }

    fun fmtCountdown(secs: Long): String {
        val s = maxOf(0, secs)
        val h = s / 3600; val m = (s % 3600) / 60; val ss = s % 60
        return if (h > 0) "$h:${m.toString().padStart(2, '0')}:${ss.toString().padStart(2, '0')}"
        else "$m:${ss.toString().padStart(2, '0')}"
    }

    fun fmtHours(h: Double): String {
        val r = Math.round(h * 10) / 10.0
        return if (r == Math.floor(r)) "${r.toInt()}" else "$r"
    }

    /** Indian digit grouping: ₹1,25,000 */
    fun rupees(v: Double, sign: Boolean = false): String {
        val neg = v < 0
        val n = abs(v).roundToLong()
        val s = n.toString()
        val grouped = if (s.length <= 3) s else {
            val last3 = s.takeLast(3)
            var rest = s.dropLast(3)
            val parts = ArrayList<String>()
            while (rest.length > 2) { parts.add(0, rest.takeLast(2)); rest = rest.dropLast(2) }
            if (rest.isNotEmpty()) parts.add(0, rest)
            parts.joinToString(",") + "," + last3
        }
        val prefix = if (neg) "−" else if (sign && n > 0) "+" else ""
        return "$prefix₹$grouped"
    }

    fun parseTime(s: String): Int? {
        val t = s.trim().uppercase(Locale.ENGLISH)
        val m = Regex("^(\\d{1,2})(?::(\\d{2}))?\\s*(AM|PM)?$").find(t) ?: return null
        var h = m.groupValues[1].toInt(); val mm = m.groupValues[2].ifEmpty { "0" }.toInt()
        val ap = m.groupValues[3]
        if (mm > 59) return null
        if (ap.isNotEmpty()) { if (h !in 1..12) return null; if (ap == "AM" && h == 12) h = 0; if (ap == "PM" && h != 12) h += 12 }
        else if (h > 23) return null
        return h * 60 + mm
    }

    fun weekStart(d: LocalDate): LocalDate = d.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
    fun localTime(min: Int): LocalTime = LocalTime.of((min / 60) % 24, min % 60)
    fun monthKey(d: LocalDate): String = "%04d-%02d".format(d.year, d.monthValue)
}
