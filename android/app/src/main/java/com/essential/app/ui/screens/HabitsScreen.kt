package com.essential.app.ui.screens

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import com.essential.app.core.Hooks
import com.essential.app.core.TimeUtil
import com.essential.app.data.Habit
import com.essential.app.data.HabitUnit
import com.essential.app.data.Seed
import com.essential.app.ui.*
import java.time.LocalDate
import java.time.YearMonth
import kotlin.math.abs
import kotlin.math.roundToInt

/** Chain maths for a habit: done dates → current and best unbroken runs. */
object Chains {
    /** Current chain counts back from today (or yesterday, so an unticked today doesn't break it yet). */
    fun current(done: Set<LocalDate>, today: LocalDate): Int {
        var d = if (today in done) today else today.minusDays(1)
        var n = 0
        while (d in done) { n++; d = d.minusDays(1) }
        return n
    }

    fun best(done: Set<LocalDate>): Int {
        var best = 0; var run = 0; var prev: LocalDate? = null
        for (x in done.sorted()) { run = if (prev != null && prev.plusDays(1) == x) run + 1 else 1; best = maxOf(best, run); prev = x }
        return best
    }
}

/** The Habits tab: every habit, ticked daily, each with its chain of dots. Fully customisable. */
class HabitsScreen(a: MainActivity, private val pushed: Boolean = false) : Screen(a) {
    override val title: String? get() = if (pushed) "Habits" else null
    override fun actions() = listOf(a.iconBtn("plus", Th.text, desc = "Add habit") { HabitEditor.open(a, null) })

    override fun content(): View = page {
        if (!pushed) {
            val h = a.hbox()
            h.add(a.h1("Habits"), 0, WRAP, 1f)
            if (repo.habits(false).any { it.usesBooks }) h.add(a.btn("Books", Btn.TEXT) { a.push(BooksScreen(a)) }, WRAP, WRAP)
            h.add(a.iconBtn("plus", Th.text, desc = "Add habit") { HabitEditor.open(a, null) }, WRAP, WRAP)
            add(h, top = 8, bottom = 2)
        }
        val habits = repo.habits(false)
        val active = habits.filter { it.active }
        val doneToday = repo.habitDone(today)
        add(a.dimText("${TimeUtil.fmtDayLong(today)} · ${active.count { it.id in doneToday }} of ${active.size} done"), bottom = 14)

        if (active.isEmpty()) {
            val c = a.card(18)
            c.add(a.h3("Start a chain"))
            c.add(a.dimText("Add the habits you want to do every day. Tap a suggestion or write your own."), top = 4, bottom = 10)
            val f = Flow(a)
            Seed.HABIT_IDEAS.forEach { idea -> f.addView(a.chip("+ $idea", false) {
                val (u, t) = Seed.IDEA_UNITS[idea] ?: (null to null)
                repo.addHabit(idea, null, unit = u, target = t); Hooks.afterChange(a); a.refresh()
            }) }
            c.add(f)
            add(c, bottom = 12)
        }

        active.forEach { h ->
            val dates = repo.habitDates(h.id).toSet()
            val cur = Chains.current(dates, today); val best = Chains.best(dates)
            val c = a.card(16) { a.push(HabitDetailScreen(a, h.id)) }
            val r = a.hbox()
            val col = a.vbox()
            col.add(a.txt(h.name, 17f, Th.text, Fonts.semibold, maxLines = 1))
            col.add(a.txt(when {
                cur > 0 -> "$cur-day chain · best $best"
                best > 0 -> "Fresh start · best $best"
                else -> "Tick today to start the chain"
            }, 13f, Th.dim), top = 2)
            r.add(col, 0, WRAP, 1f)
            r.add(TodayToggle.make(a, h.id in doneToday, h.color) { on -> repo.setHabit(h.id, today, on); Hooks.afterChange(a); a.refresh() }, a.dp(48), a.dp(48), start = 8)
            c.add(r)
            c.add(ChainStrip(a, today, dates, h.color, 14), MATCH, a.dp(26), top = 12)
            if (h.measured) c.add(amountRow(h), top = 10)
            add(c, bottom = 10)
        }

        val paused = habits.filter { !it.active }
        if (paused.isNotEmpty()) {
            add(a.label("Paused"), top = 8, bottom = 6)
            val c = a.card(6)
            paused.forEach { h -> c.add(a.listRow(h.name, "Tap to resume or edit", "dot", h.color) { HabitEditor.open(a, h) }) }
            add(c)
        }
        if (active.isNotEmpty()) add(a.btn("Add habit", Btn.TONAL, "plus") { HabitEditor.open(a, null) }, top = 6)
    }

    /** Today's amount vs target, the current book for reading, and a quick Log button. */
    private fun amountRow(h: Habit): View {
        val box = a.vbox()
        val got = repo.amount(h.id, today, today)
        val r = a.hbox()
        val col = a.vbox()
        col.add(a.txt("Today " + HabitUnit.fmt(h.unit, got) + (h.target?.let { " / ${HabitUnit.fmt(h.unit, it)}" } ?: ""), 14f, Th.text, Fonts.medium))
        if (h.usesBooks) {
            val b = repo.books(false).firstOrNull()
            col.add(a.txt(b?.let { "${it.title} · ${it.left} pages left" } ?: "Tap Log to add your book", 12.5f, Th.dim, maxLines = 1), top = 2)
        }
        r.add(col, 0, WRAP, 1f)
        r.add(a.btn("+ Log", Btn.TONAL, color = h.color) { AmountSheet.open(a, h) }.apply { minHeight = a.dp(40); setPadding(a.dp(16), a.dp(6), a.dp(16), a.dp(6)) }, WRAP, WRAP)
        box.add(r)
        h.target?.takeIf { it > 0 }?.let { box.addProgress((got / it).coerceIn(0.0, 1.0), h.color, 5, top = 8) }
        return box
    }
}

/** One habit: stats and a month calendar where done days join into a continuous chain. */
class HabitDetailScreen(a: MainActivity, private val habitId: Long) : Screen(a) {
    private var month: YearMonth? = null
    override val title: String? get() = repo.habit(habitId)?.name ?: "Habit"
    override fun actions() = listOf(a.iconBtn("edit", Th.text, desc = "Edit habit") { repo.habit(habitId)?.let { HabitEditor.open(a, it, fromDetail = true) } })

    @SuppressLint("ClickableViewAccessibility")
    override fun content(): View = page {
        val h = repo.habit(habitId) ?: return@page
        val m = month ?: YearMonth.from(today)
        val dates = repo.habitDates(h.id).toSet()
        h.trigger?.takeIf { it.isNotBlank() }?.let { add(a.dimText("Trigger: $it"), bottom = 10) }

        val stats = a.card(16)
        val sr = a.hbox()
        fun stat(v: String, l: String, color: Int = Th.text) { val c = a.vbox(); c.add(a.txt(v, 24f, color, Fonts.semibold)); c.add(a.txt(l, 12f, Th.dim)); sr.add(c, 0, WRAP, 1f) }
        stat("${Chains.current(dates, today)}", "Current chain", h.color)
        stat("${Chains.best(dates)}", "Best chain")
        stat("${dates.size}", "Days done")
        val days = if (m == YearMonth.from(today)) today.dayOfMonth else m.lengthOfMonth()
        val inMonth = dates.count { YearMonth.from(it) == m && !it.isAfter(today) }
        stat(if (days > 0 && !m.atDay(1).isAfter(today)) "${(inMonth * 100.0 / days).roundToInt()}%" else "–", "This month")
        stats.add(sr)
        add(stats, bottom = 14)

        if (h.measured) {
            val lr = a.hbox()
            lr.add(a.btn(if (h.unit == HabitUnit.COUNT) "Log" else "Log ${h.unit}", color = h.color, icon = "plus") { AmountSheet.open(a, h) }, 0, WRAP, 1f)
            if (h.usesBooks) lr.add(a.btn("Books", Btn.TONAL, color = h.color) { a.push(BooksScreen(a)) }, WRAP, WRAP, start = 8)
            add(lr, bottom = 12)
            if (h.usesBooks) repo.books(false).take(3).forEach { b ->
                val c = a.card(14) { a.push(BooksScreen(a)) }
                c.add(a.txt(b.title, 15f, Th.text, Fonts.medium, maxLines = 1))
                c.addProgress(b.fraction.coerceIn(0.0, 1.0), h.color, 6, top = 8)
                c.add(a.dimText("Page ${b.currentPage} of ${b.totalPages} · ${b.left} pages left"), top = 6)
                add(c, bottom = 8)
            }
            if (h.showTotals) add(HabitTotals.card(a, h, today), top = 4, bottom = 14)
        }

        val nav = a.hbox()
        nav.add(a.iconBtn("left", Th.text, desc = "Previous month") { month = m.minusMonths(1); a.refresh() }, a.dp(48), a.dp(48))
        nav.add(a.txt(TimeUtil.fmtMonth(m.atDay(1)), 17f, Th.text, Fonts.semibold, center = true), 0, WRAP, 1f)
        val canNext = m.isBefore(YearMonth.from(today))
        nav.add(a.iconBtn("right", if (canNext) Th.text else Th.faint, desc = "Next month") { if (canNext) { month = m.plusMonths(1); a.refresh() } }, a.dp(48), a.dp(48))
        add(nav, bottom = 4)
        val cal = HabitCalendar(a, m, dates, today, h.color) { d ->
            repo.setHabit(h.id, d, d !in dates); Hooks.afterChange(a); a.root.haptic(); a.refresh()
        }
        val gd = GestureDetector(a, object : GestureDetector.SimpleOnGestureListener() {
            override fun onFling(e1: MotionEvent?, e2: MotionEvent, vx: Float, vy: Float): Boolean {
                if (e1 == null) return false
                val dx = e2.x - e1.x
                if (abs(dx) > a.dp(80) && abs(dx) > abs(e2.y - e1.y) * 1.5f) {
                    if (dx > 0) { month = m.minusMonths(1); a.refresh(); return true }
                    if (canNext) { month = m.plusMonths(1); a.refresh(); return true }
                }
                return false
            }
        })
        cal.setOnTouchListener { v, e -> if (gd.onTouchEvent(e)) true else (v as HabitCalendar).handleTouch(e) }
        add(cal, MATCH, WRAP, bottom = 10)
        add(a.legend("Done" to h.color, "Not done" to Th.surface3), bottom = 6)
        add(a.dimText("Tap any day to mark it done or not done. Unbroken days join into one chain."), bottom = 16)
        add(a.btn(if (today in dates) "Done today ✓" else "Mark today done", if (today in dates) Btn.TONAL else Btn.FILLED, color = h.color) {
            repo.setHabit(h.id, today, today !in dates); Hooks.afterChange(a); a.refresh()
        })
        if (h.measured) {
            val entries = repo.recentEntries(h.id, 20)
            if (entries.isNotEmpty()) {
                add(a.label("Recent logs"), top = 18, bottom = 6)
                val c = a.card(6)
                entries.forEach { e ->
                    val book = e.bookId?.let { repo.book(it)?.title }
                    c.add(a.listRow("${TimeUtil.fmtDay(e.date)} · ${HabitUnit.fmt(h.unit, e.amount)}", listOfNotNull(book, e.note).joinToString(" · ").ifBlank { null },
                        trailing = a.iconBtn("trash", Th.faint, 40, "Delete log") {
                            a.confirm("Delete this log?", "${HabitUnit.fmt(h.unit, e.amount)} on ${TimeUtil.fmtDay(e.date)}", "Delete", danger = true) {
                                repo.deleteEntry(h, e); Hooks.afterChange(a); a.refresh()
                            }
                        }))
                }
                add(c)
            }
        }
    }
}

/** Add / edit a habit: name, trigger, colour, pause, reorder, delete. */
object HabitEditor {
    fun open(a: MainActivity, h: Habit?, fromDetail: Boolean = false) {
        val repo = a.repo
        var color = h?.color ?: Seed.HABIT_COLORS[repo.habits(false).size % Seed.HABIT_COLORS.size]
        var active = h?.active ?: true
        val sh = Sheet(a, if (h == null) "New habit" else "Edit habit")
        val name = a.field("Habit, e.g. Walking", h?.name)
        var unitPreset: ((String?, Double?) -> kotlin.Unit)? = null
        sh.add(name)
        if (h == null) {
            val ideas = Flow(a)
            val existing = repo.habits(false).map { it.name.lowercase() }.toSet()
            Seed.HABIT_IDEAS.filter { it.lowercase() !in existing }.forEach { idea -> ideas.addView(a.chip(idea, false) {
                name.setText(idea); name.setSelection(idea.length)
                Seed.IDEA_UNITS[idea]?.let { (u, t) -> unitPreset?.invoke(u, t) }
            }) }
            sh.add(ideas)
        }
        val trigger = a.field("Trigger or time (optional), e.g. At night", h?.trigger)
        sh.add(trigger)

        // What to count (optional)
        val modes = listOf("Done only" to null, "Minutes" to HabitUnit.MINUTES, "Pages (books)" to HabitUnit.PAGES, "Count" to HabitUnit.COUNT, "Own unit" to "")
        var unit: String? = h?.unit
        var targetForChain = h?.targetForChain ?: false
        var showTotals = h?.showTotals ?: true
        val customUnit = a.field("Unit, e.g. rounds, km, glasses", unit?.takeIf { it !in listOf(HabitUnit.MINUTES, HabitUnit.PAGES, HabitUnit.COUNT) })
        val target = a.field("Daily target (optional), e.g. 30", h?.target?.let { if (it == Math.floor(it)) it.toLong().toString() else it.toString() }, numeric = true, decimal = true)
        val track = a.vbox()
        fun modeOf(u: String?) = when (u) { null -> "Done only"; HabitUnit.MINUTES -> "Minutes"; HabitUnit.PAGES -> "Pages (books)"; HabitUnit.COUNT -> "Count"; else -> "Own unit" }
        fun renderTrack() {
            track.removeAllViews()
            track.add(a.label("What to count · optional"), bottom = 6)
            track.add(a.choice(modes.map { it.first }, modeOf(unit)) { m ->
                unit = when (m) { "Done only" -> null; "Own unit" -> customUnit.value.ifBlank { "" }; else -> modes.first { it.first == m }.second }
                renderTrack()
            }, bottom = 8)
            if (unit != null) {
                if (modeOf(unit) == "Own unit") track.add(customUnit, bottom = 8)
                track.add(target, bottom = 4)
                if (unit == HabitUnit.PAGES) track.add(a.dimText("Add your books (title + total pages) and each log moves the book forward, showing pages left."), top = 2, bottom = 4)
                track.add(a.switchRow("Chain needs the daily target", "Off: any amount counts as done for the day.", targetForChain) { targetForChain = it })
                track.add(a.switchRow("Show totals", "Today, this week, month, year and all-time totals, plus a monthly chart.", showTotals) { showTotals = it })
            }
        }
        renderTrack()
        unitPreset = { u, t -> unit = u; if (t != null) target.setText(if (t == Math.floor(t)) t.toLong().toString() else t.toString()); renderTrack() }
        sh.add(track)
        sh.add(a.label("Colour"), bottom = 6)
        val row = Flow(a)
        fun render() {
            row.removeAllViews()
            Seed.HABIT_COLORS.forEach { col ->
                row.addView(View(a).apply {
                    background = rounded(col, a.dp(18).toFloat(), if (col == color) a.dp(3) else 0, Th.text)
                    minimumWidth = a.dp(36); minimumHeight = a.dp(36)
                    contentDescription = "Colour"
                    click(true) { color = col; render() }
                })
            }
        }
        render()
        sh.add(row)
        if (h != null) {
            sh.add(a.switchRow("Active", "Paused habits keep their history but leave the daily list.", active) { active = it })
            val mv = a.hbox()
            mv.add(a.btn("Move up", Btn.TEXT, "up") { repo.moveHabit(h, true); sh.dismiss(); a.refresh() }, WRAP, WRAP)
            mv.add(a.btn("Move down", Btn.TEXT, "down") { repo.moveHabit(h, false); sh.dismiss(); a.refresh() }, WRAP, WRAP)
            sh.add(mv)
            sh.add(a.btn("Delete habit", Btn.TEXT, color = Th.red) {
                a.confirm("Delete \"${h.name}\"?", "Its whole chain history is removed too.", "Delete", danger = true) {
                    repo.deleteHabit(h.id); sh.dismiss(); Hooks.afterChange(a)
                    if (fromDetail) a.back() else a.refresh()
                }
            })
        }
        sh.actions("Save") {
            if (name.value.isBlank()) { a.toast("Give the habit a name"); return@actions }
            val u = if (unit != null && modeOf(unit) == "Own unit") customUnit.value.ifBlank { null } else unit
            val t = if (u == null) null else target.value.toDoubleOrNull()?.takeIf { it > 0 }
            if (h == null) repo.addHabit(name.value, trigger.value.ifBlank { null }, color, u, t, targetForChain, showTotals)
            else repo.updateHabit(h.copy(name = name.value, trigger = trigger.value.ifBlank { null }, active = active, color = color,
                unit = u, target = t, targetForChain = targetForChain, showTotals = showTotals))
            sh.dismiss(); Hooks.afterChange(a); a.refresh()
        }
        sh.show()
        if (h == null) name.requestFocus()
    }
}

/** Big round tick for today. */
object TodayToggle {
    fun make(a: MainActivity, done: Boolean, color: Int, onToggle: (Boolean) -> Unit): View {
        val v = android.widget.FrameLayout(a)
        val r = a.dp(24).toFloat()
        v.background = ripple(if (done) rounded(color, r) else rounded(0, r, a.dp(2), Th.alpha(color, 0.7f)), r)
        if (done) v.add(a.iconView("check", Th.bg, 24), MATCH, MATCH)
        v.contentDescription = if (done) "Done today" else "Mark done today"
        v.click(true) { onToggle(!done) }
        return v
    }
}

/** Last N days as dots; consecutive done days are joined by a bar. Empty rings for missed days. */
class ChainStrip(ctx: Context, private val today: LocalDate, private val done: Set<LocalDate>, private val color: Int, private val n: Int) : View(ctx) {
    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    override fun onDraw(c: Canvas) {
        val slot = width / n.toFloat()
        val r = minOf(slot * 0.32f, height * 0.4f)
        val cy = height / 2f
        val days = (n - 1 downTo 0).map { today.minusDays(it.toLong()) }
        p.style = Paint.Style.FILL; p.color = color
        for (i in 1 until n) if (days[i] in done && days[i - 1] in done)
            c.drawRect(slot * (i - 0.5f), cy - r * 0.55f, slot * (i + 0.5f), cy + r * 0.55f, p)
        days.forEachIndexed { i, d ->
            val cx = slot * (i + 0.5f)
            if (d in done) { p.style = Paint.Style.FILL; p.color = color; c.drawCircle(cx, cy, r, p) }
            else {
                p.style = Paint.Style.STROKE; p.strokeWidth = dp(1.5f).toFloat()
                p.color = if (d == today) Th.alpha(color, 0.8f) else Th.surface3
                c.drawCircle(cx, cy, r - p.strokeWidth / 2, p)
            }
        }
    }
}

/** Month calendar (Mon–Sun). Done days are filled dots linked into a continuous chain, missed days are empty rings. */
class HabitCalendar(ctx: Context, private val month: YearMonth, private val done: Set<LocalDate>, private val today: LocalDate,
                    private val color: Int, private val onTap: (LocalDate) -> Unit) : View(ctx) {
    private val fill = Paint(Paint.ANTI_ALIAS_FLAG)
    private val text = Paint(Paint.ANTI_ALIAS_FLAG).apply { typeface = Fonts.medium; textAlign = Paint.Align.CENTER; textSize = ctx.dp(13).toFloat() }
    private val head = Paint(Paint.ANTI_ALIAS_FLAG).apply { typeface = Fonts.medium; textAlign = Paint.Align.CENTER; textSize = ctx.dp(11).toFloat(); color = Th.faint }
    private val first = month.atDay(1)
    private val lead = first.dayOfWeek.value - 1
    private val rows = (lead + month.lengthOfMonth() + 6) / 7
    private val headH get() = dp(24).toFloat()

    override fun onMeasure(w: Int, h: Int) {
        val width = MeasureSpec.getSize(w)
        setMeasuredDimension(width, (headH + rows * (width / 7f) * 0.9f).toInt())
    }

    private fun cellW() = width / 7f
    private fun cellH() = cellW() * 0.9f
    private fun center(d: LocalDate): Pair<Float, Float> {
        val idx = lead + d.dayOfMonth - 1
        return cellW() * (idx % 7 + 0.5f) to headH + cellH() * (idx / 7 + 0.5f)
    }

    override fun onDraw(c: Canvas) {
        val cw = cellW(); val ch = cellH()
        val r = minOf(cw, ch) * 0.36f
        listOf("M", "T", "W", "T", "F", "S", "S").forEachIndexed { i, s -> c.drawText(s, cw * (i + 0.5f), headH * 0.7f, head) }
        // Chain links between consecutive done days (also across week and month edges).
        fill.style = Paint.Style.FILL; fill.color = color
        val bar = r * 0.62f
        for (day in 1..month.lengthOfMonth()) {
            val d = month.atDay(day)
            if (d !in done) continue
            val (x, y) = center(d)
            val next = d.plusDays(1); val prev = d.minusDays(1)
            if (next in done) {
                val endX = if (d.dayOfWeek.value == 7 || day == month.lengthOfMonth()) x + cw / 2 else center(next).first
                c.drawRect(x, y - bar, endX, y + bar, fill)
            }
            if (prev in done && (d.dayOfWeek.value == 1 || day == 1)) c.drawRect(x - cw / 2, y - bar, x, y + bar, fill)
        }
        for (day in 1..month.lengthOfMonth()) {
            val d = month.atDay(day)
            val (x, y) = center(d)
            val future = d.isAfter(today)
            when {
                d in done -> {
                    fill.style = Paint.Style.FILL; fill.color = color; c.drawCircle(x, y, r, fill)
                    text.color = Th.bg
                }
                future -> text.color = Th.faint
                else -> {
                    fill.style = Paint.Style.STROKE; fill.strokeWidth = dp(if (d == today) 2.2f else 1.5f).toFloat()
                    fill.color = if (d == today) color else Th.surface3
                    c.drawCircle(x, y, r - fill.strokeWidth / 2, fill)
                    text.color = if (d == today) Th.text else Th.dim
                }
            }
            c.drawText("$day", x, y - (text.descent() + text.ascent()) / 2, text)
        }
    }

    /** Tap a past or today's date to toggle it. */
    fun handleTouch(e: MotionEvent): Boolean {
        if (e.actionMasked == MotionEvent.ACTION_DOWN) return true
        if (e.actionMasked != MotionEvent.ACTION_UP) return false
        if (e.y < headH) return false
        val col = (e.x / cellW()).toInt().coerceIn(0, 6)
        val row = ((e.y - headH) / cellH()).toInt()
        val day = row * 7 + col - lead + 1
        if (day < 1 || day > month.lengthOfMonth()) return false
        val d = month.atDay(day)
        if (d.isAfter(today)) return false
        onTap(d)
        return true
    }
}

