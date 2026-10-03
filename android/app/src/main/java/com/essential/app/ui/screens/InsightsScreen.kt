package com.essential.app.ui.screens

import android.os.Handler
import android.os.Looper
import android.view.View
import com.essential.app.core.*
import com.essential.app.data.Mode
import com.essential.app.ui.*
import kotlin.math.roundToInt

/** Productivity dashboard. Everything computed on the phone from local data. */
class InsightsScreen(a: MainActivity) : Screen(a) {
    private var range = 30
    private var cache: Insights? = null
    private var cacheKey = ""
    private var loading = false

    private fun key() = "$range-${today}-${repo.db.scalarL("SELECT COUNT(*) FROM hour_log")}-${repo.db.scalarL("SELECT MAX(updated_at) FROM hour_log")}"

    override fun content(): View {
        val k = key()
        val ins = cache.takeIf { cacheKey == k }
        if (ins == null) {
            if (!loading) {
                loading = true
                val from = today.minusDays(range - 1L); val to = today
                Thread {
                    val r = try { Insights(repo, from, to) } catch (e: Exception) { null }
                    Handler(Looper.getMainLooper()).post { loading = false; cache = r; cacheKey = k; a.refresh() }
                }.start()
            }
            return page {
                add(header())
                add(a.space(60))
                add(a.dimText("Calculating your last $range days…").apply { gravity = android.view.Gravity.CENTER })
            }
        }
        return page { add(header()); body(this, ins) }
    }

    private fun header(): View {
        val v = a.vbox()
        val r = a.hbox()
        r.add(a.h1("Insights"), 0, WRAP, 1f)
        r.add(a.alarmBtn(), WRAP, WRAP, end = 4)
        r.add(a.choice(listOf("7", "30", "90"), "$range") { range = it?.toInt() ?: 30; a.refresh() }, WRAP, WRAP)
        v.add(r, top = 8, bottom = 12)
        val row = a.hbox()
        row.add(a.btn("Weekly report", Btn.TONAL, "insights") { a.push(WeeklyReportScreen(a)) }, 0, WRAP, 1f, end = 8)
        row.add(a.btn("Plan vs actual", Btn.TONAL) { a.selectTab("log") }, 0, WRAP, 1f)
        v.add(row, bottom = 16)
        return v
    }

    private fun body(v: android.widget.LinearLayout, ins: Insights) = with(v) {
        val days = ins.days
        val labels = days.map { if (range <= 7) TimeUtil.fmtDow(it.date).take(2) else "${it.date.dayOfMonth}" }
        val active = ins.activeDays
        if (active.isEmpty()) { add(a.dimText("Log a few hours to see your insights.")); return@with }

        // Headline: Essential Hours per day
        val avgEh = active.map { it.essential }.average()
        val target = repo.settings.targetEssential(Mode.NORMAL)
        val c = a.card(16)
        val hr = a.hbox().apply { gravity = android.view.Gravity.BOTTOM }
        hr.add(a.txt(TimeUtil.fmtHours(avgEh), 44f, Th.primary, Fonts.light), WRAP, WRAP)
        hr.add(a.txt("  Essential h/day avg · target ${TimeUtil.fmtHours(target)}", 13.5f, Th.dim), 0, WRAP, 1f, bottom = 10)
        c.add(hr)
        c.add(BarChart(a, days.map { it.essential }, labels, days.map { if (it.essential >= it.targetEssential) Th.primary else Th.alpha(Th.primary, 0.55f) }, target, 170), top = 6)
        add(c, bottom = 12)

        section("Total working hours per day") {
            it.add(BarChart(a, days.map { d -> d.work }, labels, days.map { Th.necessary }, repo.settings.targetWork(Mode.NORMAL)))
        }
        section("Essential · Necessary · Trivial") {
            it.add(StackedBarChart(a, days.map { d -> listOf(d.essential to Th.essential, d.necessary to Th.necessary, d.trivial to Th.trivial) }, labels))
            it.add(a.legend("Essential" to Th.essential, "Necessary" to Th.necessary, "Trivial" to Th.trivial), top = 6)
            val tot = days.sumOf { d -> d.logged }.coerceAtLeast(0.01)
            it.add(a.dimText("Split: ${(days.sumOf { d -> d.essential } / tot * 100).roundToInt()}% essential · ${(days.sumOf { d -> d.necessary } / tot * 100).roundToInt()}% necessary · ${(days.sumOf { d -> d.trivial } / tot * 100).roundToInt()}% trivial"), top = 4)
        }
        section("Plan-follow rate") {
            it.add(LineChart(a, listOf(days.map { d -> d.follow?.times(100) }), listOf(Th.green), labels, 100.0, fmt = { v -> "${v.roundToInt()}%" }))
        }
        section("Golden Hours: focus & energy by hour") {
            val g = ins.goldenHours()
            if (g.isEmpty()) return@section
            val ds = repo.dayStart()
            val hours = g.keys.sortedBy { h -> TimeUtil.offset(h * 60, ds) }
            it.add(DualBarChart(a, hours.map { h -> g[h]?.first }, hours.map { h -> g[h]?.second }, Th.primary, Th.necessary,
                hours.map { h -> TimeUtil.fmtTime(h * 60).replace(" ", "").lowercase().replace(":00", "") }, 5.0))
            it.add(a.legend("Focus" to Th.primary, "Energy" to Th.necessary), top = 6)
            val best = g.filter { e -> e.value.first != null }.maxByOrNull { e -> e.value.first!! }
            best?.let { b -> it.add(a.dimText("Your best focus is around ${TimeUtil.fmtTime(b.key * 60)}. Guard it for Essential work."), top = 4) }
        }
        section("Time vs ₹ by activity") {
            val vs = ins.byVenture()
            val maxH = vs.maxOfOrNull { s -> s.hours } ?: 1.0
            val maxM = vs.maxOfOrNull { s -> s.money }?.coerceAtLeast(1.0) ?: 1.0
            vs.forEach { s ->
                val r = a.hbox()
                r.add(a.dot(s.color, 9), a.dp(9), a.dp(9), end = 8)
                r.add(a.txt(s.name, 14.5f, Th.text, Fonts.medium), 0, WRAP, 1f)
                r.add(a.txt("${TimeUtil.fmtHours(s.hours)}h · ${TimeUtil.rupees(s.money)} · ${TimeUtil.rupees(s.perHour)}/h", 12.5f, Th.dim), WRAP, WRAP)
                it.add(r, top = 10)
                val bars = a.hbox()
                bars.add(a.progress(s.hours / maxH, s.color, 6), 0, a.dp(6), 1f, end = 6)
                bars.add(a.progress(s.money / maxM, Th.trivial, 6), 0, a.dp(6), 1f)
                it.add(bars, top = 6)
            }
            it.add(a.legend("Time" to Th.dim, "₹ earned" to Th.trivial), top = 8)
            ins.lowReturnVentures().forEach { s -> it.add(a.txt("${s.name}: lots of time, low return (${TimeUtil.rupees(s.perHour)}/h). Worth an uncommit review?", 13.5f, Th.yellow), top = 6) }
        }
        section("Daily Score") {
            it.add(Heatmap(a, days.map { d -> d.date to (if (d.logged > 0) d.score else null) }))
            it.add(a.dimText("Average ${active.map { d -> d.score }.average().roundToInt()} · darker = higher"), top = 6)
        }
        section("What pulls you off plan") {
            val off = ins.offPlanReasons().take(5)
            val dist = ins.distractionReasons().take(5)
            if (off.isNotEmpty()) { it.add(a.dimText("Off-plan reasons")); it.add(a.hbars(off.map { (k, n) -> Triple(k, n.toDouble(), Th.red) }, { n -> "${n.toInt()}" }), bottom = 10) }
            if (dist.isNotEmpty()) { it.add(a.dimText("Distractions"), top = 6); it.add(a.hbars(dist.map { (k, n) -> Triple(k, n.toDouble(), Th.trivial) }, { n -> "${n.toInt()}" })) }
        }
        section("Eliminate & estimate") {
            it.add(a.body("Hours protected by saying no: ${TimeUtil.fmtHours(ins.hoursProtected())}h"))
            val br = ins.bufferRatio()
            it.add(a.body(br?.let { r -> "Tasks take ${"%.1f".format(r)}× your estimate" } ?: "Estimate a few tasks to see buffer accuracy"), top = 4)
            val trend = Insights.bufferTrend(repo)
            if (trend.size >= 2) it.add(LineChart(a, listOf(trend.map { t -> t.second }), listOf(Th.necessary), trend.map { t -> TimeUtil.fmtShort(t.first) }, heightDp = 110), top = 8)
        }
        section("Normal vs Max Mode") {
            val n = ins.modeStats(Mode.NORMAL); val m = ins.modeStats(Mode.MAX)
            if (m.days == 0) { it.add(a.dimText("No Max Mode days in this range.")); return@section }
            fun row(l: String, x: String, y: String) {
                val r = a.hbox().apply { setPadding(0, a.dp(6), 0, a.dp(6)) }
                r.add(a.txt(l, 14f), 0, WRAP, 1.4f); r.add(a.txt(x, 14f, Th.primary, Fonts.medium), 0, WRAP, 1f); r.add(a.txt(y, 14f, Th.trivial, Fonts.medium), 0, WRAP, 1f)
                it.add(r)
            }
            row("", "Normal", "Max")
            row("Days", "${n.days}", "${m.days}")
            row("Essential h/day", TimeUtil.fmtHours(n.essential), TimeUtil.fmtHours(m.essential))
            row("Focus", n.focus?.let { f -> "%.1f".format(f) } ?: "–", m.focus?.let { f -> "%.1f".format(f) } ?: "–")
            row("Energy", n.energy?.let { f -> "%.1f".format(f) } ?: "–", m.energy?.let { f -> "%.1f".format(f) } ?: "–")
            row("₹ / work hour", TimeUtil.rupees(n.perHour), TimeUtil.rupees(m.perHour))
        }
        repo.intent()?.let { g ->
            section("Goal pace") {
                val p = Insights.goalPace(g, today)
                it.add(a.body(g.title))
                it.addProgress(g.progress / 100.0, Th.primary, 8, top = 8)
                it.add(a.dimText("${g.progress}% done · expected ${p.expectedPct}% · ${p.daysLeft} days left"), top = 6)
                it.add(a.body(p.projected?.let { d -> "At the current rate you'll finish by ${TimeUtil.fmtDayLong(d)}" + if (d.isAfter(g.endDate)) " — after your target date." else " — on time." }
                    ?: "Mark some progress to project a finish date."), top = 4)
            }
        }
    }

    private fun android.widget.LinearLayout.section(title: String, build: (android.widget.LinearLayout) -> Unit) {
        val c = a.card(16)
        c.add(a.label(title), bottom = 8)
        build(c)
        add(c, bottom = 12)
    }
}
