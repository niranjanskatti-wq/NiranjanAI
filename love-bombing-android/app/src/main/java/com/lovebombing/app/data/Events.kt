package com.lovebombing.app.data

import java.time.LocalDate
import java.time.MonthDay

enum class EventKind { BIRTHDAY, ANNIVERSARY, FESTIVAL, PLAN }

data class Event(
    val date: LocalDate,
    val title: String,
    val kind: EventKind,
    val minuteOfDay: Int? = null,
    val plan: Plan? = null,
    val festivalKey: String? = null,
)

/** Birthday, anniversary, festivals and user plans falling within [start, end]. */
fun eventsBetween(
    start: LocalDate,
    end: LocalDate,
    settings: Settings?,
    plans: List<Plan>,
    festivals: List<Festival>,
): List<Event> {
    val out = ArrayList<Event>()
    val name = settings?.wifeName?.trim().orEmpty().ifEmpty { "Her" }
    for (year in start.year..end.year) {
        settings?.birthday?.let { epoch ->
            val d = MonthDay.from(LocalDate.ofEpochDay(epoch)).atYear(year)
            if (!d.isBefore(start) && !d.isAfter(end)) out += Event(d, "$name's birthday", EventKind.BIRTHDAY)
        }
        settings?.anniversary?.let { epoch ->
            val wed = LocalDate.ofEpochDay(epoch)
            val d = MonthDay.from(wed).atYear(year)
            val years = year - wed.year
            if (years > 0 && !d.isBefore(start) && !d.isAfter(end)) {
                out += Event(d, "Wedding anniversary · ${ordinal(years)}", EventKind.ANNIVERSARY)
            }
        }
    }
    festivals.filter { !it.date.isBefore(start) && !it.date.isAfter(end) }
        .forEach { out += Event(it.date, it.name, EventKind.FESTIVAL, festivalKey = it.key) }
    plans.forEach { p ->
        val d = LocalDate.ofEpochDay(p.dateEpochDay)
        if (!d.isBefore(start) && !d.isAfter(end)) out += Event(d, p.title, EventKind.PLAN, p.minuteOfDay, plan = p)
    }
    out.sortWith(compareBy<Event>({ it.date }, { it.minuteOfDay ?: -1 }))
    return out
}

fun ordinal(n: Int): String {
    val suffix = if (n % 100 in 11..13) "th" else when (n % 10) {
        1 -> "st"; 2 -> "nd"; 3 -> "rd"; else -> "th"
    }
    return "$n$suffix"
}

fun formatMinutes(minutes: Int): String {
    val h = minutes / 60
    val m = minutes % 60
    val h12 = if (h % 12 == 0) 12 else h % 12
    return "%d:%02d %s".format(h12, m, if (h < 12) "AM" else "PM")
}
