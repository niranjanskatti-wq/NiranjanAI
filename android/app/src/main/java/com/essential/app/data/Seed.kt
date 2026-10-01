package com.essential.app.data

import android.database.sqlite.SQLiteDatabase
import com.essential.app.core.TimeUtil

/** Default ventures, templates, habits and voice rules created on first launch. */
object Seed {
    private fun t(h: Int, m: Int = 0) = h * 60 + m

    data class B(val s: Int, val e: Int, val title: String, val cat: String, val venture: String? = null, val prot: Boolean = false)

    val VENTURES = listOf(
        "Real Estate" to 0xFF7FB8A4.toInt(), "Astrology" to 0xFFB39DDB.toInt(), "Trading" to 0xFFE6C07B.toInt(),
        "Apps" to 0xFF8AB4F8.toInt(), "New Ventures" to 0xFFF2A285.toInt(), "Personal" to 0xFFA8B0B8.toInt()
    )

    val NORMAL = listOf(
        B(t(5), t(5, 15), "Wake, water, no phone", Cat.ROUTINE, "Personal"),
        B(t(5, 15), t(6), "Sadhana / meditation", Cat.SPIRITUAL, "Personal"),
        B(t(6), t(6, 45), "Exercise", Cat.HEALTH, "Personal"),
        B(t(6, 45), t(7, 30), "Bath, breakfast, set today's ONE thing", Cat.PLANNING),
        B(t(7, 30), t(10, 30), "Essential Block 1", Cat.ESSENTIAL, null, true),
        B(t(10, 30), t(10, 45), "Break", Cat.REST),
        B(t(10, 45), t(13), "Real estate: calls, visits, meetings", Cat.BUSINESS, "Real Estate"),
        B(t(13), t(14), "Lunch + 20 min rest", Cat.REST),
        B(t(14), t(16), "Essential Block 2", Cat.ESSENTIAL),
        B(t(16), t(17), "Admin, follow-ups, buffer time", Cat.ADMIN),
        B(t(17), t(18), "Family / play / walk", Cat.LIFE, "Personal"),
        B(t(18), t(18, 30), "Market prep", Cat.TRADING, "Trading"),
        B(t(18, 30), t(21), "MCX trading", Cat.TRADING, "Trading"),
        B(t(21), t(21, 30), "Dinner", Cat.REST),
        B(t(21, 30), t(22), "Daily review", Cat.PLANNING),
        B(t(22), t(5), "Sleep, 7 hours", Cat.SLEEP, null, true)
    )

    val MAX = listOf(
        B(t(4, 30), t(4, 45), "Wake, water", Cat.ROUTINE, "Personal"),
        B(t(4, 45), t(5, 30), "Sadhana", Cat.SPIRITUAL, "Personal"),
        B(t(5, 30), t(6), "Exercise, short", Cat.HEALTH, "Personal"),
        B(t(6), t(6, 30), "Bath, breakfast, set ONE thing", Cat.PLANNING),
        B(t(6, 30), t(10, 30), "Essential Block 1", Cat.ESSENTIAL, null, true),
        B(t(10, 30), t(10, 45), "Break", Cat.REST),
        B(t(10, 45), t(13, 15), "Real estate: calls, visits, meetings", Cat.BUSINESS, "Real Estate"),
        B(t(13, 15), t(13, 45), "Lunch", Cat.REST),
        B(t(13, 45), t(14, 5), "Power nap, 20 min", Cat.REST, null, true),
        B(t(14, 5), t(17, 5), "Essential Block 2", Cat.ESSENTIAL),
        B(t(17, 5), t(18), "Admin + family call or walk", Cat.ADMIN),
        B(t(18), t(18, 30), "Market prep", Cat.TRADING, "Trading"),
        B(t(18, 30), t(21, 30), "MCX trading", Cat.TRADING, "Trading"),
        B(t(21, 30), t(22), "Dinner", Cat.REST),
        B(t(22), t(22, 45), "Essential Block 3: light work, learning, planning", Cat.ESSENTIAL),
        B(t(22, 45), t(23), "Daily review", Cat.PLANNING),
        B(t(23), t(4, 30), "Sleep, 5.5 hours", Cat.SLEEP, null, true)
    )

    val SUNDAY = listOf(
        B(t(5), t(5, 15), "Wake, water, no phone", Cat.ROUTINE, "Personal"),
        B(t(5, 15), t(6, 15), "Sadhana", Cat.SPIRITUAL, "Personal"),
        B(t(6, 15), t(7, 15), "Long walk / exercise", Cat.HEALTH, "Personal"),
        B(t(7, 15), t(8), "Bath, breakfast", Cat.REST),
        B(t(8), t(10), "Think Time: reflect, explore, plan", Cat.THINK, null, true),
        B(t(10), t(12), "Family time", Cat.LIFE, "Personal"),
        B(t(12), t(13), "Weekly review & obstacle", Cat.PLANNING),
        B(t(13), t(15), "Lunch + rest", Cat.REST),
        B(t(15), t(17), "Learning / light essential work", Cat.LEARNING),
        B(t(17), t(19), "Play / outing", Cat.LIFE, "Personal"),
        B(t(19), t(20), "Plan next week, buffer", Cat.BUFFER),
        B(t(20), t(21), "Dinner", Cat.REST),
        B(t(21), t(22), "Read, wind down", Cat.REST),
        B(t(22), t(5), "Sleep, 7 hours", Cat.SLEEP, null, true)
    )

    val TRAVEL = listOf(
        B(t(5), t(5, 15), "Wake, water", Cat.ROUTINE, "Personal"),
        B(t(5, 15), t(5, 45), "Sadhana, short", Cat.SPIRITUAL, "Personal"),
        B(t(5, 45), t(6, 30), "Pack, breakfast, set ONE thing", Cat.PLANNING),
        B(t(6, 30), t(9, 30), "Travel: calls and reading", Cat.TRAVEL),
        B(t(9, 30), t(12, 30), "Meetings / site visits", Cat.BUSINESS, "Real Estate"),
        B(t(12, 30), t(13, 30), "Lunch", Cat.REST),
        B(t(13, 30), t(15, 30), "Essential work on the go", Cat.ESSENTIAL),
        B(t(15, 30), t(18), "Travel back, buffer", Cat.TRAVEL),
        B(t(18), t(18, 30), "Market prep", Cat.TRADING, "Trading"),
        B(t(18, 30), t(21), "MCX trading", Cat.TRADING, "Trading"),
        B(t(21), t(21, 30), "Dinner", Cat.REST),
        B(t(21, 30), t(22), "Daily review", Cat.PLANNING),
        B(t(22), t(5), "Sleep, 7 hours", Cat.SLEEP, null, true)
    )

    val HABITS = listOf(
        "Sadhana" to "After wake and water → sit for Sadhana",
        "Exercise" to "After Sadhana → shoes on",
        "3L water" to "After bath → fill the 1L bottle three times",
        "No phone first hour" to "Phone charges outside the bedroom",
        "Reading 20 min" to "After dinner → 20 pages",
        "Asleep on time" to "Wind-down reminder → lights out",
        "Trading rules followed" to "Before every trade → run the checklist"
    )

    val RULES = listOf(
        Triple("site visit, jv, plot, property, land, builder, flat, real estate, broker, deal, registration", Cat.BUSINESS, "Real Estate"),
        Triple("gold, crude, silver, natural gas, trade, trading, mcx, market, position", Cat.TRADING, "Trading"),
        Triple("client reading, consultation, horoscope, kundli, astrology, jathaka", Cat.BUSINESS, "Astrology"),
        Triple("app, code, coding, bug, deploy, release, android", Cat.ESSENTIAL, "Apps"),
        Triple("new idea, research, business plan, new venture", Cat.THINK, "New Ventures"),
        Triple("sadhana, meditation, pooja, japa", Cat.SPIRITUAL, "Personal"),
        Triple("gym, walk, exercise, yoga, run", Cat.HEALTH, "Personal"),
        Triple("family, kids, play, wife, parents", Cat.LIFE, "Personal"),
        Triple("email, invoice, bank, follow up, follow-up, paperwork", Cat.ADMIN, null)
    )
    const val TRIVIAL_RULE = "youtube, instagram, scrolling, whatsapp, reels, news, tv"

    fun seed(db: SQLiteDatabase) {
        val now = TimeUtil.nowMillis()
        val vid = HashMap<String, Long>()
        VENTURES.forEachIndexed { i, (name, color) ->
            vid[name] = db.insert("venture", null, cv("name" to name, "color" to color, "sort" to i, "updated_at" to now))
        }
        fun tpl(name: String, mode: String, days: String, sort: Int, blocks: List<B>) {
            val id = db.insert("template", null, cv("name" to name, "mode" to mode, "assigned_weekdays" to days, "sort" to sort, "updated_at" to now))
            blocks.forEach { b ->
                db.insert("block", null, cv("template_id" to id, "start_time" to b.s, "end_time" to b.e, "title" to b.title,
                    "category" to b.cat, "venture_id" to b.venture?.let { vid[it] }, "is_protected" to b.prot, "updated_at" to now))
            }
        }
        tpl("Weekday", Mode.NORMAL, "1,2,3,4,5,6", 0, NORMAL)
        tpl("Sprint Day", Mode.MAX, "1,2,3,4,5,6", 1, MAX)
        tpl("Sunday", Mode.NORMAL, "7", 2, SUNDAY)
        tpl("Travel Day", Mode.NORMAL, "", 3, TRAVEL)
        HABITS.forEachIndexed { i, (n, trig) -> db.insert("habit", null, cv("name" to n, "trigger" to trig, "sort" to i, "updated_at" to now)) }
        RULES.forEach { (k, c, v) -> db.insert("keyword_rule", null, cv("keywords" to k, "category" to c, "venture_id" to v?.let { vid[it] }, "updated_at" to now)) }
        db.insert("keyword_rule", null, cv("keywords" to TRIVIAL_RULE, "category" to Cat.OTHER, "type" to Type.TRIVIAL, "updated_at" to now))
        listOf("Weekly property expo stall", "Free astrology Q&A group", "Trading Telegram group").forEach {
            db.insert("commitment", null, cv("name" to it, "updated_at" to now))
        }
    }
}
