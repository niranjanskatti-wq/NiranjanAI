package com.lovebombing.app.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.MonthDay
import java.time.YearMonth
import java.time.temporal.TemporalAdjusters

/** User's on/off and time/day changes for one automatic routine. */
@Entity(tableName = "auto_plans")
data class AutoPlanSetting(
    @PrimaryKey val templateId: String,
    val enabled: Boolean,
    val minuteOfDay: Int? = null,
    /** 1 = Monday … 7 = Sunday; only for weekly / monthly routines. */
    val dayOfWeek: Int? = null,
)

/**
 * Status of one plan occurrence, keyed "auto:<template>:<epochDay>" or "plan:<id>".
 * [epochDay]/[minuteOfDay] hold a "Change" (reschedule) of an automatic occurrence.
 */
@Entity(tableName = "plan_status")
data class PlanStatusRow(
    @PrimaryKey val key: String,
    val status: String,
    val epochDay: Long? = null,
    val minuteOfDay: Int? = null,
    val updatedAt: Long = System.currentTimeMillis(),
)

enum class PlanStatus(val label: String) {
    PENDING("Planned"), DONE("Done"), NOT_DONE("Not done"), SKIPPED("Skipped");

    companion object {
        fun of(name: String?) = entries.firstOrNull { it.name == name } ?: PENDING
    }
}

sealed interface Recurrence {
    data class Weekly(val day: DayOfWeek) : Recurrence
    /** [nth] 1..4, or -1 for the last one in the month. */
    data class MonthlyNth(val nth: Int, val day: DayOfWeek) : Recurrence
    data class BeforeBirthday(val daysBefore: Int) : Recurrence
    data class BeforeAnniversary(val daysBefore: Int) : Recurrence
    data class BeforeFestival(val daysBefore: Int) : Recurrence
}

data class AutoTemplate(
    val id: String,
    val title: String,
    val type: PlanType,
    val recurrence: Recurrence,
    val minuteOfDay: Int,
    val idea: String,
    val defaultOn: Boolean = true,
    /** For "send a message" routines: which category to suggest. */
    val messageCategory: String? = null,
) {
    val dayAdjustable get() = recurrence is Recurrence.Weekly || recurrence is Recurrence.MonthlyNth
}

private fun hm(h: Int, m: Int = 0) = h * 60 + m

/** Festivals big enough for a gift/outfit plan. */
private val MAJOR_FESTIVALS = setOf("diwali", "valentines", "karvachauth", "ugadi", "holi", "newyear", "navratri", "womensday")

object AutoPlans {
    val templates = listOf(
        AutoTemplate("weekly-date", "Date night with {name}", PlanType.DATE_NIGHT, Recurrence.Weekly(DayOfWeek.SATURDAY), hm(19, 30),
            "Pick the place yourself, book it, and tell her what time to be ready. No phones at the table."),
        AutoTemplate("friday-flowers", "Bring jasmine or flowers", PlanType.GIFT, Recurrence.Weekly(DayOfWeek.FRIDAY), hm(18, 30),
            "Pick up a gajra or a small bunch on the way home. Hand it over with a kiss."),
        AutoTemplate("sunday-breakfast", "Make her Sunday breakfast", PlanType.SURPRISE, Recurrence.Weekly(DayOfWeek.SUNDAY), hm(8, 30),
            "Let her sleep in. Make her favourite breakfast and tea, and serve it with a smile."),
        AutoTemplate("monday-note", "Leave her a love note", PlanType.SURPRISE, Recurrence.Weekly(DayOfWeek.MONDAY), hm(7, 30),
            "Three honest lines on a sticky note: mirror, handbag or lunch box."),
        AutoTemplate("tuesday-call", "Call her just to talk", PlanType.CUSTOM, Recurrence.Weekly(DayOfWeek.TUESDAY), hm(13, 30),
            "Five minutes in the middle of the day. No errands, no to-do list, just her."),
        AutoTemplate("sunday-letter", "Send {name} a long love message", PlanType.MESSAGE, Recurrence.Weekly(DayOfWeek.SUNDAY), hm(21, 0),
            "A longer, heartfelt message to end the week. One is ready for you.", messageCategory = Content.LONG_CATEGORY),
        AutoTemplate("wednesday-movie", "Movie night at home", PlanType.DATE_NIGHT, Recurrence.Weekly(DayOfWeek.WEDNESDAY), hm(21, 0),
            "Her pick of film, popcorn, one blanket, phones away.", defaultOn = false),
        AutoTemplate("thursday-walk", "Evening walk together", PlanType.CUSTOM, Recurrence.Weekly(DayOfWeek.THURSDAY), hm(19, 0),
            "Twenty minutes, just the two of you. Ask about her day and really listen.", defaultOn = false),
        AutoTemplate("sunday-chore", "Take over one of her chores", PlanType.CUSTOM, Recurrence.Weekly(DayOfWeek.SUNDAY), hm(11, 0),
            "Laundry, kitchen, groceries: pick one she usually does and do it without being asked.", defaultOn = false),
        AutoTemplate("monthly-gift", "Small surprise gift", PlanType.GIFT, Recurrence.MonthlyNth(1, DayOfWeek.SATURDAY), hm(11, 0),
            "Something small she'd love: her favourite sweet, a book, earrings, a plant. Check the Gifts tab for ideas."),
        AutoTemplate("monthly-outing", "Day out together", PlanType.TRIP, Recurrence.MonthlyNth(-1, DayOfWeek.SUNDAY), hm(10, 0),
            "A temple, a lake, a new cafe or a short drive out of the city. You plan it end to end."),
        AutoTemplate("bday-gift", "Buy {name}'s birthday gift", PlanType.GIFT, Recurrence.BeforeBirthday(10), hm(18, 0),
            "Check her wishlist first. Get it wrapped and hide it well."),
        AutoTemplate("bday-dinner", "Book her birthday dinner and cake", PlanType.CUSTOM, Recurrence.BeforeBirthday(5), hm(12, 0),
            "Reserve the restaurant and order the cake from her favourite bakery."),
        AutoTemplate("bday-midnight", "Midnight birthday wish", PlanType.MESSAGE, Recurrence.BeforeBirthday(0), hm(0, 0),
            "Be the very first to wish her. A message is ready.", messageCategory = "Birthday"),
        AutoTemplate("anniv-gift", "Anniversary gift", PlanType.GIFT, Recurrence.BeforeAnniversary(10), hm(18, 0),
            "Something meaningful: jewellery, a saree, a photo book of your years together."),
        AutoTemplate("anniv-date", "Anniversary dinner date", PlanType.DATE_NIGHT, Recurrence.BeforeAnniversary(0), hm(19, 30),
            "Dress up, take her somewhere special, and tell her why you'd marry her again."),
        AutoTemplate("festival-gift", "Gift or outfit for {name}", PlanType.GIFT, Recurrence.BeforeFestival(4), hm(18, 0),
            "A new outfit, bangles, sweets or flowers for the festival."),
        AutoTemplate("festival-wish", "Festival wish for {name}", PlanType.MESSAGE, Recurrence.BeforeFestival(0), hm(7, 30),
            "Wish her first thing in the morning. A festival message is ready.", messageCategory = Content.FESTIVAL_CATEGORY),
    )

    private val byId = templates.associateBy { it.id }
    fun template(id: String) = byId[id]

    fun describe(t: AutoTemplate, cfg: AutoPlanSetting?): String {
        val time = formatMinutes(cfg?.minuteOfDay ?: t.minuteOfDay)
        val day = cfg?.dayOfWeek?.let { DayOfWeek.of(it) }
        fun name(d: DayOfWeek) = d.name.lowercase().replaceFirstChar { it.uppercase() }
        return when (val r = t.recurrence) {
            is Recurrence.Weekly -> "Every ${name(day ?: r.day)} · $time"
            is Recurrence.MonthlyNth -> {
                val nth = when (r.nth) { 1 -> "First"; 2 -> "Second"; 3 -> "Third"; 4 -> "Fourth"; else -> "Last" }
                "$nth ${name(day ?: r.day)} of the month · $time"
            }
            is Recurrence.BeforeBirthday -> if (r.daysBefore == 0) "On her birthday · $time" else "${r.daysBefore} days before her birthday · $time"
            is Recurrence.BeforeAnniversary -> if (r.daysBefore == 0) "On your anniversary · $time" else "${r.daysBefore} days before your anniversary · $time"
            is Recurrence.BeforeFestival -> if (r.daysBefore == 0) "On major festivals · $time" else "${r.daysBefore} days before major festivals · $time"
        }
    }

    /** Original (un-rescheduled) dates of a routine within [start, end], with an optional label (festival name). */
    fun dates(
        t: AutoTemplate,
        start: LocalDate,
        end: LocalDate,
        settings: Settings?,
        festivals: List<Festival>,
        dayOverride: Int?,
    ): List<Pair<LocalDate, String?>> {
        val out = ArrayList<Pair<LocalDate, String?>>()
        fun keep(d: LocalDate, label: String? = null) { if (!d.isBefore(start) && !d.isAfter(end)) out += d to label }
        when (val r = t.recurrence) {
            is Recurrence.Weekly -> {
                val dow = dayOverride?.let { DayOfWeek.of(it) } ?: r.day
                var d = start.with(TemporalAdjusters.nextOrSame(dow))
                while (!d.isAfter(end)) { out += d to null; d = d.plusWeeks(1) }
            }
            is Recurrence.MonthlyNth -> {
                val dow = dayOverride?.let { DayOfWeek.of(it) } ?: r.day
                var ym = YearMonth.from(start)
                while (!ym.atDay(1).isAfter(end)) {
                    val first = ym.atDay(1)
                    val d = if (r.nth < 0) first.with(TemporalAdjusters.lastInMonth(dow))
                    else first.with(TemporalAdjusters.dayOfWeekInMonth(r.nth, dow))
                    keep(d)
                    ym = ym.plusMonths(1)
                }
            }
            is Recurrence.BeforeBirthday -> settings?.birthday?.let { annual(it, r.daysBefore, start, end, ::keep) }
            is Recurrence.BeforeAnniversary -> settings?.anniversary?.let { annual(it, r.daysBefore, start, end, ::keep) }
            is Recurrence.BeforeFestival -> festivals.forEach { f ->
                val isEve = f.key == "newyear" && f.date.monthValue == 12
                if (f.key in MAJOR_FESTIVALS && !isEve) keep(f.date.minusDays(r.daysBefore.toLong()), f.name)
            }
        }
        return out
    }

    private fun annual(epoch: Long, daysBefore: Int, start: LocalDate, end: LocalDate, keep: (LocalDate, String?) -> Unit) {
        val md = MonthDay.from(LocalDate.ofEpochDay(epoch))
        for (y in start.year..end.year + 1) keep(md.atYear(y).minusDays(daysBefore.toLong()), null)
    }
}

/** One plan on one day: either a user-made plan or an occurrence of an automatic routine. */
data class PlanItem(
    val key: String,
    val title: String,
    val type: PlanType,
    val date: LocalDate,
    val minuteOfDay: Int,
    val note: String,
    val status: PlanStatus,
    val template: AutoTemplate? = null,
    val plan: Plan? = null,
    val messageId: Int? = null,
    val messageText: String? = null,
    val messageCategory: String? = null,
    /** Original date for automatic occurrences (the key is based on it). */
    val originalDate: LocalDate = date,
) {
    val isAuto get() = template != null
    val at: LocalDateTime get() = LocalDateTime.of(date, LocalTime.of(minuteOfDay / 60, minuteOfDay % 60))

    /** Planned items whose time has passed count as "not done" until marked. */
    fun effectiveStatus(now: LocalDateTime = LocalDateTime.now()): PlanStatus =
        if (status == PlanStatus.PENDING && now.isAfter(at.plusHours(3))) PlanStatus.NOT_DONE else status
}

fun autoKey(templateId: String, originalDay: LocalDate) = "auto:$templateId:${originalDay.toEpochDay()}"
fun planKey(id: Long) = "plan:$id"

/** All plan items (manual + automatic, with their statuses) whose date falls within [start, end]. */
fun planItems(
    start: LocalDate,
    end: LocalDate,
    settings: Settings?,
    plans: List<Plan>,
    autos: Map<String, AutoPlanSetting>,
    statuses: Map<String, PlanStatusRow>,
    festivals: List<Festival>,
): List<PlanItem> {
    val name = settings?.wifeName?.trim().orEmpty().ifEmpty { "her" }
    val out = ArrayList<PlanItem>()
    // Generate a wider window so occurrences rescheduled into [start, end] are found too.
    val genStart = start.minusDays(62)
    val genEnd = end.plusDays(62)
    for (t in AutoPlans.templates) {
        val cfg = autos[t.id]
        if (!(cfg?.enabled ?: t.defaultOn)) continue
        val minute = cfg?.minuteOfDay ?: t.minuteOfDay
        for ((original, label) in AutoPlans.dates(t, genStart, genEnd, settings, festivals, cfg?.dayOfWeek)) {
            val key = autoKey(t.id, original)
            val st = statuses[key]
            val date = st?.epochDay?.let { LocalDate.ofEpochDay(it) } ?: original
            if (date.isBefore(start) || date.isAfter(end)) continue
            var title = t.title.replace("{name}", name)
            if (label != null) title = "$label: $title"
            out += PlanItem(
                key = key, title = title, type = t.type, date = date, minuteOfDay = st?.minuteOfDay ?: minute,
                note = t.idea, status = PlanStatus.of(st?.status), template = t,
                messageCategory = t.messageCategory, originalDate = original,
            )
        }
    }
    for (p in plans) {
        val date = LocalDate.ofEpochDay(p.dateEpochDay)
        if (date.isBefore(start) || date.isAfter(end)) continue
        val key = planKey(p.id)
        out += PlanItem(
            key = key, title = p.title, type = PlanType.of(p.type), date = date, minuteOfDay = p.minuteOfDay,
            note = p.note, status = PlanStatus.of(statuses[key]?.status), plan = p,
            messageId = p.messageId, messageText = p.messageText,
        )
    }
    out.sortWith(compareBy<PlanItem>({ it.date }, { it.minuteOfDay }))
    return out
}
