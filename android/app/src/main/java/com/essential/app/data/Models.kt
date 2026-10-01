package com.essential.app.data

import java.time.LocalDate

object Cat {
    const val ROUTINE = "Routine"; const val SPIRITUAL = "Spiritual"; const val HEALTH = "Health"
    const val PLANNING = "Planning"; const val ESSENTIAL = "Essential"; const val REST = "Rest"
    const val BUSINESS = "Business"; const val ADMIN = "Admin"; const val LIFE = "Life"
    const val SLEEP = "Sleep"; const val THINK = "Think Time"
    const val LEARNING = "Learning"; const val BUFFER = "Buffer"; const val TRAVEL = "Travel"; const val OTHER = "Other"

    val ALL = listOf(ESSENTIAL, BUSINESS, ADMIN, PLANNING, THINK, LEARNING, BUFFER, ROUTINE,
        SPIRITUAL, HEALTH, LIFE, REST, TRAVEL, SLEEP, OTHER)

    /** Categories that count toward "working hours". */
    val WORK = setOf(ESSENTIAL, BUSINESS, ADMIN, PLANNING, THINK, LEARNING, BUFFER)

    /** Type implied when an hour is logged "as planned". */
    fun defaultType(category: String?): String = when (category) {
        ESSENTIAL, THINK -> Type.ESSENTIAL
        else -> Type.NECESSARY
    }
}

object Type {
    const val ESSENTIAL = "Essential"; const val NECESSARY = "Necessary"; const val TRIVIAL = "Trivial"
    val ALL = listOf(ESSENTIAL, NECESSARY, TRIVIAL)
}

object Plan {
    const val YES = "Yes"; const val PARTLY = "Partly"; const val NO = "No"
    val ALL = listOf(YES, PARTLY, NO)
    val REASONS = listOf("Phone", "Unplanned call", "Visitor", "Said yes to something", "Tired", "Emergency", "Other")
}

object Source { const val NOTIFICATION = "notification"; const val APP = "app"; const val VOICE = "voice"; const val FOCUS = "focus"; const val WIDGET = "widget" }

object Mode { const val NORMAL = "normal"; const val MAX = "max" }

data class Venture(val id: Long, val name: String, val color: Int, val archived: Boolean, val sort: Int)

data class Goal(
    val id: Long, val title: String, val type: String, val startDate: LocalDate, val endDate: LocalDate,
    val progress: Int, val status: String
) { val isIntent get() = type == "intent" }

data class Milestone(val id: Long, val goalId: Long, val title: String, val done: Boolean, val doneDate: String?)

data class Template(val id: Long, val name: String, val mode: String, val weekdays: Set<Int>, val sort: Int)

data class Block(
    val id: Long, val templateId: Long, val start: Int, val end: Int, val title: String,
    val category: String, val ventureId: Long?, val isProtected: Boolean
) {
    /** Minutes, wrapping past midnight. */
    val duration: Int get() { val d = ((end - start) % 1440 + 1440) % 1440; return if (d == 0) 1440 else d }
    fun contains(minuteOfDay: Int): Boolean = ((minuteOfDay - start + 1440) % 1440) < duration
}

data class Sprint(
    val id: Long, val goal: String, val start: LocalDate, val end: LocalDate, val status: String,
    val recoveryEnd: LocalDate?, val reportSeen: Boolean
)

data class DayPlan(
    val date: LocalDate, val templateId: Long?, val mode: String?, val oneThing: String?, val task2: String?, val task3: String?,
    val oneDone: Boolean, val task2Done: Boolean, val task3Done: Boolean
)

data class HourLog(
    val id: Long, val date: LocalDate, val hour: Int, val minutes: Int, val activity: String, val category: String?,
    val ventureId: Long?, val type: String, val focus: Int?, val energy: Int?, val followedPlan: String?,
    val offPlanReason: String?, val money: Double?, val moneyNote: String?, val source: String, val loggedAt: Long
)

data class FocusSession(
    val id: Long, val date: LocalDate, val start: Long, val end: Long?, val plannedMinutes: Int, val task: String?,
    val interruptions: Int, val completed: Boolean
)

data class Distraction(val id: Long, val ts: Long, val date: LocalDate, val reason: String?)

data class DailyReview(
    val date: LocalDate, val oneThingDone: Boolean, val smallWin: String?, val trivialToCut: String?, val headline: String?,
    val rating: Int?, val tomorrowOneThing: String?
)

data class Habit(val id: Long, val name: String, val trigger: String?, val active: Boolean, val sort: Int, val color: Int = 0)

data class SleepLog(val date: LocalDate, val bedtime: Int, val wake: Int, val quality: Int) {
    /** Hours slept; bedtime is the evening before `date`. */
    val hours: Double get() = (((wake - bedtime) % 1440 + 1440) % 1440) / 60.0
}

data class Opportunity(
    val id: Long, val title: String, val fit: Int, val money: Int, val strengths: Int, val energy: Int, val giveUp: String,
    val total: Int, val decision: String, val created: String, val reviewDate: String?
)

data class NoLog(val id: Long, val date: LocalDate, val what: String, val hoursSaved: Double)
data class Commitment(val id: Long, val name: String, val active: Boolean)
data class UncommitReview(
    val id: Long, val month: String, val item: String, val ventureId: Long?, val wouldStart: String?, val decision: String?,
    val followUpDone: Boolean
)
data class TaskEstimate(val id: Long, val title: String, val date: LocalDate, val est: Int, val actual: Int?)
data class Obstacle(val id: Long, val week: String, val obstacle: String, val action: String?, val resolved: Boolean?)

data class KeywordRule(val id: Long, val keywords: String, val category: String?, val ventureId: Long?, val type: String?) {
    val words: List<String> get() = keywords.split(',').map { it.trim().lowercase() }.filter { it.isNotEmpty() }
}

