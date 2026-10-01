package com.essential.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.view.View
import com.essential.app.core.*
import com.essential.app.data.Mode
import com.essential.app.data.Trade
import com.essential.app.ui.FocusActivity
import com.essential.app.ui.MainActivity
import com.essential.app.ui.Screen
import com.essential.app.ui.screens.*
import com.essential.app.widget.DistractedTile
import com.essential.app.widget.MediumWidget
import com.essential.app.widget.SmallWidget
import com.essential.app.widget.Widgets
import org.junit.Assert.*
import org.junit.Test
import org.robolectric.Robolectric
import org.robolectric.Shadows.shadowOf
import org.robolectric.shadows.ShadowDialog
import java.time.LocalDate

/** End-to-end flows through the real UI and data layer. */
class AppFlowTest : AppTestBase() {
    private val monday = LocalDate.of(2026, 10, 5)

    private fun click(a: MainActivity, text: String, contains: Boolean = false) {
        val v = a.root.findText(text, contains) ?: error("No view with text \"$text\" in:\n" + a.root.allText())
        v.performClick(); idle()
    }

    private fun dialogText(): String = ShadowDialog.getLatestDialog()?.window?.decorView?.allText() ?: ""

    @Test fun firstLaunchOnboardingThroughTheUi() {
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        assertNotNull(a.root.findText("Less, but better."))
        click(a, "Begin")
        val field = a.root.findText("", false).let { findEdit(a.root)!! }
        field.setText("Close 3 JV real estate deals by 31 Dec")
        click(a, "Set my intent")
        assertNotNull("permissions step", a.root.findText("Reliable reminders"))
        assertNotNull(a.root.findText("Notifications"))
        click(a, "Continue")
        click(a, "Start")
        assertTrue(repo.settings.bool("onboarded"))
        assertEquals("Close 3 JV real estate deals by 31 Dec", repo.intent()!!.title)
        assertTrue("sample data loaded", repo.hasSampleData())
        assertNotNull("Home shows intent", a.root.findText("Close 3 JV real estate deals by 31 Dec"))
        assertNotNull(a.root.findText("Essential Hours today", contains = true) ?: a.root.findText("ESSENTIAL HOURS TODAY"))
        assertTrue("alarms armed after onboarding", alarms.scheduledAlarms.isNotEmpty())
    }

    private fun findEdit(v: View): android.widget.EditText? {
        if (v is android.widget.EditText) return v
        if (v is android.view.ViewGroup) for (i in 0 until v.childCount) findEdit(v.getChildAt(i))?.let { return it }
        return null
    }

    @Test fun everyScreenRendersWithSampleData() {
        onboard(sample = true)
        at(2026, 10, 5, 11, 20)
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        val home = a.root.allText()
        assertTrue(home.contains("Real estate: calls, visits, meetings")) // current block 10:45–13:00
        assertTrue(home.contains("Daily Score"))
        for (tab in 0..4) { a.selectTab(tab); idle() }
        val screens: List<Screen> = listOf(GoalsScreen(a), SprintScreen(a), TemplatesScreen(a), TemplateEditorScreen(a, repo.templates().first().id),
            VenturesScreen(a), OpportunityScreen(a), NoLogScreen(a), UncommitScreen(a), BufferScreen(a), ObstacleScreen(a), DistractionScreen(a),
            HabitsScreen(a), SleepScreen(a), PlayThinkScreen(a), TradingScreen(a), WeeklyReportScreen(a), MissedHoursScreen(a),
            TargetsScreen(a), WeightsScreen(a), NotificationSettingsScreen(a), PermissionsScreen(a), PhoneHelpScreen(a), BackupScreen(a),
            KeywordRulesScreen(a), SprintReportScreen(a, repo.sprints().first().id))
        for (s in screens) { a.push(s); idle(); a.back(); idle() }
        // Insights computes on a background thread
        a.selectTab(2)
        var waited = 0
        while (a.root.findText("Calculating", contains = true) != null && waited < 200) { Thread.sleep(50); idle(); waited++ }
        assertNotNull(a.root.findText("Golden Hours", contains = true) ?: a.root.findText("GOLDEN HOURS: FOCUS & ENERGY BY HOUR"))
        // Sheets
        LogHourSheet.open(a, monday, 9); idle(); assertTrue(dialogText().contains("Followed plan?") || dialogText().contains("FOLLOWED PLAN?"))
        FocusSheet.open(a); idle(); ModeSheet.open(a, monday); idle(); ReviewSheet.open(a, monday); idle()
        SleepSheet.open(a, monday); idle(); ScoreSheet.open(a, monday); idle()
        OpportunityScreen.newIdea(a); idle(); TradingScreen.startTrade(a); idle()
    }

    @Test fun logScreenSwipeAndLogMissed() {
        onboard()
        at(2026, 10, 5, 12, 5)
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        a.selectTab(1); idle()
        assertTrue(a.root.allText().contains("Log 7 missed hours")) // 5,6,7,8,9,10,11
        a.push(MissedHoursScreen(a)); idle()
        click(a, "All as planned")
        assertEquals(7, repo.logs(monday).size)
        assertEquals(0, Logging.missing(repo, Days.resolve(repo, monday)).size)
    }

    @Test fun sameAsLastHourCopiesPrevious() {
        onboard()
        at(2026, 10, 5, 11, 0)
        Logging.quick(app, Logging.Slot(monday, 9), Logging.AS_PLANNED, "app", "Drafting JV term sheet")
        val copy = Logging.sameAsLast(app, Logging.Slot(monday, 10), "app")!!
        assertEquals("Drafting JV term sheet", repo.logFor(monday, 10)!!.activity)
        assertEquals(copy.type, repo.logFor(monday, 9)!!.type)
    }

    @Test fun modeSwitchingAndSprintLifecycle() {
        onboard()
        assertNotNull("Max requires a sprint", Days.setMode(repo, monday, Mode.MAX))
        assertEquals(Mode.NORMAL, Days.resolve(repo, monday).mode)
        val id = repo.addSprint("Sign 2 JV term sheets", monday, monday.plusDays(13))
        assertNull(Days.setMode(repo, monday, Mode.MAX))
        val d = Days.resolve(repo, monday)
        assertEquals(Mode.MAX, d.mode); assertEquals("Sprint Day", d.template?.name)
        assertEquals("Sprint days default to Max", Mode.MAX, Days.resolve(repo, monday.plusDays(1)).mode)
        assertEquals("Sunday keeps its template", "Sunday", Days.resolve(repo, monday.plusDays(6)).template?.name)
        // sprint ends → recovery week in Normal Mode
        val after = monday.plusDays(14)
        repo.closeFinishedSprints(after)
        assertEquals("done", repo.sprint(id)!!.status)
        val rd = Days.resolve(repo, after)
        assertEquals(Mode.NORMAL, rd.mode); assertNotNull(rd.recovery)
        assertNotNull("Max blocked during recovery", Days.setMode(repo, after, Mode.MAX))
        assertNull("recovery ends after a week", Days.resolve(repo, monday.plusDays(21)).recovery)
        val report = Insights.sprintReport(repo, repo.sprint(id)!!)
        assertNotNull(report)
    }

    @Test fun sprintMaxSixWeeks() {
        onboard()
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        SprintScreen.newSprint(a); idle()
        assertTrue(dialogText().contains("at most 6 weeks"))
    }

    @Test fun burnoutWarning() {
        onboard()
        for (i in 0..2) repo.saveSleep(com.essential.app.data.SleepLog(monday.minusDays(i.toLong()), 23 * 60 + 30, 4 * 60 + 30, 2))
        val b = Insights.burnout(repo, monday)
        assertNotNull(b); assertTrue(b!!.reasons.first().startsWith("Sleep"))
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        assertTrue(a.root.allText().contains("Your body may need a lighter day"))
    }

    @Test fun revengeTradeGuard() {
        onboard()
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        assertNull(TradingScreen.guardReason(a))
        repeat(2) { repo.addTrade(Trade(0, monday, TimeUtil.nowMillis() + it, "Crude", "Long", 6100.0, 6080.0, 100.0, -2000.0, true, "Calm", true, null)) }
        assertNotNull(TradingScreen.guardReason(a))
        TradingScreen.startTrade(a); idle()
        val d = ShadowDialog.getLatestDialog()
        assertTrue(d.window!!.decorView.allText().contains("Stop trading for today"))
        assertFalse(shadowOf(d).isCancelable)
    }

    @Test fun lossLimitTriggersGuard() {
        onboard()
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        repo.addTrade(Trade(0, monday, TimeUtil.nowMillis(), "Gold", "Short", 71000.0, 71500.0, 25.0, -12500.0, false, "Revenge", false, null))
        assertTrue(TradingScreen.guardReason(a)!!.contains("loss limit"))
    }

    @Test fun backupRestoreRoundTripAndCsv() {
        onboard(sample = true)
        val logs = repo.db.scalarL("SELECT COUNT(*) FROM hour_log")
        val trades = repo.db.scalarL("SELECT COUNT(*) FROM trade")
        assertTrue(logs > 150); assertTrue(trades > 5)
        val json = Backup.exportJson(app)
        repo.db.exec("DELETE FROM hour_log"); repo.db.exec("DELETE FROM trade")
        assertEquals(0, repo.db.scalarL("SELECT COUNT(*) FROM hour_log"))
        Backup.restoreJson(app, json)
        assertEquals(logs, repo.db.scalarL("SELECT COUNT(*) FROM hour_log"))
        assertEquals(trades, repo.db.scalarL("SELECT COUNT(*) FROM trade"))
        try { Backup.restoreJson(app, "{\"hello\":1}"); fail("should reject") } catch (e: IllegalArgumentException) { }
        val csv = Backup.csvFiles(app)
        assertEquals(setOf("hour_logs.csv", "trades.csv", "reviews.csv", "habits.csv", "sleep.csv"), csv.keys)
        val hl = String(csv["hour_logs.csv"]!!).lines()
        assertTrue(hl[0].startsWith("date,hour,minutes,activity,category,venture,type,focus,energy"))
        assertTrue(hl.size > 150)
        val exp = Backup.export(app)
        assertNotNull(exp.share)
    }

    @Test fun sampleDataCanBeCleared() {
        onboard(sample = true)
        assertTrue(repo.hasSampleData())
        val days = repo.db.scalarL("SELECT COUNT(DISTINCT date) FROM hour_log")
        assertEquals(14, days)
        assertTrue(repo.db.scalarL("SELECT COUNT(DISTINCT mode) FROM day_plan") == 2L)
        Logging.quick(app, Logging.Slot(monday, 9), Logging.ESSENTIAL, "app", "My real work")
        repo.clearSampleData()
        assertFalse(repo.hasSampleData())
        assertEquals(1, repo.db.scalarL("SELECT COUNT(*) FROM hour_log"))
        assertEquals(0, repo.db.scalarL("SELECT COUNT(*) FROM trade"))
        assertNotNull("user's intent kept", repo.intent())
        assertEquals("templates kept", 4, repo.templates().size)
    }

    @Test fun weeklyReportIsShortAndRuleBased() {
        onboard(sample = true)
        val r = WeeklyReport.build(repo, TimeUtil.weekStart(monday).minusWeeks(1))
        assertTrue("under 200 words: ${r.wordCount()}\n${r.asText()}", r.wordCount() < 200)
        assertEquals(3, r.suggestions.size)
        assertTrue(r.sections.any { it.title == "Hours" })
        assertTrue(r.sections.any { it.title == "Trading" })
        assertTrue(r.asText().contains("vs last week"))
    }

    @Test fun dailyScoreLive() {
        onboard()
        at(2026, 10, 5, 12, 0)
        val before = Metrics.dayScore(repo, monday).total
        for (h in 7..10) Logging.quick(app, Logging.Slot(monday, h), Logging.AS_PLANNED, "app")
        repo.setPlanField(monday, "one_thing", "Send JV term sheet"); repo.setPlanField(monday, "one_done", true)
        val after = Metrics.dayScore(repo, monday)
        assertTrue(after.total > before)
        assertEquals(6, after.parts.size)
    }

    @Test fun opportunityBelow90GoesToNotNow() {
        onboard()
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        a.push(OpportunityScreen(a)); idle()
        OpportunityScreen.newIdea(a); idle()
        val dv = ShadowDialog.getLatestDialog().window!!.decorView
        val edits = ArrayList<android.widget.EditText>()
        fun walk(v: View) { if (v is android.widget.EditText) edits.add(v); if (v is android.view.ViewGroup) for (i in 0 until v.childCount) walk(v.getChildAt(i)) }
        walk(dv)
        edits[0].setText("Crypto course"); edits[1].setText("MCX prep time")
        dv.findText("Decide")!!.performClick(); idle()
        val o = repo.opportunities().first()
        assertEquals("Not Now", o.decision); assertEquals(50, o.total)
        assertNotNull(o.reviewDate)
    }

    @Test fun widgetsAndTiles() {
        onboard()
        at(2026, 10, 5, 11, 20)
        assertNotNull(Widgets.build(app, false)); assertNotNull(Widgets.build(app, true))
        val mgr = AppWidgetManager.getInstance(app)
        val sm = shadowOf(mgr)
        sm.createWidget(SmallWidget::class.java, com.essential.app.R.layout.widget_small)
        sm.createWidget(MediumWidget::class.java, com.essential.app.R.layout.widget_medium)
        Widgets.updateAll(app)
        assertEquals(1, mgr.getAppWidgetIds(ComponentName(app, MediumWidget::class.java)).size)
        // Widget "As planned" logs the last finished hour (10–11 AM; mostly Essential Block 1)
        com.essential.app.notify.ActionReceiver().onReceive(app, Intent(com.essential.app.notify.ActionReceiver.WIDGET_AS_PLANNED))
        assertEquals("Essential Block 1", repo.logFor(monday, 10)!!.activity)
        idle()
        // Distracted tile
        val tile = Robolectric.setupService(DistractedTile::class.java)
        tile.onClick()
        shadowOf(app).broadcastIntents.lastOrNull()?.let { com.essential.app.notify.ActionReceiver().onReceive(app, it) }
        assertEquals(1, repo.distractions(monday, monday).size)
    }

    @Test fun focusActivityShowsCountdown() {
        onboard()
        Focus.start(app, 25, "Deal structuring")
        val f = Robolectric.buildActivity(FocusActivity::class.java).setup().get()
        val text = f.window.decorView.allText()
        assertTrue(text.contains("Deal structuring"))
        assertTrue(text.contains("25:00") || text.contains("24:59"))
        Focus.finish(app, false)
    }

    @Test fun deepLinksFromShortcuts() {
        onboard()
        val a = Robolectric.buildActivity(MainActivity::class.java, Intent().setAction("com.essential.app.shortcut.log_hour")).setup().get()
        idle()
        assertTrue(dialogText().contains("Followed plan?") || dialogText().contains("FOLLOWED PLAN?"))
        a.handleRoute(Intent().putExtra("route", "log_trade")); idle()
        assertTrue(dialogText().contains("Pre-trade checklist"))
    }

    @Test fun habitsStreaksAndNoGuilt() {
        onboard()
        val h = repo.habits().first()
        for (i in 1..3) repo.setHabit(h.id, monday.minusDays(i.toLong() + 2), true)
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        a.push(HabitsScreen(a)); idle()
        assertTrue(a.root.allText().contains("Fresh start today · best 3"))
    }
}
