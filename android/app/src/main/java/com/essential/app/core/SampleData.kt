package com.essential.app.core

import android.content.Context
import com.essential.app.data.Cat
import com.essential.app.data.Mode
import com.essential.app.data.Plan
import com.essential.app.data.Repo
import com.essential.app.data.Type
import com.essential.app.data.cv
import java.time.DayOfWeek
import java.time.LocalDate
import kotlin.random.Random

/**
 * 14 days of realistic sample data (Normal and Max Mode days, a finished sprint, habits, sleep…).
 * Every row is flagged is_sample=1 so "Clear sample data" removes exactly these rows.
 */
object SampleData {
    fun load(ctx: Context) {
        val repo = Repo.get(ctx)
        if (repo.hasSampleData()) return
        val db = repo.db
        val r = Random(42)
        val today = Days.today(repo)
        val templates = repo.templates()
        val sprintStart = today.minusDays(13); val sprintEnd = today.minusDays(8)

        db.tx {
            // Sample activities (removed with the rest of the sample data)
            val re = db.insert("venture", cv("name" to "Project A", "color" to 0xFF7FB8A4.toInt(), "is_sample" to 1))
            val astro = db.insert("venture", cv("name" to "Clients", "color" to 0xFFB39DDB.toInt(), "is_sample" to 1))
            val apps = db.insert("venture", cv("name" to "Learning", "color" to 0xFF8AB4F8.toInt(), "is_sample" to 1))
            db.insert("sprint", cv("goal" to "Finish Project A first version", "start_date" to sprintStart.toString(), "end_date" to sprintEnd.toString(),
                "status" to "done", "recovery_end_date" to sprintEnd.plusDays(7).toString(), "report_seen" to 0, "is_sample" to 1))

            val oneThings = listOf("Finish the Project A outline", "Write the weekly report", "Draft the proposal",
                "Call 3 clients back", "Prepare notes for 2 clients", "Review the client list",
                "Close the open follow-ups", "Ship the first version", "Write site notes", "Plan next week",
                "Finish chapter 3 of the course", "Record a short demo", "Fix the top bug", "Update the task sheet")
            val trivia = listOf("Instagram scrolling", "YouTube videos", "WhatsApp groups", "News browsing")
            val reasons = listOf("Phone", "Unplanned call", "Visitor", "Said yes to something", "Tired")

            for (i in 14 downTo 1) {
                val date = today.minusDays(i.toLong())
                val inSprint = !date.isBefore(sprintStart) && !date.isAfter(sprintEnd) && date.dayOfWeek != DayOfWeek.SUNDAY
                val dow = date.dayOfWeek.value
                val mode = if (inSprint) Mode.MAX else Mode.NORMAL
                val tpl = templates.firstOrNull { it.mode == mode && dow in it.weekdays } ?: templates.first { it.mode == mode }
                val oneDone = r.nextDouble() < 0.7
                db.insert("day_plan", cv("date" to date.toString(), "template_id" to tpl.id, "mode" to mode, "one_thing" to oneThings[i - 1],
                    "task_2" to "Reply to 2 messages", "task_3" to if (r.nextBoolean()) "Pay electricity bill" else null,
                    "one_done" to oneDone, "task_2_done" to r.nextBoolean(), "is_sample" to 1))

                val blocks = repo.blocks(tpl.id)
                val hours = TimeUtil.trackedHours(repo.settings.wake(mode), repo.settings.sleep(mode), repo.dayStart())
                val late = if (inSprint) (i - 8).coerceAtLeast(0) else 0   // tiredness grows inside the sprint
                for (h in hours) {
                    if (r.nextDouble() < 0.08) continue // a few unlogged hours
                    val b = Timeline.blockForHour(blocks, h) ?: continue
                    var activity = b.title; var type = Cat.defaultType(b.category); var cat = b.category; var venture = b.ventureId
                    var followed = Plan.YES; var reason: String? = null; var money: Double? = null; var note: String? = null
                    val roll = r.nextDouble()
                    if (b.category == Cat.ESSENTIAL) {
                        activity = listOf("Project A: deep work", "Project A: writing", "Course: study", "Project A: planning")[r.nextInt(4)]
                        venture = if (activity.startsWith("Course")) apps else re
                    }
                    if (b.category == Cat.BUSINESS && r.nextDouble() < 0.3) { activity = "Client session"; venture = astro; money = listOf(1500.0, 2100.0, 2500.0, 3100.0)[r.nextInt(4)] }
                    if (b.category == Cat.BUSINESS && venture == re && (r.nextDouble() < 0.06 || (h == 12 && i in setOf(3, 9)))) { money = listOf(25000.0, 50000.0, 120000.0)[r.nextInt(3)]; note = "Payment received" }
                    when {
                        roll < 0.10 && b.category !in setOf(Cat.SLEEP, Cat.SPIRITUAL) -> {
                            activity = trivia[r.nextInt(trivia.size)]; type = Type.TRIVIAL; cat = Cat.OTHER; venture = null
                            followed = Plan.NO; reason = "Phone"; money = null
                        }
                        roll < 0.22 -> { followed = Plan.PARTLY; reason = reasons[r.nextInt(reasons.size)] }
                        roll < 0.27 -> { followed = Plan.NO; reason = reasons[r.nextInt(reasons.size)]; type = Type.NECESSARY; activity = "Unplanned: " + reason.lowercase() }
                    }
                    val lateHour = h >= 21 || h < 4
                    val focus = (if (type == Type.TRIVIAL) 2 else 3 + r.nextInt(3) - (if (lateHour) 1 else 0) - (late / 3)).coerceIn(1, 5)
                    val energy = (4 - (if (lateHour) 1 else 0) - (if (h in 14..15) 1 else 0) + r.nextInt(2) - (late / 3)).coerceIn(1, 5)
                    val at = TimeUtil.slotStart(date, h, repo.dayStart()).plusMinutes(62).toInstant().toEpochMilli()
                    db.insert("hour_log", cv("date" to date.toString(), "hour_start" to h, "minutes" to 60, "activity" to activity, "category" to cat,
                        "venture_id" to venture, "type" to type, "focus" to focus, "energy" to energy, "followed_plan" to followed,
                        "off_plan_reason" to reason, "money_amount" to money, "money_note" to note,
                        "source" to listOf("notification", "notification", "app", "voice")[r.nextInt(4)], "logged_at" to at, "is_sample" to 1))
                }

                // focus sessions inside Essential blocks
                blocks.filter { it.category == Cat.ESSENTIAL }.take(1 + r.nextInt(2)).forEach { b ->
                    val start = TimeUtil.timeOn(date, b.start, repo.dayStart()).toInstant().toEpochMilli()
                    val mins = listOf(50, 90)[r.nextInt(2)]
                    db.insert("focus_session", cv("date" to date.toString(), "start" to start, "end" to start + mins * 60_000L, "planned_minutes" to mins,
                        "task" to oneThings[i - 1], "interruptions" to r.nextInt(3), "completed" to 1, "is_sample" to 1))
                }
                // distractions
                repeat(2 + r.nextInt(5)) {
                    val h = hours[r.nextInt(hours.size)]
                    val ts = TimeUtil.slotStart(date, h, repo.dayStart()).plusMinutes(r.nextInt(60).toLong()).toInstant().toEpochMilli()
                    db.insert("distraction", cv("timestamp" to ts, "date" to date.toString(),
                        "reason" to listOf("Phone", "WhatsApp", "Unplanned call", "Visitor", null)[r.nextInt(5)], "is_sample" to 1))
                }
                // review
                if (r.nextDouble() < 0.85) db.insert("daily_review", cv("date" to date.toString(), "one_thing_done" to oneDone,
                    "small_win" to listOf("Client agreed to meet", "Finished report early", "No phone in Block 1", "Two client sessions done", "Evening walk with family")[r.nextInt(5)],
                    "trivial_to_cut" to listOf("WhatsApp groups", "Checking news", "Long lunch calls", "Instagram")[r.nextInt(4)],
                    "headline" to listOf("Steady and clear", "Busy but scattered", "Deep work morning", "Good progress", "Tired, still showed up")[r.nextInt(5)],
                    "day_rating" to (5 + r.nextInt(5)), "tomorrow_one_thing" to if (i > 1) oneThings[i - 2] else null, "is_sample" to 1))
                // habits
                repo.habits().forEach { hb -> if (r.nextDouble() < 0.72) db.insert("habit_log", cv("habit_id" to hb.id, "date" to date.toString(), "done" to 1, "is_sample" to 1)) }
                // sleep (night before)
                val bedTarget = repo.settings.sleep(mode)
                val bed = bedTarget + r.nextInt(-20, 45)
                val wake = repo.settings.wake(mode) + r.nextInt(-5, 15)
                db.insert("sleep_log", cv("date" to date.toString(), "bedtime" to ((bed % 1440) + 1440) % 1440, "wake_time" to wake,
                    "quality" to (if (inSprint) 2 + r.nextInt(3) else 3 + r.nextInt(3)), "is_sample" to 1))
            }
            listOf(Triple(12, "Free networking dinner", 3.0), Triple(9, "Unpaid talk at a club", 4.0),
                Triple(5, "Friend's side-project partnership", 10.0), Triple(2, "Weekend event stall", 8.0)).forEach { (d, w, h) ->
                db.insert("no_log", cv("date" to today.minusDays(d.toLong()).toString(), "what" to w, "hours_saved" to h, "is_sample" to 1))
            }
            listOf(Triple("Bigger contract with a key client", intArrayOf(95, 95, 90, 90), "Two evenings per week"),
                Triple("Start a YouTube channel", intArrayOf(50, 60, 80, 70), "Sunday Think Time"),
                Triple("Crypto course", intArrayOf(20, 55, 40, 50), "Evening family time")).forEachIndexed { k, (t, s, g) ->
                val total = s.average().toInt()
                db.insert("opportunity", cv("title" to t, "score_fit" to s[0], "score_money" to s[1], "score_strengths" to s[2], "score_energy" to s[3],
                    "give_up_answer" to g, "total_score" to total, "decision" to if (total >= 90) "Yes" else "Not Now",
                    "created" to today.minusDays((10 - k * 3).toLong()).toString(),
                    "review_date" to if (total >= 90) null else today.withDayOfMonth(1).plusMonths(1).toString(), "is_sample" to 1))
            }
            listOf(Triple("Weekly report", 60, 95), Triple("Draft proposal", 120, 210), Triple("Client summary", 45, 60),
                Triple("Project A screens", 180, 300), Triple("Bank paperwork", 30, 55), Triple("Course notes", 30, 40),
                Triple("Call list", 45, 70), Triple("Slides update", 90, 150)).forEachIndexed { k, (t, e, a) ->
                db.insert("task_estimate", cv("title" to t, "date" to today.minusDays((14 - k).toLong()).toString(), "estimated_minutes" to e,
                    "actual_minutes" to a, "is_sample" to 1))
            }
            db.insert("obstacle", cv("week" to TimeUtil.weekStart(today).minusWeeks(1).toString(), "obstacle" to "Unplanned calls during Essential Block 1",
                "action" to "Phone on Do Not Disturb until 10:30 AM; callbacks at 10:45", "is_sample" to 1))
        }
        repo.settings.set("sample_loaded", true)
        Hooks.afterChange(ctx)
    }
}
