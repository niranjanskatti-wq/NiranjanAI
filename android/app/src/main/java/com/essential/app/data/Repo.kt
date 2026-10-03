package com.essential.app.data

import android.content.Context
import android.database.Cursor
import com.essential.app.core.TimeUtil
import java.time.LocalDate

/** All reads/writes go through here. Synchronous: the database is small and local. */
class Repo private constructor(val ctx: Context) {
    companion object {
        @Volatile private var inst: Repo? = null
        fun get(ctx: Context): Repo = inst ?: synchronized(this) { inst ?: Repo(ctx.applicationContext).also { inst = it } }
        internal fun resetForTests() { inst = null }
    }

    val db: Db = Db.get(ctx)
    val settings: Settings get() = Settings.get(ctx)

    // ---------------------------------------------------------------- ventures
    private fun venture(c: Cursor) = Venture(c.lng("id"), c.s("name"), c.int("color"), c.bool("archived"), c.int("sort"))
    fun ventures(includeArchived: Boolean = false): List<Venture> =
        db.query("SELECT * FROM venture ${if (includeArchived) "" else "WHERE archived=0"} ORDER BY archived, sort, id") { venture(it) }
    fun venture(id: Long?): Venture? = id?.let { db.one("SELECT * FROM venture WHERE id=?", it) { c -> venture(c) } }
    fun ventureByName(name: String): Venture? = db.one("SELECT * FROM venture WHERE name=? COLLATE NOCASE", name) { venture(it) }
    fun addVenture(name: String, color: Int): Long =
        db.insert("venture", cv("name" to name, "color" to color, "sort" to (db.scalarL("SELECT MAX(sort) FROM venture") + 1)))
    fun updateVenture(id: Long, name: String, color: Int, archived: Boolean) =
        db.update("venture", cv("name" to name, "color" to color, "archived" to archived), "id=?", id)

    // ---------------------------------------------------------------- goals
    private fun goal(c: Cursor) = Goal(c.lng("id"), c.s("title"), c.s("type"), LocalDate.parse(c.s("start_date")),
        LocalDate.parse(c.s("end_date")), c.int("progress"), c.s("status"))
    fun activeGoals(): List<Goal> = db.query("SELECT * FROM goal WHERE status='active' ORDER BY CASE type WHEN 'intent' THEN 0 ELSE 1 END, id") { goal(it) }
    fun allGoals(): List<Goal> = db.query("SELECT * FROM goal ORDER BY status, id DESC") { goal(it) }
    fun intent(): Goal? = db.one("SELECT * FROM goal WHERE status='active' AND type='intent' ORDER BY id DESC LIMIT 1") { goal(it) }
    fun goal(id: Long): Goal? = db.one("SELECT * FROM goal WHERE id=?", id) { goal(it) }
    fun addGoal(title: String, type: String, start: LocalDate, end: LocalDate): Long =
        db.insert("goal", cv("title" to title, "type" to type, "start_date" to start.toString(), "end_date" to end.toString(), "progress" to 0, "status" to "active"))
    fun updateGoal(g: Goal) = db.update("goal", cv("title" to g.title, "type" to g.type, "start_date" to g.startDate.toString(),
        "end_date" to g.endDate.toString(), "progress" to g.progress, "status" to g.status), "id=?", g.id)
    fun setGoalStatus(id: Long, status: String) = db.update("goal", cv("status" to status), "id=?", id)
    fun setGoalProgress(id: Long, p: Int) = db.update("goal", cv("progress" to p.coerceIn(0, 100)), "id=?", id)

    private fun milestone(c: Cursor) = Milestone(c.lng("id"), c.lng("goal_id"), c.s("title"), c.bool("done"), c.str("done_date"))
    fun milestones(goalId: Long): List<Milestone> = db.query("SELECT * FROM milestone WHERE goal_id=? ORDER BY sort, id", goalId) { milestone(it) }
    fun addMilestone(goalId: Long, title: String) {
        db.insert("milestone", cv("goal_id" to goalId, "title" to title, "sort" to (db.scalarL("SELECT COUNT(*) FROM milestone WHERE goal_id=?", goalId))))
        syncProgress(goalId)
    }
    fun setMilestone(id: Long, done: Boolean, today: LocalDate) {
        val gid = db.scalarL("SELECT goal_id FROM milestone WHERE id=?", id)
        db.update("milestone", cv("done" to done, "done_date" to if (done) today.toString() else null), "id=?", id)
        syncProgress(gid)
    }
    fun deleteMilestone(id: Long) {
        val gid = db.scalarL("SELECT goal_id FROM milestone WHERE id=?", id)
        db.delete("milestone", "id=?", id); syncProgress(gid)
    }
    /** When a goal has milestones, its progress is the share of milestones done. */
    fun syncProgress(goalId: Long) {
        val ms = milestones(goalId)
        if (ms.isNotEmpty()) setGoalProgress(goalId, (ms.count { it.done } * 100) / ms.size)
    }

    // ---------------------------------------------------------------- templates & blocks
    private fun template(c: Cursor) = Template(c.lng("id"), c.s("name"), c.s("mode"),
        c.s("assigned_weekdays").split(',').mapNotNull { it.trim().toIntOrNull() }.toSet(), c.int("sort"))
    fun templates(): List<Template> = db.query("SELECT * FROM template ORDER BY sort, id") { template(it) }
    fun template(id: Long?): Template? = id?.let { db.one("SELECT * FROM template WHERE id=?", it) { c -> template(c) } }
    fun addTemplate(name: String, mode: String, copyFrom: Long?): Long {
        val id = db.insert("template", cv("name" to name, "mode" to mode, "assigned_weekdays" to "", "sort" to (db.scalarL("SELECT MAX(sort) FROM template") + 1)))
        if (copyFrom != null) saveBlocks(id, blocks(copyFrom))
        return id
    }
    fun updateTemplate(t: Template) = db.update("template", cv("name" to t.name, "mode" to t.mode,
        "assigned_weekdays" to t.weekdays.sorted().joinToString(",")), "id=?", t.id)
    /** Assign weekdays, removing them from other templates of the same mode. */
    fun assignWeekdays(t: Template, days: Set<Int>) {
        db.tx {
            templates().filter { it.id != t.id && it.mode == t.mode }.forEach { o ->
                val left = o.weekdays - days
                if (left != o.weekdays) db.update("template", cv("assigned_weekdays" to left.sorted().joinToString(",")), "id=?", o.id)
            }
            db.update("template", cv("assigned_weekdays" to days.sorted().joinToString(",")), "id=?", t.id)
        }
    }
    fun deleteTemplate(id: Long) = db.tx { db.delete("block", "template_id=?", id); db.delete("template", "id=?", id) }

    private fun block(c: Cursor) = Block(c.lng("id"), c.lng("template_id"), c.int("start_time"), c.int("end_time"), c.s("title"),
        c.s("category"), c.lngN("venture_id"), c.bool("is_protected"))
    fun blocks(templateId: Long?): List<Block> {
        if (templateId == null) return emptyList()
        val ds = dayStart()
        return db.query("SELECT * FROM block WHERE template_id=?", templateId) { block(it) }.sortedBy { TimeUtil.offset(it.start, ds) }
    }
    fun saveBlocks(templateId: Long, list: List<Block>) = db.tx {
        db.delete("block", "template_id=?", templateId)
        list.forEach { b ->
            db.insert("block", cv("template_id" to templateId, "start_time" to b.start, "end_time" to b.end, "title" to b.title,
                "category" to b.category, "venture_id" to b.ventureId, "is_protected" to b.isProtected))
        }
    }

    fun dayStart(): Int = TimeUtil.dayStartFrom(settings.int("wake_normal"), settings.int("wake_max"))

    // ---------------------------------------------------------------- sprints
    private fun sprint(c: Cursor) = Sprint(c.lng("id"), c.s("goal"), LocalDate.parse(c.s("start_date")), LocalDate.parse(c.s("end_date")),
        c.s("status"), c.str("recovery_end_date")?.let { LocalDate.parse(it) }, c.bool("report_seen"))
    fun sprints(): List<Sprint> = db.query("SELECT * FROM sprint ORDER BY start_date DESC") { sprint(it) }
    fun sprint(id: Long): Sprint? = db.one("SELECT * FROM sprint WHERE id=?", id) { sprint(it) }
    /** Sprint covering [date] (running or finished; cancelled sprints excluded). */
    fun activeSprint(date: LocalDate): Sprint? = db.one(
        "SELECT * FROM sprint WHERE status IN ('active','done') AND start_date<=? AND end_date>=? ORDER BY id DESC LIMIT 1", date.toString(), date.toString()) { sprint(it) }
    /** Sprint whose recovery week covers [date]. */
    fun recoverySprint(date: LocalDate): Sprint? = db.one(
        "SELECT * FROM sprint WHERE status IN ('done','active') AND end_date<? AND recovery_end_date>=? ORDER BY id DESC LIMIT 1", date.toString(), date.toString()) { sprint(it) }
    fun addSprint(goal: String, start: LocalDate, end: LocalDate): Long =
        db.insert("sprint", cv("goal" to goal, "start_date" to start.toString(), "end_date" to end.toString(), "status" to "active",
            "recovery_end_date" to end.plusDays(7).toString()))
    /** Close sprints whose end date has passed; returns the ones just closed. */
    fun closeFinishedSprints(today: LocalDate): List<Sprint> {
        val due = db.query("SELECT * FROM sprint WHERE status='active' AND end_date<?", today.toString()) { sprint(it) }
        due.forEach { db.update("sprint", cv("status" to "done"), "id=?", it.id) }
        return due
    }
    fun endSprintNow(id: Long, today: LocalDate) = db.update("sprint", cv("status" to "done", "end_date" to today.minusDays(1).toString(),
        "recovery_end_date" to today.plusDays(6).toString()), "id=?", id)
    fun markSprintReportSeen(id: Long) = db.update("sprint", cv("report_seen" to true), "id=?", id)

    // ---------------------------------------------------------------- day plan
    private fun dayPlan(c: Cursor) = DayPlan(LocalDate.parse(c.s("date")), c.lngN("template_id"), c.str("mode"), c.str("one_thing"),
        c.str("task_2"), c.str("task_3"), c.bool("one_done"), c.bool("task_2_done"), c.bool("task_3_done"))
    fun dayPlan(date: LocalDate): DayPlan? = db.one("SELECT * FROM day_plan WHERE date=?", date.toString()) { dayPlan(it) }
    fun dayPlans(from: LocalDate, to: LocalDate): List<DayPlan> =
        db.query("SELECT * FROM day_plan WHERE date>=? AND date<=?", from.toString(), to.toString()) { dayPlan(it) }
    private fun ensurePlan(date: LocalDate) {
        db.exec("INSERT OR IGNORE INTO day_plan(date, updated_at) VALUES(?, ?)", date.toString(), TimeUtil.nowMillis())
    }
    fun setPlanField(date: LocalDate, field: String, value: Any?) {
        ensurePlan(date); db.update("day_plan", cv(field to value), "date=?", date.toString())
    }
    fun setDayTemplate(date: LocalDate, templateId: Long?, mode: String?) {
        ensurePlan(date); db.update("day_plan", cv("template_id" to templateId, "mode" to mode), "date=?", date.toString())
    }

    // ---------------------------------------------------------------- hour logs
    private fun hourLog(c: Cursor) = HourLog(c.lng("id"), LocalDate.parse(c.s("date")), c.int("hour_start"), c.int("minutes"), c.s("activity"),
        c.str("category"), c.lngN("venture_id"), c.s("type"), c.intN("focus"), c.intN("energy"), c.str("followed_plan"),
        c.str("off_plan_reason"), c.dblN("money_amount"), c.str("money_note"), c.s("source"), c.lng("logged_at"))
    fun logs(date: LocalDate): List<HourLog> = db.query("SELECT * FROM hour_log WHERE date=?", date.toString()) { hourLog(it) }
    fun logsRange(from: LocalDate, to: LocalDate): List<HourLog> =
        db.query("SELECT * FROM hour_log WHERE date>=? AND date<=? ORDER BY date, logged_at", from.toString(), to.toString()) { hourLog(it) }
    fun log(id: Long): HourLog? = db.one("SELECT * FROM hour_log WHERE id=?", id) { hourLog(it) }
    fun logFor(date: LocalDate, hour: Int): HourLog? =
        db.one("SELECT * FROM hour_log WHERE date=? AND hour_start=? ORDER BY id DESC LIMIT 1", date.toString(), hour) { hourLog(it) }
    fun lastLogBefore(date: LocalDate, hour: Int): HourLog? {
        val ds = dayStart()
        return logs(date).filter { TimeUtil.offset(it.hour * 60, ds) < TimeUtil.offset(hour * 60, ds) }
            .maxByOrNull { TimeUtil.offset(it.hour * 60, ds) }
            ?: db.one("SELECT * FROM hour_log WHERE date<? ORDER BY date DESC, logged_at DESC LIMIT 1", date.toString()) { hourLog(it) }
    }
    /** One log per (date, hour): saving replaces any existing entry for that hour. */
    fun saveLog(l: HourLog): Long {
        val values = cv("date" to l.date.toString(), "hour_start" to l.hour, "minutes" to l.minutes, "activity" to l.activity,
            "category" to l.category, "venture_id" to l.ventureId, "type" to l.type, "focus" to l.focus, "energy" to l.energy,
            "followed_plan" to l.followedPlan, "off_plan_reason" to l.offPlanReason, "money_amount" to l.money,
            "money_note" to l.moneyNote, "source" to l.source, "logged_at" to l.loggedAt)
        val existing = if (l.id > 0) l.id else logFor(l.date, l.hour)?.id ?: 0
        return if (existing > 0) { db.update("hour_log", values, "id=?", existing); existing } else db.insert("hour_log", values)
    }
    fun deleteLog(id: Long) = db.delete("hour_log", "id=?", id)
    fun recentActivities(limit: Int = 8): List<String> =
        db.query("SELECT activity, MAX(logged_at) m FROM hour_log GROUP BY activity ORDER BY m DESC LIMIT ?", limit) { it.getString(0) }

    // ---------------------------------------------------------------- focus
    private fun focus(c: Cursor) = FocusSession(c.lng("id"), LocalDate.parse(c.s("date")), c.lng("start"), c.lngN("end"),
        c.int("planned_minutes"), c.str("task"), c.int("interruptions"), c.bool("completed"))
    fun focusSession(id: Long): FocusSession? = db.one("SELECT * FROM focus_session WHERE id=?", id) { focus(it) }
    fun focusSessions(from: LocalDate, to: LocalDate): List<FocusSession> =
        db.query("SELECT * FROM focus_session WHERE date>=? AND date<=? ORDER BY start", from.toString(), to.toString()) { focus(it) }
    fun addFocus(date: LocalDate, start: Long, planned: Int, task: String?): Long =
        db.insert("focus_session", cv("date" to date.toString(), "start" to start, "planned_minutes" to planned, "task" to task))
    fun updateFocus(id: Long, end: Long?, interruptions: Int, completed: Boolean) =
        db.update("focus_session", cv("end" to end, "interruptions" to interruptions, "completed" to completed), "id=?", id)

    // ---------------------------------------------------------------- distractions
    private fun distraction(c: Cursor) = Distraction(c.lng("id"), c.lng("timestamp"), LocalDate.parse(c.s("date")), c.str("reason"))
    fun addDistraction(ts: Long, date: LocalDate, reason: String?): Long =
        db.insert("distraction", cv("timestamp" to ts, "date" to date.toString(), "reason" to reason))
    fun setDistractionReason(id: Long, reason: String) = db.update("distraction", cv("reason" to reason), "id=?", id)
    fun distractions(from: LocalDate, to: LocalDate): List<Distraction> =
        db.query("SELECT * FROM distraction WHERE date>=? AND date<=? ORDER BY timestamp", from.toString(), to.toString()) { distraction(it) }

    // ---------------------------------------------------------------- reviews
    private fun review(c: Cursor) = DailyReview(LocalDate.parse(c.s("date")), c.bool("one_thing_done"), c.str("small_win"),
        c.str("trivial_to_cut"), c.str("headline"), c.intN("day_rating"), c.str("tomorrow_one_thing"))
    fun review(date: LocalDate): DailyReview? = db.one("SELECT * FROM daily_review WHERE date=?", date.toString()) { review(it) }
    fun reviews(from: LocalDate, to: LocalDate): List<DailyReview> =
        db.query("SELECT * FROM daily_review WHERE date>=? AND date<=? ORDER BY date", from.toString(), to.toString()) { review(it) }
    fun saveReview(r: DailyReview) {
        db.upsert("daily_review", cv("date" to r.date.toString(), "one_thing_done" to r.oneThingDone, "small_win" to r.smallWin,
            "trivial_to_cut" to r.trivialToCut, "headline" to r.headline, "day_rating" to r.rating, "tomorrow_one_thing" to r.tomorrowOneThing))
        setPlanField(r.date, "one_done", r.oneThingDone)
        if (!r.tomorrowOneThing.isNullOrBlank()) setPlanField(r.date.plusDays(1), "one_thing", r.tomorrowOneThing)
    }

    // ---------------------------------------------------------------- habits
    private fun habit(c: Cursor) = Habit(c.lng("id"), c.s("name"), c.str("trigger"), c.bool("active"), c.int("sort"),
        c.int("color").takeIf { it != 0 } ?: Seed.HABIT_COLORS[(c.lng("id") % Seed.HABIT_COLORS.size).toInt()],
        c.str("unit")?.takeIf { it.isNotBlank() }, c.dblN("target"), c.bool("target_for_chain"), c.bool("show_totals"))
    fun habit(id: Long): Habit? = db.one("SELECT * FROM habit WHERE id=?", id) { habit(it) }
    fun habits(activeOnly: Boolean = true): List<Habit> =
        db.query("SELECT * FROM habit ${if (activeOnly) "WHERE active=1" else ""} ORDER BY sort, id") { habit(it) }
    fun addHabit(name: String, trigger: String?, color: Int = Seed.HABIT_COLORS[(db.scalarL("SELECT COUNT(*) FROM habit") % Seed.HABIT_COLORS.size).toInt()],
                 unit: String? = null, target: Double? = null, targetForChain: Boolean = false, showTotals: Boolean = true): Long =
        db.insert("habit", cv("name" to name, "trigger" to trigger, "color" to color, "sort" to (db.scalarL("SELECT MAX(sort) FROM habit") + 1),
            "unit" to unit, "target" to target, "target_for_chain" to targetForChain, "show_totals" to showTotals))
    fun updateHabit(h: Habit) = db.update("habit", cv("name" to h.name, "trigger" to h.trigger, "active" to h.active, "color" to h.color,
        "unit" to h.unit, "target" to h.target, "target_for_chain" to h.targetForChain, "show_totals" to h.showTotals), "id=?", h.id)
    fun moveHabit(h: Habit, up: Boolean) {
        val list = habits(false).toMutableList()
        val i = list.indexOfFirst { it.id == h.id }; val j = if (up) i - 1 else i + 1
        if (i < 0 || j !in list.indices) return
        java.util.Collections.swap(list, i, j)
        db.tx { list.forEachIndexed { k, x -> db.update("habit", cv("sort" to k), "id=?", x.id) } }
    }
    fun deleteHabit(id: Long) = db.tx { db.delete("alarm", "habit_id=?", id); db.delete("habit_entry", "habit_id=?", id); db.delete("habit_log", "habit_id=?", id); db.delete("habit", "id=?", id) }

    // ---------------------------------------------------------------- alarms
    private fun alarm(c: Cursor) = UserAlarm(c.lng("id"), c.s("label"), c.int("minute"), c.int("days"), c.bool("enabled"), c.lngN("habit_id"),
        c.str("style") ?: UserAlarm.STYLE_ALARM, c.int("snooze_min").takeIf { it > 0 } ?: 10, c.bool("vibrate"), c.str("once_date"))
    fun alarms(): List<UserAlarm> = db.query("SELECT * FROM alarm ORDER BY minute, id") { alarm(it) }
    fun alarmsFor(habitId: Long): List<UserAlarm> = db.query("SELECT * FROM alarm WHERE habit_id=? ORDER BY minute, id", habitId) { alarm(it) }
    fun alarm(id: Long): UserAlarm? = db.one("SELECT * FROM alarm WHERE id=?", id) { alarm(it) }
    private fun alarmCv(x: UserAlarm) = cv("label" to x.label, "minute" to x.minute, "days" to x.days, "enabled" to x.enabled, "habit_id" to x.habitId,
        "style" to x.style, "snooze_min" to x.snoozeMin, "vibrate" to x.vibrate, "once_date" to x.onceDate, "updated_at" to TimeUtil.nowMillis())
    /** Insert when id is 0, otherwise update. Returns the id. */
    fun saveAlarm(x: UserAlarm): Long = if (x.id == 0L) db.insert("alarm", alarmCv(x)) else { db.update("alarm", alarmCv(x), "id=?", x.id); x.id }
    fun setAlarmEnabled(id: Long, on: Boolean) = db.update("alarm", cv("enabled" to on, "updated_at" to TimeUtil.nowMillis()), "id=?", id)
    fun deleteAlarm(id: Long) = db.delete("alarm", "id=?", id)

    // ---------------------------------------------------------------- habit amounts & books
    private fun entry(c: Cursor) = HabitEntry(c.lng("id"), c.lng("habit_id"), LocalDate.parse(c.s("date")), c.dbl("amount"), c.lngN("book_id"), c.str("note"))
    fun entries(habitId: Long, from: LocalDate, to: LocalDate): List<HabitEntry> =
        db.query("SELECT * FROM habit_entry WHERE habit_id=? AND date>=? AND date<=? ORDER BY date DESC, id DESC", habitId, from.toString(), to.toString()) { entry(it) }
    fun recentEntries(habitId: Long, limit: Int = 30): List<HabitEntry> =
        db.query("SELECT * FROM habit_entry WHERE habit_id=? ORDER BY date DESC, id DESC LIMIT ?", habitId, limit) { entry(it) }
    fun amount(habitId: Long, from: LocalDate, to: LocalDate): Double =
        db.scalarD("SELECT SUM(amount) FROM habit_entry WHERE habit_id=? AND date>=? AND date<=?", habitId, from.toString(), to.toString())
    fun amountAllTime(habitId: Long): Double = db.scalarD("SELECT SUM(amount) FROM habit_entry WHERE habit_id=?", habitId)
    fun amountsByDate(habitId: Long, from: LocalDate, to: LocalDate): Map<LocalDate, Double> =
        db.query("SELECT date, SUM(amount) FROM habit_entry WHERE habit_id=? AND date>=? AND date<=? GROUP BY date", habitId, from.toString(), to.toString()) {
            LocalDate.parse(it.getString(0)) to it.getDouble(1) }.toMap()
    fun daysWithAmount(habitId: Long): Long = db.scalarL("SELECT COUNT(DISTINCT date) FROM habit_entry WHERE habit_id=?", habitId)

    /** Log an amount; reading pages also move the book forward. The day counts as done when the habit's rule is met. */
    fun logAmount(h: Habit, date: LocalDate, amount: Double, bookId: Long? = null, note: String? = null): Long {
        var id = 0L
        db.tx {
            id = db.insert("habit_entry", cv("habit_id" to h.id, "date" to date.toString(), "amount" to amount, "book_id" to bookId,
                "note" to note, "created" to TimeUtil.nowMillis()))
            if (bookId != null) movePages(bookId, amount.toInt())
            refreshDone(h, date)
        }
        return id
    }

    fun deleteEntry(h: Habit, e: HabitEntry) = db.tx {
        db.delete("habit_entry", "id=?", e.id)
        if (e.bookId != null) movePages(e.bookId, -e.amount.toInt())
        refreshDone(h, e.date)
    }

    /** Measured habits: done when the day's amount reaches the target (if "target needed for chain") or is above zero. */
    fun refreshDone(h: Habit, date: LocalDate) {
        if (!h.measured) return
        val sum = amount(h.id, date, date)
        val t = h.target
        val met = if (h.targetForChain && t != null && t > 0) sum >= t else sum > 0
        if (met) setHabit(h.id, date, true)
        else if (sum <= 0 || h.targetForChain) setHabit(h.id, date, false)
    }

    private fun book(c: Cursor) = Book(c.lng("id"), c.s("title"), c.str("author"), c.int("total_pages"), c.int("current_page"), c.str("started"), c.str("finished"))
    fun books(includeFinished: Boolean = true): List<Book> =
        db.query("SELECT * FROM book ${if (includeFinished) "" else "WHERE finished IS NULL"} ORDER BY (finished IS NOT NULL), sort, id") { book(it) }
    fun book(id: Long?): Book? = id?.let { db.one("SELECT * FROM book WHERE id=?", it) { c -> book(c) } }
    fun addBook(title: String, author: String?, total: Int, current: Int = 0): Long =
        db.insert("book", cv("title" to title, "author" to author, "total_pages" to total, "current_page" to current.coerceIn(0, maxOf(total, current)),
            "started" to TimeUtil.now().toLocalDate().toString(), "sort" to (db.scalarL("SELECT MAX(sort) FROM book") + 1)))
    fun updateBook(b: Book) = db.update("book", cv("title" to b.title, "author" to b.author, "total_pages" to b.totalPages,
        "current_page" to b.currentPage, "finished" to b.finished), "id=?", b.id)
    fun deleteBook(id: Long) = db.tx { db.exec("UPDATE habit_entry SET book_id=NULL WHERE book_id=?", id); db.delete("book", "id=?", id) }
    fun pagesReadFromBook(bookId: Long): Double = db.scalarD("SELECT SUM(amount) FROM habit_entry WHERE book_id=?", bookId)

    private fun movePages(bookId: Long, delta: Int) {
        val b = book(bookId) ?: return
        val cur = (b.currentPage + delta).coerceAtLeast(0).let { if (b.totalPages > 0) minOf(it, b.totalPages) else it }
        val finished = if (b.totalPages in 1..cur) (b.finished ?: TimeUtil.now().toLocalDate().toString()) else null
        db.update("book", cv("current_page" to cur, "finished" to finished), "id=?", bookId)
    }
    fun habitDone(date: LocalDate): Set<Long> =
        db.query("SELECT habit_id FROM habit_log WHERE date=? AND done=1", date.toString()) { it.getLong(0) }.toSet()
    fun setHabit(habitId: Long, date: LocalDate, done: Boolean) {
        if (done) db.upsert("habit_log", cv("habit_id" to habitId, "date" to date.toString(), "done" to 1))
        else db.delete("habit_log", "habit_id=? AND date=?", habitId, date.toString())
    }
    fun habitDates(habitId: Long): List<LocalDate> =
        db.query("SELECT date FROM habit_log WHERE habit_id=? AND done=1 ORDER BY date", habitId) { LocalDate.parse(it.getString(0)) }
    fun habitLogCount(from: LocalDate, to: LocalDate): Long =
        db.scalarL("SELECT COUNT(*) FROM habit_log WHERE date>=? AND date<=? AND done=1", from.toString(), to.toString())

    // ---------------------------------------------------------------- sleep
    private fun sleep(c: Cursor) = SleepLog(LocalDate.parse(c.s("date")), c.int("bedtime"), c.int("wake_time"), c.int("quality"))
    fun sleepLog(date: LocalDate): SleepLog? = db.one("SELECT * FROM sleep_log WHERE date=?", date.toString()) { sleep(it) }
    fun sleepLogs(from: LocalDate, to: LocalDate): List<SleepLog> =
        db.query("SELECT * FROM sleep_log WHERE date>=? AND date<=? ORDER BY date", from.toString(), to.toString()) { sleep(it) }
    fun saveSleep(s: SleepLog) = db.upsert("sleep_log", cv("date" to s.date.toString(), "bedtime" to s.bedtime, "wake_time" to s.wake, "quality" to s.quality))

    // ---------------------------------------------------------------- opportunities
    private fun opp(c: Cursor) = Opportunity(c.lng("id"), c.s("title"), c.int("score_fit"), c.int("score_money"), c.int("score_strengths"),
        c.int("score_energy"), c.s("give_up_answer"), c.int("total_score"), c.s("decision"), c.s("created"), c.str("review_date"))
    fun opportunities(): List<Opportunity> = db.query("SELECT * FROM opportunity ORDER BY created DESC, id DESC") { opp(it) }
    fun addOpportunity(o: Opportunity): Long = db.insert("opportunity", cv("title" to o.title, "score_fit" to o.fit, "score_money" to o.money,
        "score_strengths" to o.strengths, "score_energy" to o.energy, "give_up_answer" to o.giveUp, "total_score" to o.total,
        "decision" to o.decision, "created" to o.created, "review_date" to o.reviewDate))
    fun setOpportunityDecision(id: Long, decision: String, reviewDate: String?) =
        db.update("opportunity", cv("decision" to decision, "review_date" to reviewDate), "id=?", id)
    fun deleteOpportunity(id: Long) = db.delete("opportunity", "id=?", id)

    // ---------------------------------------------------------------- no log
    fun noLogs(): List<NoLog> = db.query("SELECT * FROM no_log ORDER BY date DESC, id DESC") { NoLog(it.lng("id"), LocalDate.parse(it.s("date")), it.s("what"), it.dbl("hours_saved")) }
    fun addNo(date: LocalDate, what: String, hours: Double): Long = db.insert("no_log", cv("date" to date.toString(), "what" to what, "hours_saved" to hours))
    fun deleteNo(id: Long) = db.delete("no_log", "id=?", id)
    fun hoursSaved(from: LocalDate, to: LocalDate): Double =
        db.scalarD("SELECT SUM(hours_saved) FROM no_log WHERE date>=? AND date<=?", from.toString(), to.toString())

    // ---------------------------------------------------------------- commitments & uncommit
    fun commitments(): List<Commitment> = db.query("SELECT * FROM commitment ORDER BY active DESC, id") { Commitment(it.lng("id"), it.s("name"), it.bool("active")) }
    fun addCommitment(name: String) = db.insert("commitment", cv("name" to name))
    fun setCommitmentActive(id: Long, active: Boolean) = db.update("commitment", cv("active" to active), "id=?", id)
    private fun uncommit(c: Cursor) = UncommitReview(c.lng("id"), c.s("month"), c.s("item"), c.lngN("venture_id"), c.str("would_start"),
        c.str("decision"), c.bool("follow_up_done"))
    fun uncommitReviews(month: String): List<UncommitReview> = db.query("SELECT * FROM uncommit_review WHERE month=? ORDER BY id", month) { uncommit(it) }
    fun pendingFollowUps(): List<UncommitReview> = db.query(
        "SELECT * FROM uncommit_review WHERE decision IN ('Reduce','Stop','Test-stop') AND follow_up_done=0 ORDER BY month DESC") { uncommit(it) }
    fun saveUncommit(month: String, item: String, ventureId: Long?, wouldStart: String?, decision: String?) {
        val existing = db.scalarL("SELECT id FROM uncommit_review WHERE month=? AND item=?", month, item)
        val values = cv("month" to month, "item" to item, "venture_id" to ventureId, "would_start" to wouldStart, "decision" to decision)
        if (existing > 0) db.update("uncommit_review", values, "id=?", existing) else db.insert("uncommit_review", values)
    }
    fun setFollowUp(id: Long, done: Boolean) = db.update("uncommit_review", cv("follow_up_done" to done), "id=?", id)

    // ---------------------------------------------------------------- task estimates
    private fun task(c: Cursor) = TaskEstimate(c.lng("id"), c.s("title"), LocalDate.parse(c.s("date")), c.int("estimated_minutes"), c.intN("actual_minutes"))
    fun tasks(): List<TaskEstimate> = db.query("SELECT * FROM task_estimate ORDER BY (actual_minutes IS NOT NULL), date DESC, id DESC") { task(it) }
    fun addTask(title: String, date: LocalDate, est: Int): Long = db.insert("task_estimate", cv("title" to title, "date" to date.toString(), "estimated_minutes" to est))
    fun setTaskActual(id: Long, actual: Int?) = db.update("task_estimate", cv("actual_minutes" to actual), "id=?", id)
    fun deleteTask(id: Long) = db.delete("task_estimate", "id=?", id)

    // ---------------------------------------------------------------- obstacles
    private fun obstacle(c: Cursor) = Obstacle(c.lng("id"), c.s("week"), c.s("obstacle"), c.str("action"), c.intN("resolved")?.let { it != 0 })
    fun obstacle(week: LocalDate): Obstacle? = db.one("SELECT * FROM obstacle WHERE week=? ORDER BY id DESC LIMIT 1", week.toString()) { obstacle(it) }
    fun obstacles(): List<Obstacle> = db.query("SELECT * FROM obstacle ORDER BY week DESC") { obstacle(it) }
    fun saveObstacle(week: LocalDate, text: String, action: String?) {
        val ex = obstacle(week)
        if (ex != null) db.update("obstacle", cv("obstacle" to text, "action" to action), "id=?", ex.id)
        else db.insert("obstacle", cv("week" to week.toString(), "obstacle" to text, "action" to action))
    }
    fun setObstacleResolved(id: Long, resolved: Boolean) = db.update("obstacle", cv("resolved" to resolved), "id=?", id)

    // ---------------------------------------------------------------- keyword rules
    fun rules(): List<KeywordRule> = db.query("SELECT * FROM keyword_rule ORDER BY id") {
        KeywordRule(it.lng("id"), it.s("keywords"), it.str("category"), it.lngN("venture_id"), it.str("type"))
    }
    fun saveRule(r: KeywordRule) {
        val values = cv("keywords" to r.keywords, "category" to r.category, "venture_id" to r.ventureId, "type" to r.type)
        if (r.id > 0) db.update("keyword_rule", values, "id=?", r.id) else db.insert("keyword_rule", values)
    }
    fun deleteRule(id: Long) = db.delete("keyword_rule", "id=?", id)

    // ---------------------------------------------------------------- sample data
    fun hasSampleData(): Boolean = db.scalarL("SELECT COUNT(*) FROM hour_log WHERE is_sample=1") > 0
    fun clearSampleData() = db.tx {
        Db.TABLES.filter { it != "settings" }.forEach { t ->
            val hasCol = db.query("PRAGMA table_info($t)") { it.getString(1) }.contains("is_sample")
            if (hasCol) db.delete(t, "is_sample=1")
        }
        settings.set("sample_loaded", false)
    }
}
