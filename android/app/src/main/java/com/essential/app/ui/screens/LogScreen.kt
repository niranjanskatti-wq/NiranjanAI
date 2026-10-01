package com.essential.app.ui.screens

import android.annotation.SuppressLint
import android.view.GestureDetector
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.widget.ScrollView
import com.essential.app.core.*
import com.essential.app.data.Source
import com.essential.app.ui.*
import java.time.LocalDate
import kotlin.math.abs
import kotlin.math.roundToInt

/** Plan vs Actual: scheduled block on the left, what happened on the right. Swipe between days. */
class LogScreen(a: MainActivity) : Screen(a) {
    private var date: LocalDate? = null

    @SuppressLint("ClickableViewAccessibility")
    override fun content(): View {
        val d = date ?: today
        val day = Days.resolve(repo, d)
        val logs = repo.logs(d).associateBy { it.hour }
        val v = page {
            val nav = a.hbox()
            nav.add(a.iconBtn("left", Th.text, desc = "Previous day") { date = d.minusDays(1); a.refresh() }, a.dp(48), a.dp(48))
            val mid = a.vbox().apply { gravity = Gravity.CENTER_HORIZONTAL }
            mid.add(a.txt(if (d == today) "Today" else TimeUtil.fmtDay(d), 18f, Th.text, Fonts.semibold, center = true), WRAP, WRAP, gravity = Gravity.CENTER_HORIZONTAL)
            mid.add(a.txt("${if (day.isMax) "Max" else "Normal"} · ${day.template?.name ?: ""}", 12.5f, Th.dim, center = true), WRAP, WRAP, gravity = Gravity.CENTER_HORIZONTAL)
            mid.click { a.pickDate(d) { date = it; a.refresh() } }
            nav.add(mid, 0, WRAP, 1f)
            nav.add(a.iconBtn("right", if (d < today) Th.text else Th.faint, desc = "Next day") { if (d < today) { date = d.plusDays(1); a.refresh() } }, a.dp(48), a.dp(48))
            add(nav, bottom = 10)

            val l = logs.values.toList()
            val sum = a.card(14)
            val sr = a.hbox()
            fun stat(v: String, label: String) { val c = a.vbox(); c.add(a.txt(v, 20f, Th.text, Fonts.semibold)); c.add(a.txt(label, 12f, Th.dim)); sr.add(c, 0, WRAP, 1f) }
            stat(TimeUtil.fmtHours(Metrics.essentialHours(l)) + "h", "Essential")
            stat(TimeUtil.fmtHours(Metrics.workHours(l)) + "h", "Working")
            stat(Metrics.followRate(l)?.let { "${(it * 100).roundToInt()}%" } ?: "–", "Plan followed")
            stat("${l.size}/${day.hours.size}", "Logged")
            sum.add(sr)
            add(sum, bottom = 10)
            add(a.legend("Followed" to Th.green, "Partly" to Th.yellow, "Off-plan" to Th.red, "Unlogged" to Th.grey), bottom = 8)
            val missing = Logging.missing(repo, day)
            if (missing.isNotEmpty()) add(a.btn("Log ${missing.size} missed hour${if (missing.size == 1) "" else "s"}", Btn.TONAL) { a.push(MissedHoursScreen(a, d)) }, bottom = 12)

            val head = a.hbox()
            head.add(a.label("Planned"), 0, WRAP, 1f, start = 58)
            head.add(a.label("Actual"), 0, WRAP, 1f, start = 8)
            add(head, bottom = 6)
            val now = TimeUtil.now()
            for (h in day.hours) {
                val p = day.plannedFor(h)
                val lg = logs[h]
                val future = day.slotStart(h).isAfter(now)
                val row = a.hbox().apply { setPadding(0, a.dp(4), 0, a.dp(4)); minimumHeight = a.dp(56) }
                row.add(a.txt(TimeUtil.fmtTime(h * 60), 12.5f, Th.faint, Fonts.medium), a.dp(54), WRAP)
                val left = a.vbox().apply { setPadding(a.dp(10), a.dp(8), a.dp(10), a.dp(8)); background = rounded(Th.surface, a.dp(12).toFloat()) }
                left.add(a.txt(p?.title ?: "—", 13.5f, Th.text, maxLines = 2))
                left.add(a.txt(p?.category ?: "", 11.5f, Th.faint, maxLines = 1))
                row.add(left, 0, MATCH, 1f, end = 6)
                val col = if (lg == null) Th.grey else if (lg.followedPlan == null) Th.type(lg.type) else Th.plan(lg.followedPlan)
                val right = a.vbox().apply { setPadding(a.dp(10), a.dp(8), a.dp(10), a.dp(8)) }
                val r = a.dp(12).toFloat()
                right.background = ripple(if (future && lg == null) rounded(0, r, a.dp(1), Th.outline) else rounded(Th.alpha(col, if (lg == null) 0.5f else 0.18f), r, if (lg != null) a.dp(1) else 0, Th.alpha(col, 0.7f)), r)
                if (lg != null) {
                    right.add(a.txt(lg.activity, 13.5f, Th.text, maxLines = 2))
                    right.add(a.txt(lg.type + (lg.offPlanReason?.let { " · $it" } ?: "") + (lg.money?.let { " · " + TimeUtil.rupees(it) } ?: ""), 11.5f, Th.dim, maxLines = 1))
                } else right.add(a.txt(if (future) "" else "Tap to log", 13f, Th.faint))
                if (!future) right.click(true) { LogHourSheet.open(a, d, h) }
                row.add(right, 0, MATCH, 1f)
                add(row)
            }
        }
        val gd = GestureDetector(a, object : GestureDetector.SimpleOnGestureListener() {
            override fun onFling(e1: MotionEvent?, e2: MotionEvent, vx: Float, vy: Float): Boolean {
                if (e1 == null) return false
                val dx = e2.x - e1.x; val dy = e2.y - e1.y
                if (abs(dx) > a.dp(80) && abs(dx) > abs(dy) * 1.5f) {
                    if (dx < 0 && d < today) { date = d.plusDays(1); a.refresh(); return true }
                    if (dx > 0) { date = d.minusDays(1); a.refresh(); return true }
                }
                return false
            }
        })
        (v as ScrollView).setOnTouchListener { _, e -> gd.onTouchEvent(e); false }
        return v
    }
}

/** Fill several unlogged hours at once. */
class MissedHoursScreen(a: MainActivity, private val forDate: LocalDate? = null) : Screen(a) {
    override val title = "Missed hours"

    override fun content(): View = page {
        val dates = if (forDate != null) listOf(forDate) else listOf(today, today.minusDays(1))
        var any = false
        for (d in dates) {
            val day = Days.resolve(repo, d)
            val missing = Logging.missing(repo, day)
            if (missing.isEmpty()) continue
            any = true
            val hr = a.hbox()
            hr.add(a.label(if (d == today) "Today" else TimeUtil.fmtDay(d)), 0, WRAP, 1f)
            hr.add(a.btn("All as planned", Btn.TEXT) {
                missing.forEach { h -> Logging.quick(a, Logging.Slot(d, h), Logging.AS_PLANNED, Source.APP) }
                it.haptic(); a.toast("${missing.size} hours logged as planned"); a.refresh()
            }, WRAP, WRAP)
            add(hr, top = 6, bottom = 6)
            for (h in missing) {
                val p = day.plannedFor(h)
                val c = a.card(14)
                val t = a.hbox()
                t.add(a.txt(TimeUtil.fmtHourRange(h), 14.5f, Th.text, Fonts.medium), 0, WRAP, 1f)
                t.add(a.iconBtn("edit", Th.dim, 40, "Edit") { LogHourSheet.open(a, d, h) }, WRAP, WRAP)
                c.add(t)
                c.add(a.dimText("Planned: ${p?.title ?: "—"}"), top = 2, bottom = 10)
                val r = a.hbox()
                fun q(label: String, kind: String, color: Int) = r.add(a.btn(label, Btn.TONAL, color = color) {
                    Logging.quick(a, Logging.Slot(d, h), kind, Source.APP); it.haptic(); a.refresh()
                }, 0, WRAP, 1f, end = 6)
                q("As planned", Logging.AS_PLANNED, Th.primary)
                q("Essential", Logging.ESSENTIAL, Th.essential)
                q("Trivial", Logging.TRIVIAL, Th.trivial)
                c.add(r)
                add(c, bottom = 8)
            }
        }
        if (!any) {
            add(a.space(40))
            add(a.txt("All caught up", 20f, Th.text, Fonts.semibold, center = true))
            add(a.dimText("Every finished hour is logged."), top = 6)
        }
    }
}

