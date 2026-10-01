package com.essential.app.data

import android.database.sqlite.SQLiteDatabase
import com.essential.app.core.TimeUtil

/** Default ventures, templates, habits and voice rules created on first launch. */
object Seed {
    private fun t(h: Int, m: Int = 0) = h * 60 + m

    data class B(val s: Int, val e: Int, val title: String, val cat: String, val venture: String? = null, val prot: Boolean = false)

    /** No activities are pre-filled: you add your own (as many as you like) in Activities. */
    val VENTURES: List<Pair<String, Int>> = emptyList()

    val NORMAL = listOf(
        B(t(5), t(5, 15), "Morning routine", Cat.ROUTINE),
        B(t(5, 15), t(6), "Meditation", Cat.SPIRITUAL),
        B(t(6), t(6, 45), "Exercise", Cat.HEALTH),
        B(t(6, 45), t(7, 30), "Breakfast, plan today's ONE thing", Cat.PLANNING),
        B(t(7, 30), t(10, 30), "Essential Block 1", Cat.ESSENTIAL, null, true),
        B(t(10, 30), t(10, 45), "Break", Cat.REST),
        B(t(10, 45), t(13), "Work block", Cat.BUSINESS),
        B(t(13), t(14), "Lunch + 20 min rest", Cat.REST),
        B(t(14), t(16), "Essential Block 2", Cat.ESSENTIAL),
        B(t(16), t(17), "Admin, follow-ups, buffer time", Cat.ADMIN),
        B(t(17), t(18), "Family / play / walk", Cat.LIFE),
        B(t(18), t(19, 30), "Evening work block", Cat.BUSINESS),
        B(t(19, 30), t(21), "Family, reading, walk", Cat.LIFE),
        B(t(21), t(21, 30), "Dinner", Cat.REST),
        B(t(21, 30), t(22), "Daily review", Cat.PLANNING),
        B(t(22), t(5), "Sleep, 7 hours", Cat.SLEEP, null, true)
    )

    val MAX = listOf(
        B(t(4, 30), t(4, 45), "Morning routine", Cat.ROUTINE),
        B(t(4, 45), t(5, 30), "Meditation", Cat.SPIRITUAL),
        B(t(5, 30), t(6), "Exercise, short", Cat.HEALTH),
        B(t(6), t(6, 30), "Breakfast, plan the ONE thing", Cat.PLANNING),
        B(t(6, 30), t(10, 30), "Essential Block 1", Cat.ESSENTIAL, null, true),
        B(t(10, 30), t(10, 45), "Break", Cat.REST),
        B(t(10, 45), t(13, 15), "Work block", Cat.BUSINESS),
        B(t(13, 15), t(13, 45), "Lunch", Cat.REST),
        B(t(13, 45), t(14, 5), "Power nap, 20 min", Cat.REST, null, true),
        B(t(14, 5), t(17, 5), "Essential Block 2", Cat.ESSENTIAL),
        B(t(17, 5), t(18), "Admin + family call or walk", Cat.ADMIN),
        B(t(18), t(20), "Evening work block", Cat.BUSINESS),
        B(t(20), t(21, 30), "Family call, walk", Cat.LIFE),
        B(t(21, 30), t(22), "Dinner", Cat.REST),
        B(t(22), t(22, 45), "Essential Block 3: light work, learning, planning", Cat.ESSENTIAL),
        B(t(22, 45), t(23), "Daily review", Cat.PLANNING),
        B(t(23), t(4, 30), "Sleep, 5.5 hours", Cat.SLEEP, null, true)
    )

    val SUNDAY = listOf(
        B(t(5), t(5, 15), "Morning routine", Cat.ROUTINE),
        B(t(5, 15), t(6, 15), "Meditation", Cat.SPIRITUAL),
        B(t(6, 15), t(7, 15), "Long walk / exercise", Cat.HEALTH),
        B(t(7, 15), t(8), "Breakfast", Cat.REST),
        B(t(8), t(10), "Think Time: reflect, explore, plan", Cat.THINK, null, true),
        B(t(10), t(12), "Family time", Cat.LIFE),
        B(t(12), t(13), "Weekly review & obstacle", Cat.PLANNING),
        B(t(13), t(15), "Lunch + rest", Cat.REST),
        B(t(15), t(17), "Learning / light essential work", Cat.LEARNING),
        B(t(17), t(19), "Play / outing", Cat.LIFE),
        B(t(19), t(20), "Plan next week, buffer", Cat.BUFFER),
        B(t(20), t(21), "Dinner", Cat.REST),
        B(t(21), t(22), "Read, wind down", Cat.REST),
        B(t(22), t(5), "Sleep, 7 hours", Cat.SLEEP, null, true)
    )

    val TRAVEL = listOf(
        B(t(5), t(5, 15), "Morning routine", Cat.ROUTINE),
        B(t(5, 15), t(5, 45), "Meditation, short", Cat.SPIRITUAL),
        B(t(5, 45), t(6, 30), "Pack, breakfast, set ONE thing", Cat.PLANNING),
        B(t(6, 30), t(9, 30), "Travel: calls and reading", Cat.TRAVEL),
        B(t(9, 30), t(12, 30), "Meetings / visits", Cat.BUSINESS),
        B(t(12, 30), t(13, 30), "Lunch", Cat.REST),
        B(t(13, 30), t(15, 30), "Essential work on the go", Cat.ESSENTIAL),
        B(t(15, 30), t(18), "Travel back, buffer", Cat.TRAVEL),
        B(t(18), t(21), "Family, rest, unpack", Cat.LIFE),
        B(t(21), t(21, 30), "Dinner", Cat.REST),
        B(t(21, 30), t(22), "Daily review", Cat.PLANNING),
        B(t(22), t(5), "Sleep, 7 hours", Cat.SLEEP, null, true)
    )

    /** Starter habits (rename, delete or add your own on the Habits tab). */
    val HABITS = listOf("Walking" to "", "Meditation" to "")

    /** Ready-made habit ideas offered when adding a habit. */
    val HABIT_COLORS = listOf(0xFF7FD1B9, 0xFF8AB4F8, 0xFFE6C07B, 0xFFB39DDB, 0xFFF2A285, 0xFFE88A8A, 0xFF9FD3E6, 0xFFC5D88A).map { it.toInt() }

    val HABIT_IDEAS = listOf("Walking", "Meditation", "Exercise", "Reading 20 min", "Drink 3L water", "No phone first hour",
        "Sleep on time", "Journaling", "Yoga", "Stretching", "Gratitude", "Learn something new")

    val RULES: List<Triple<String, String, String?>> = emptyList()
    const val TRIVIAL_RULE = "youtube, instagram, scrolling, whatsapp, reels, news, tv"

    // ---- Names from versions 1.0–1.1, removed by the v3 migration on existing installs
    val LEGACY_VENTURES = listOf("Real Estate", "Astrology", "Trading", "Apps", "New Ventures", "Personal")
    val LEGACY_RULES = listOf(
        "site visit, jv, plot, property, land, builder, flat, real estate, broker, deal, registration",
        "client reading, consultation, horoscope, kundli, astrology, jathaka",
        "app, code, coding, bug, deploy, release, android",
        "new idea, research, business plan, new venture",
        "sadhana, meditation, pooja, japa",
        "gym, walk, exercise, yoga, run",
        "family, kids, play, wife, parents",
        "email, invoice, bank, follow up, follow-up, paperwork")
    val LEGACY_COMMITMENTS = listOf("Weekly property expo stall", "Free astrology Q&A group", "Trading Telegram group")
    val LEGACY_TITLES = mapOf(
        "Wake, water, no phone" to "Morning routine", "Wake, water" to "Morning routine",
        "Sadhana / meditation" to "Meditation", "Sadhana" to "Meditation", "Sadhana, short" to "Meditation, short",
        "Bath, breakfast, set today's ONE thing" to "Breakfast, plan today's ONE thing",
        "Bath, breakfast, set ONE thing" to "Breakfast, plan the ONE thing", "Bath, breakfast" to "Breakfast",
        "Real estate: calls, visits, meetings" to "Work block", "Astrology consultations" to "Evening work block",
        "Meetings / site visits" to "Meetings / visits")

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
        HABITS.forEachIndexed { i, (n, trig) -> db.insert("habit", null, cv("name" to n, "trigger" to trig.ifEmpty { null }, "sort" to i, "color" to HABIT_COLORS[i % HABIT_COLORS.size], "updated_at" to now)) }
        RULES.forEach { (k, c, v) -> db.insert("keyword_rule", null, cv("keywords" to k, "category" to c, "venture_id" to v?.let { vid[it] }, "updated_at" to now)) }
        db.insert("keyword_rule", null, cv("keywords" to TRIVIAL_RULE, "category" to Cat.OTHER, "type" to Type.TRIVIAL, "updated_at" to now))
    }
}
