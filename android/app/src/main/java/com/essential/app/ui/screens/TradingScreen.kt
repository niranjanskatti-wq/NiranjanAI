package com.essential.app.ui.screens

import android.app.Dialog
import android.graphics.Color
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import com.essential.app.core.*
import com.essential.app.data.Emotions
import com.essential.app.data.Trade
import com.essential.app.ui.*
import kotlin.math.roundToInt

/** MCX trading journal: required pre-trade checklist, revenge-trade guard, stats. */
class TradingScreen(a: MainActivity) : Screen(a) {
    override val title = "Trading journal"
    override fun actions() = listOf(a.iconBtn("plus", Th.text, desc = "Log trade") { startTrade(a) })
    private var range = 30

    companion object {
        /** Guard condition: N losses in a row today, or daily loss limit hit. Returns the reason, or null. */
        fun guardReason(a: MainActivity): String? {
            val repo = a.repo
            val today = Days.today(repo)
            val t = repo.trades(today, today)
            val maxL = repo.settings.int("max_consec_losses").coerceAtLeast(1)
            val limit = repo.settings.dbl("loss_limit")
            val pnl = t.sumOf { it.pnl }
            if (limit > 0 && pnl <= -limit) return "Today's P&L is ${TimeUtil.rupees(pnl)} — your daily loss limit is ${TimeUtil.rupees(limit)}."
            if (t.size >= maxL && t.takeLast(maxL).all { it.pnl < 0 }) return "$maxL losses in a row today (${t.takeLast(maxL).joinToString(", ") { TimeUtil.rupees(it.pnl) }})."
            return null
        }

        /** Full-screen stop. Dismiss only by typing "I understand". */
        fun showGuard(a: MainActivity, reason: String, onDismiss: () -> Unit = {}) {
            val d = Dialog(a, android.R.style.Theme_DeviceDefault_NoActionBar_Fullscreen)
            d.setCancelable(false)
            val col = a.vbox(28).apply { gravity = Gravity.CENTER; setBackgroundColor(Th.bg) }
            col.add(a.iconView("warn", Th.red, 48), WRAP, WRAP, gravity = Gravity.CENTER_HORIZONTAL, bottom = 18)
            col.add(a.txt("Stop trading for today", 28f, Th.text, Fonts.semibold, center = true), bottom = 12)
            col.add(a.txt(reason, 16f, Th.dim, center = true), bottom = 10)
            col.add(a.txt("Revenge trades are where most losses come from. The market will be here tomorrow; your capital needs to be too.", 15f, Th.dim, center = true), bottom = 28)
            col.add(a.dimText("Type \"I understand\" to close"), bottom = 8)
            val f = a.field("I understand")
            col.add(f, bottom = 12)
            val b = a.btn("Close", color = Th.red) {}
            b.alpha = 0.4f; b.isEnabled = false
            f.addTextChangedListener(Watch { s ->
                val ok = s.trim().equals("I understand", ignoreCase = true)
                b.isEnabled = ok; b.alpha = if (ok) 1f else 0.4f
            })
            b.setOnClickListener { a.repo.settings.set("guard_date", Days.today(a.repo).toString()); d.dismiss(); onDismiss() }
            col.add(b)
            d.setContentView(a.scroll(col).apply { setBackgroundColor(Th.bg) })
            d.window?.setBackgroundDrawable(android.graphics.drawable.ColorDrawable(Color.TRANSPARENT))
            d.window?.setLayout(MATCH, MATCH)
            d.window?.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
            d.show()
        }

        fun startTrade(a: MainActivity) {
            val reason = guardReason(a)
            if (reason != null) { showGuard(a, reason) { checklist(a) }; return }
            checklist(a)
        }

        private fun checklist(a: MainActivity) {
            val checks = BooleanArray(4)
            val items = listOf("Level marked?", "Stop loss set?", "Size within limit?", "Not revenge trading?")
            val sh = Sheet(a, "Pre-trade checklist", "All four before you enter.")
            lateinit var go: android.widget.TextView
            items.forEachIndexed { i, s ->
                val r = a.hbox().apply { setPadding(0, a.dp(10), 0, a.dp(10)) }
                val box = android.widget.FrameLayout(a)
                fun render() {
                    box.removeAllViews()
                    box.background = if (checks[i]) rounded(Th.primary, a.dp(8).toFloat()) else rounded(0, a.dp(8).toFloat(), a.dp(2), Th.dim)
                    if (checks[i]) box.add(a.iconView("check", Th.onPrimary, 16), MATCH, MATCH)
                }
                render()
                r.add(box, a.dp(26), a.dp(26), end = 14)
                r.add(a.txt(s, 16.5f), 0, WRAP, 1f)
                r.click(true) { checks[i] = !checks[i]; render(); val ok = checks.all { it }; go.isEnabled = ok; go.alpha = if (ok) 1f else 0.4f }
                sh.add(r, bottom = 0)
            }
            go = a.btn("Checklist passed — log trade") { sh.dismiss(); form(a, true) }
            go.isEnabled = false; go.alpha = 0.4f
            sh.add(go, top = 12, bottom = 4)
            sh.add(a.btn("I skipped the checklist (log honestly)", Btn.TEXT, color = Th.dim) { sh.dismiss(); form(a, false) })
            sh.show()
        }

        private fun form(a: MainActivity, checklistPassed: Boolean) {
            val repo = a.repo
            var instrument = "Gold"; var dir = "Long"; var rules: Boolean? = if (checklistPassed) null else false; var emotion: String? = null
            val sh = Sheet(a, "Log trade")
            sh.add(a.label("Instrument"), bottom = 6)
            val custom = a.field("Custom instrument (optional)")
            sh.add(a.choice(repo.instruments(), instrument) { instrument = it ?: instrument })
            sh.add(custom)
            sh.add(a.choice(listOf("Long", "Short"), dir) { dir = it ?: dir })
            val nums = a.hbox()
            val entry = a.field("Entry", numeric = true, decimal = true); val exit = a.field("Exit", numeric = true, decimal = true)
            nums.add(entry, 0, WRAP, 1f, end = 8); nums.add(exit, 0, WRAP, 1f)
            sh.add(nums)
            val qty = a.field("Quantity (units)", numeric = true, decimal = true)
            sh.add(qty)
            val pnl = a.field("P&L ₹ (auto from entry/exit × qty, or type it)", numeric = true, decimal = true)
            sh.add(pnl)
            val calc = Watch {
                val e = entry.value.toDoubleOrNull(); val x = exit.value.toDoubleOrNull(); val q = qty.value.toDoubleOrNull()
                if (e != null && x != null && q != null && !pnl.hasFocus()) pnl.setText(((if (dir == "Long") x - e else e - x) * q).roundToInt().toString())
            }
            entry.addTextChangedListener(calc); exit.addTextChangedListener(calc); qty.addTextChangedListener(calc)
            sh.add(a.label("Rules followed?"), bottom = 6)
            sh.add(a.choice(listOf("Yes", "No"), rules?.let { if (it) "Yes" else "No" }, { if (it == "Yes") Th.green else Th.red }) { rules = it == "Yes" })
            sh.add(a.label("Emotion"), bottom = 6)
            sh.add(a.choice(Emotions.ALL, null, { if (it == "Calm") Th.primary else Th.trivial }, allowNone = true) { emotion = it })
            val note = a.field("Note (optional)")
            sh.add(note)
            sh.actions("Save trade") {
                val p = pnl.value.toDoubleOrNull()
                if (p == null) { a.toast("Enter the P&L"); return@actions }
                if (rules == null) { a.toast("Were your rules followed?"); return@actions }
                val now = System.currentTimeMillis()
                repo.addTrade(Trade(0, Days.today(repo), now, custom.value.ifBlank { instrument }, dir, entry.value.toDoubleOrNull(), exit.value.toDoubleOrNull(),
                    qty.value.toDoubleOrNull(), p, rules!!, emotion, checklistPassed, note.value.ifBlank { null }))
                sh.dismiss()
                a.toast("Trade logged: ${TimeUtil.rupees(p, true)}")
                guardReason(a)?.let { showGuard(a, it) }
                a.refresh()
            }
            sh.show()
        }
    }

    override fun content(): View = page {
        val todayTrades = repo.trades(today, today)
        val pnl = todayTrades.sumOf { it.pnl }
        val limit = repo.settings.dbl("loss_limit")
        val c = a.card(18)
        c.add(a.label("Today"))
        c.add(a.txt(TimeUtil.rupees(pnl, true), 40f, if (pnl >= 0) Th.green else Th.red, Fonts.light), top = 2)
        c.add(a.dimText("${todayTrades.size} trade${if (todayTrades.size == 1) "" else "s"} · loss limit ${TimeUtil.rupees(limit)}"), top = 2)
        if (pnl < 0 && limit > 0) c.addProgress(-pnl / limit, Th.red, 6, top = 10)
        guardReason(a)?.let { r -> c.add(a.txt("Guard active: $r", 14f, Th.red), top = 10) }
        add(c, bottom = 12)
        add(a.btn("Log trade", icon = "plus") { startTrade(a) }, bottom = 16)

        val hr = a.hbox()
        hr.add(a.label("Stats"), 0, WRAP, 1f)
        hr.add(a.choice(listOf("7d", "30d", "90d"), "${range}d") { range = it?.removeSuffix("d")?.toInt() ?: 30; a.refresh() }, WRAP, WRAP)
        add(hr, bottom = 8)
        val ins = Insights(repo, today.minusDays(range - 1L), today)
        val st = ins.tradeStats()
        if (st.count == 0) { add(a.dimText("No trades in this range.")); return@page }
        val sc = a.card(16)
        val r = a.hbox()
        fun stat(v: String, l: String, col: Int = Th.text) { val x = a.vbox(); x.add(a.txt(v, 20f, col, Fonts.semibold)); x.add(a.txt(l, 12f, Th.dim)); r.add(x, 0, WRAP, 1f) }
        stat("${(st.winRate * 100).roundToInt()}%", "Win rate")
        stat(TimeUtil.rupees(st.pnl, true), "P&L", if (st.pnl >= 0) Th.green else Th.red)
        stat("${(st.rulesFollowedPct * 100).roundToInt()}%", "Rules kept")
        stat("${st.count}", "Trades")
        sc.add(r)
        add(sc, bottom = 12)
        val money = { v: Double -> TimeUtil.rupees(v, true) }
        fun pnlBars(title: String, rows: List<Pair<String, Double>>) {
            if (rows.isEmpty()) return
            add(a.label(title), top = 6)
            val m = rows.maxOf { kotlin.math.abs(it.second) }.coerceAtLeast(1.0)
            add(a.hbars(rows.map { Triple(it.first, kotlin.math.abs(it.second), if (it.second >= 0) Th.green else Th.red) }, { "" }, m, rows.map { money(it.second) }), bottom = 10)
        }
        pnlBars("P&L by instrument", st.byInstrument)
        pnlBars("Rules followed vs broken", listOf("Followed" to st.followedPnl, "Broken (${st.brokenCount})" to st.brokenPnl))
        pnlBars("P&L by emotion", st.byEmotion)
        if (st.byHour.isNotEmpty()) {
            add(a.label("P&L by time of day"), top = 6, bottom = 6)
            add(BarChart(a, st.byHour.map { kotlin.math.abs(it.second) }, st.byHour.map { TimeUtil.fmtTime(it.first * 60).replace(" ", "").lowercase() },
                st.byHour.map { if (it.second >= 0) Th.green else Th.red }, fmt = { TimeUtil.rupees(it) }), bottom = 4)
            add(a.dimText("Bar height = size; green profit, red loss."), bottom = 12)
        }
        add(a.label("Recent trades"), top = 6, bottom = 6)
        val list = a.card(6)
        repo.recentTrades(30).forEach { t ->
            list.add(a.listRow("${t.instrument} ${t.direction} · ${TimeUtil.rupees(t.pnl, true)}",
                "${TimeUtil.fmtDay(t.date)} ${TimeUtil.fmtClock(TimeUtil.at(t.ts))} · ${if (t.rulesFollowed) "rules kept" else "rules broken"}${t.emotion?.let { " · $it" } ?: ""}${if (!t.checklistPassed) " · no checklist" else ""}",
                "dot", if (t.pnl >= 0) Th.green else Th.red) {
                a.confirm("Delete trade?", "${t.instrument} ${TimeUtil.rupees(t.pnl, true)} on ${TimeUtil.fmtDay(t.date)}", "Delete", danger = true) { repo.deleteTrade(t.id); a.refresh() }
            })
        }
        add(list)
    }
}

