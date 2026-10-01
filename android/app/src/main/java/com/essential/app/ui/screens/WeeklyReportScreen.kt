package com.essential.app.ui.screens

import android.graphics.Bitmap
import android.graphics.Canvas
import android.view.View
import com.essential.app.core.Backup
import com.essential.app.core.RuleCoach
import com.essential.app.core.TimeUtil
import com.essential.app.core.WeeklyReport
import com.essential.app.ui.*
import java.io.ByteArrayOutputStream

/** Sunday report, generated on the phone from fixed rules. Shareable as an image. */
class WeeklyReportScreen(a: MainActivity) : Screen(a) {
    override val title = "Weekly report"
    private var weeksBack = 0
    private var cardView: View? = null
    private var report: WeeklyReport.Report? = null

    override fun actions() = listOf(a.iconBtn("share", Th.text, desc = "Share as image") { shareImage() })

    override fun content(): View = page {
        val week = TimeUtil.weekStart(today).minusWeeks(weeksBack.toLong())
        val r = RuleCoach.weekly(repo, week)
        report = r
        val nav = a.hbox()
        nav.add(a.iconBtn("left", Th.text, desc = "Previous week") { weeksBack++; a.refresh() }, a.dp(48), a.dp(48))
        nav.add(a.txt("${TimeUtil.fmtShort(r.weekStart)} – ${TimeUtil.fmtShort(r.weekEnd)}", 16f, Th.text, Fonts.medium, center = true), 0, WRAP, 1f)
        nav.add(a.iconBtn("right", if (weeksBack > 0) Th.text else Th.faint, desc = "Next week") { if (weeksBack > 0) { weeksBack--; a.refresh() } }, a.dp(48), a.dp(48))
        add(nav, bottom = 8)

        val card = a.card(22)
        card.add(a.txt("Essential", 13f, Th.primary, Fonts.semibold))
        card.add(a.txt("Week of ${TimeUtil.fmtShort(r.weekStart)}", 22f, Th.text, Fonts.semibold), top = 2)
        card.add(a.body(r.headline), top = 8, bottom = 6)
        r.sections.forEach { s ->
            card.add(a.label(s.title), top = 12, bottom = 4)
            s.lines.forEach { l -> card.add(a.txt(l, 14.5f, Th.text), bottom = 3) }
        }
        card.add(a.label("Next week"), top = 14, bottom = 4)
        r.suggestions.forEachIndexed { i, s ->
            val row = a.hbox().apply { gravity = android.view.Gravity.TOP }
            row.add(a.txt("${i + 1}", 14.5f, Th.primary, Fonts.semibold), a.dp(20), WRAP)
            row.add(a.txt(s, 14.5f, Th.text), 0, WRAP, 1f)
            card.add(row, bottom = 4)
        }
        card.add(a.txt("Less, but better.", 12.5f, Th.faint, Fonts.medium), top = 14)
        cardView = card
        add(card, bottom = 10)
        add(a.dimText("${r.wordCount()} words · made on this phone from your logs"), bottom = 14)
        val row = a.hbox()
        row.add(a.btn("Share image", icon = "share") { shareImage() }, 0, WRAP, 1f, end = 8)
        row.add(a.btn("Share text", Btn.TONAL) { a.shareText(r.asText(), "Weekly report") }, 0, WRAP, 1f)
        add(row)
    }

    private fun shareImage() {
        val v = cardView ?: return
        if (v.width == 0) return
        val bmp = Bitmap.createBitmap(v.width + a.dp(32), v.height + a.dp(32), Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        c.drawColor(Th.bg)
        c.translate(a.dp(16).toFloat(), a.dp(16).toFloat())
        v.draw(c)
        val out = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
        val name = "essential-week-${report?.weekStart ?: today}.png"
        a.shareUris(listOf(Backup.shareFile(a, name, out.toByteArray())), "image/png", "Weekly report")
    }
}

