package com.essential.app.ui.screens

import android.view.View
import android.widget.LinearLayout
import com.essential.app.core.Days
import com.essential.app.core.Hooks
import com.essential.app.core.TimeUtil
import com.essential.app.data.Book
import com.essential.app.data.Habit
import com.essential.app.data.HabitUnit
import com.essential.app.data.Repo
import com.essential.app.ui.*
import java.time.LocalDate
import java.time.YearMonth
import java.time.temporal.TemporalAdjusters
import kotlin.math.roundToInt

/** Log how much of a measured habit you did: minutes, pages (with a book), a count or your own unit. */
object AmountSheet {
    fun open(a: MainActivity, h: Habit, initialDate: LocalDate = Days.today(a.repo)) {
        val repo = a.repo
        var date = initialDate
        val books = repo.books(false).toMutableList()
        var bookId: Long? = books.firstOrNull()?.id
        val sh = Sheet(a, "Log ${h.name}", h.target?.let { "Daily target: ${HabitUnit.fmt(h.unit, it)}" })

        lateinit var dateRow: LinearLayout
        dateRow = a.listRow("Day", dayLabel(a, date), "log") {
            a.pickDate(date) { d -> if (!d.isAfter(Days.today(a.repo))) { date = d; ((dateRow.getChildAt(1) as LinearLayout).getChildAt(1) as android.widget.TextView).text = dayLabel(a, d) } }
        }
        sh.add(dateRow, bottom = 4)
        sh.add(a.dimText("Already today: ${HabitUnit.fmt(h.unit, repo.amount(h.id, date, date))}"), bottom = 10)

        val amount = a.field(when (h.unit) { HabitUnit.MINUTES -> "Minutes"; HabitUnit.PAGES -> "Pages read"; else -> "How many ${HabitUnit.short(h.unit)}" },
            numeric = true, decimal = h.unit != HabitUnit.PAGES)
        val presets = when (h.unit) {
            HabitUnit.MINUTES -> listOf(5, 10, 15, 20, 30, 45, 60, 90)
            HabitUnit.PAGES -> listOf(5, 10, 20, 30, 50)
            else -> listOf(1, 2, 5, 10, 20)
        }
        val chips = Flow(a)
        presets.forEach { p -> chips.addView(a.chip(if (h.unit == HabitUnit.MINUTES) TimeUtil.fmtDuration(p.toLong()) else "$p", false) { amount.setText("$p"); amount.setSelection(amount.text.length) }) }
        h.target?.let { t -> chips.addView(a.chip("Target ${HabitUnit.fmt(h.unit, t)}", false, Th.primary) { amount.setText(if (t == Math.floor(t)) "${t.toLong()}" else "$t") }) }

        if (h.usesBooks) {
            sh.add(a.label("Book"), bottom = 6)
            val bookBox = a.vbox()
            val nowOn = a.field("Or: I'm now on page…", numeric = true)
            fun renderBooks() {
                bookBox.removeAllViews()
                val f = Flow(a)
                books.forEach { b ->
                    f.addView(a.chip("${b.title} · ${b.left} left", b.id == bookId, h.color) { bookId = if (bookId == b.id) null else b.id; renderBooks() })
                }
                f.addView(a.chip("+ Add book", false, Th.dim) {
                    BookEditor.open(a, null) { newId -> repo.book(newId)?.let { books.add(it); bookId = it.id; renderBooks() } }
                })
                bookBox.add(f)
                val b = books.firstOrNull { it.id == bookId }
                if (b != null) bookBox.add(a.dimText("On page ${b.currentPage} of ${b.totalPages} · ${b.left} pages left"), top = 6)
                else if (books.isEmpty()) bookBox.add(a.dimText("Add the book you're reading with its total pages to see pages left."), top = 6)
            }
            renderBooks()
            sh.add(bookBox, bottom = 10)
            nowOn.addTextChangedListener(Watch { t ->
                val b = books.firstOrNull { it.id == bookId } ?: return@Watch
                val p = t.toIntOrNull() ?: return@Watch
                if (p > b.currentPage) amount.setText("${p - b.currentPage}")
            })
            sh.add(amount, bottom = 6)
            sh.add(chips, bottom = 6)
            sh.add(nowOn, bottom = 8)
        } else {
            sh.add(amount, bottom = 6)
            sh.add(chips, bottom = 8)
        }
        val note = a.field("Note (optional)")
        sh.add(note)
        sh.actions("Save") {
            val v = amount.value.toDoubleOrNull()
            if (v == null || v <= 0) { a.toast("Enter how much"); return@actions }
            repo.logAmount(h, date, v, if (h.usesBooks) bookId else null, note.value.ifBlank { null })
            Hooks.afterChange(a); a.root.haptic(); sh.dismiss()
            val b = repo.book(bookId)
            a.toast(if (h.usesBooks && b != null) (if (b.done) "Finished \"${b.title}\"!" else "${HabitUnit.fmt(h.unit, v)} · ${b.left} pages left")
                    else "Logged ${HabitUnit.fmt(h.unit, v)}")
            a.refresh()
        }
        sh.show()
        amount.requestFocus()
    }

    private fun dayLabel(a: MainActivity, d: LocalDate) = if (d == Days.today(a.repo)) "Today" else TimeUtil.fmtDayLong(d)
}


/** Totals for a measured habit: today, week, month, year, all time + monthly chart (each optional per habit). */
object HabitTotals {
    data class T(val today: Double, val week: Double, val month: Double, val year: Double, val all: Double, val days: Long)

    fun of(repo: Repo, h: Habit, today: LocalDate) = T(
        repo.amount(h.id, today, today),
        repo.amount(h.id, TimeUtil.weekStart(today), today),
        repo.amount(h.id, today.withDayOfMonth(1), today),
        repo.amount(h.id, today.with(TemporalAdjusters.firstDayOfYear()), today),
        repo.amountAllTime(h.id), repo.daysWithAmount(h.id))

    fun card(a: MainActivity, h: Habit, today: LocalDate): View {
        val t = of(a.repo, h, today)
        val c = a.card(16)
        c.add(a.label("Totals"), bottom = 8)
        fun row(label: String, v: Double, extra: String? = null) {
            val r = a.hbox().apply { setPadding(0, a.dp(6), 0, a.dp(6)) }
            r.add(a.txt(label, 15f), 0, WRAP, 1f)
            r.add(a.txt(HabitUnit.fmt(h.unit, v) + (extra ?: ""), 15f, Th.text, Fonts.semibold), WRAP, WRAP)
            c.add(r)
        }
        row("Today", t.today, h.target?.let { " / ${HabitUnit.fmt(h.unit, it)}" })
        row("This week", t.week)
        row("This month", t.month)
        row("This year", t.year)
        row("All time", t.all)
        if (t.days > 0) c.add(a.dimText("Average on days done: ${HabitUnit.fmt(h.unit, t.all / t.days)} · ${t.days} days"), top = 4)
        // last 12 months
        val months = (11 downTo 0).map { YearMonth.from(today).minusMonths(it.toLong()) }
        val vals = months.map { m -> a.repo.amount(h.id, m.atDay(1), m.atEndOfMonth()) }
        if (vals.any { it > 0 }) {
            val asHours = h.unit == HabitUnit.MINUTES
            c.add(a.label(if (asHours) "Hours per month" else "Per month"), top = 14, bottom = 6)
            c.add(BarChart(a, vals.map { if (asHours) it / 60.0 else it }, months.map { it.month.name.take(1) }, months.map { h.color },
                fmt = { v -> if (asHours) TimeUtil.fmtHours(v) else "${v.roundToInt()}" }))
        }
        return c
    }
}

/** Your books: total pages, where you are, pages left. Used by any "Pages" habit. */
class BooksScreen(a: MainActivity) : Screen(a) {
    override val title = "Books"
    override fun actions() = listOf(a.iconBtn("plus", Th.text, desc = "Add book") { BookEditor.open(a, null) { a.refresh() } })

    override fun content(): View = page {
        val books = repo.books()
        add(a.dimText("Add each book with its total pages. Pages you log in a reading habit move the book forward automatically."), bottom = 12)
        if (books.isEmpty()) add(a.btn("Add your first book", icon = "plus") { BookEditor.open(a, null) { a.refresh() } })
        val reading = books.filter { !it.done }; val done = books.filter { it.done }
        if (reading.isNotEmpty()) add(a.label("Reading"), bottom = 6)
        reading.forEach { add(bookCard(it), bottom = 10) }
        if (done.isNotEmpty()) add(a.label("Finished"), top = 6, bottom = 6)
        done.forEach { add(bookCard(it), bottom = 10) }
        val total = books.sumOf { repo.pagesReadFromBook(it.id) }
        if (total > 0) add(a.dimText("Pages logged across all books: ${total.toInt()}"), top = 6)
    }

    private fun bookCard(b: Book): View {
        val c = a.card(16) { BookEditor.open(a, b) { a.refresh() } }
        c.add(a.txt(b.title, 16.5f, Th.text, Fonts.semibold))
        b.author?.takeIf { it.isNotBlank() }?.let { c.add(a.dimText(it), top = 2) }
        c.addProgress(b.fraction.coerceIn(0.0, 1.0), Th.primary, 8, top = 10)
        c.add(a.txt(if (b.done) "Finished${b.finished?.let { " on ${TimeUtil.fmtShort(LocalDate.parse(it))}" } ?: ""} · ${b.totalPages} pages"
            else "Page ${b.currentPage} of ${b.totalPages} · ${b.left} pages left · ${(b.fraction * 100).roundToInt()}%", 13.5f, Th.dim), top = 6)
        return c
    }
}

object BookEditor {
    fun open(a: MainActivity, b: Book?, onSaved: (Long) -> kotlin.Unit) {
        val repo = a.repo
        val sh = Sheet(a, if (b == null) "Add book" else "Edit book")
        val title = a.field("Title", b?.title)
        val author = a.field("Author (optional)", b?.author)
        val total = a.field("Total pages", b?.totalPages?.takeIf { it > 0 }?.toString(), numeric = true)
        val current = a.field("Pages already read (current page)", b?.currentPage?.toString() ?: "0", numeric = true)
        sh.add(title); sh.add(author); sh.add(total); sh.add(current)
        if (b != null) {
            sh.add(a.btn(if (b.done) "Mark as still reading" else "Mark finished", Btn.TONAL) {
                repo.updateBook(if (b.done) b.copy(finished = null, currentPage = minOf(b.currentPage, maxOf(0, b.totalPages - 1)))
                    else b.copy(finished = TimeUtil.now().toLocalDate().toString(), currentPage = b.totalPages))
                sh.dismiss(); onSaved(b.id)
            })
            sh.add(a.btn("Delete book", Btn.TEXT, color = Th.red) {
                a.confirm("Delete \"${b.title}\"?", "Your logged pages stay in the habit's history.", "Delete", danger = true) { repo.deleteBook(b.id); sh.dismiss(); onSaved(b.id) }
            })
        }
        sh.actions("Save") {
            val t = total.value.toIntOrNull() ?: 0
            if (title.value.isBlank() || t <= 0) { a.toast("Add the title and total pages"); return@actions }
            val cur = (current.value.toIntOrNull() ?: 0).coerceIn(0, t)
            val id = if (b == null) repo.addBook(title.value, author.value.ifBlank { null }, t, cur)
            else { repo.updateBook(b.copy(title = title.value, author = author.value.ifBlank { null }, totalPages = t, currentPage = cur,
                finished = if (cur >= t) (b.finished ?: TimeUtil.now().toLocalDate().toString()) else null)); b.id }
            sh.dismiss(); onSaved(id)
        }
        sh.show()
        if (b == null) title.requestFocus()
    }
}
