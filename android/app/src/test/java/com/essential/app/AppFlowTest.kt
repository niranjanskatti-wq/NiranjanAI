package com.essential.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.view.View
import com.essential.app.core.*
import com.essential.app.data.Mode
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
        assertNotNull("tab chooser", a.root.findText("Choose your tabs"))
        click(a, "Continue")
        findEdit(a.root)!!.setText("Finish my main project by 31 Dec")
        click(a, "Continue")
        assertNotNull("reminders step", a.root.findText("Reminders"))
        click(a, "Continue")
        click(a, "Start")
        assertTrue(repo.settings.bool("onboarded"))
        assertEquals("Finish my main project by 31 Dec", repo.intent()!!.title)
        assertFalse("sample data is off by default", repo.hasSampleData())
        assertNotNull("Home shows intent", a.root.findText("Finish my main project by 31 Dec"))
        assertTrue("alarms armed after onboarding", alarms.scheduledAlarms.isNotEmpty())
    }

    @Test fun setupCanBeSkippedEntirely() {
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        click(a, "Skip setup and open the app")
        assertTrue(repo.settings.bool("onboarded"))
        assertNull("no goal required", repo.intent())
        assertTrue(a.root.allText().contains("Add a main goal (optional)"))
    }

    @Test fun tabsChosenDuringSetup() {
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        click(a, "Begin")
        // turn off Now, Log, Insights and Tools: only Habits (+ Settings) remain
        for (label in listOf("Now", "Log", "Insights", "Tools")) {
            val row = a.root.findText(label)!!.parent.parent as android.view.View
            row.performClick(); idle()
        }
        click(a, "Skip setup")
        assertEquals(listOf("habits", "settings"), a.enabledTabs())
        assertTrue("opens on Habits", a.root.allText().contains("Walking"))
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
        assertTrue(home.contains("Work block")) // current block 10:45–13:00
        assertTrue(home.contains("Daily Score"))
        for (tab in MainActivity.ALL_TABS.map { it.first }) { a.selectTab(tab); idle() }
        val screens: List<Screen> = listOf(GoalsScreen(a), SprintScreen(a), TemplatesScreen(a), TemplateEditorScreen(a, repo.templates().first().id),
            VenturesScreen(a), OpportunityScreen(a), NoLogScreen(a), UncommitScreen(a), BufferScreen(a), ObstacleScreen(a), DistractionScreen(a),
            HabitsScreen(a), HabitDetailScreen(a, repo.habits().first().id), SleepScreen(a), PlayThinkScreen(a), WeeklyReportScreen(a), MissedHoursScreen(a),
            TargetsScreen(a), WeightsScreen(a), NotificationSettingsScreen(a), PermissionsScreen(a), PhoneHelpScreen(a), BackupScreen(a),
            KeywordRulesScreen(a), SprintReportScreen(a, repo.sprints().first().id))
        for (s in screens) { a.push(s); idle(); a.back(); idle() }
        // Insights computes on a background thread
        a.selectTab("insights")
        var waited = 0
        while (a.root.findText("Calculating", contains = true) != null && waited < 200) { Thread.sleep(50); idle(); waited++ }
        assertNotNull(a.root.findText("Golden Hours", contains = true) ?: a.root.findText("GOLDEN HOURS: FOCUS & ENERGY BY HOUR"))
        // Sheets
        LogHourSheet.open(a, monday, 9); idle(); assertTrue(dialogText().contains("Followed plan?") || dialogText().contains("FOLLOWED PLAN?"))
        FocusSheet.open(a); idle(); ModeSheet.open(a, monday); idle(); ReviewSheet.open(a, monday); idle()
        SleepSheet.open(a, monday); idle(); ScoreSheet.open(a, monday); idle()
        OpportunityScreen.newIdea(a); idle()
    }

    @Test fun logScreenSwipeAndLogMissed() {
        onboard()
        at(2026, 10, 5, 12, 5)
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        a.selectTab("log"); idle()
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

    @Test fun noTradingAnywhere() {
        onboard(sample = true)
        assertNull(repo.ventureByName("Trading"))
        assertTrue(repo.habits(false).none { it.name.contains("Trading") })
        assertTrue(repo.templates().flatMap { repo.blocks(it.id) }.none { it.category == "Trading" || it.title.contains("MCX") })
        assertEquals(0, repo.db.scalarL("SELECT COUNT(*) FROM sqlite_master WHERE name='trade'"))
        for (t in repo.templates()) assertEquals(1440, repo.blocks(t.id).sumOf { it.duration })
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        a.selectTab("tools"); idle()
        assertFalse(a.root.allText().contains("Trading"))
    }

    @Test fun upgradeFromV1RemovesTradingData() {
        onboard()
        val db = repo.db
        val tid = db.insert("venture", com.essential.app.data.cv("name" to "Trading", "color" to 0))
        val weekday = repo.templates().first().id
        db.insert("block", com.essential.app.data.cv("template_id" to weekday, "start_time" to 0, "end_time" to 1, "title" to "MCX trading", "category" to "Trading", "venture_id" to tid))
        db.exec("CREATE TABLE trade(id INTEGER PRIMARY KEY, pnl REAL)")
        db.insert("habit", com.essential.app.data.cv("name" to "Trading rules followed"))
        repo.settings.set("loss_limit", 5000)
        db.removeTrading()
        assertNull(repo.ventureByName("Trading"))
        assertEquals(0, db.scalarL("SELECT COUNT(*) FROM block WHERE category='Trading'"))
        assertEquals(1, db.scalarL("SELECT COUNT(*) FROM block WHERE title='Family, reading, walk' AND start_time=0"))
        assertEquals(0, db.scalarL("SELECT COUNT(*) FROM sqlite_master WHERE name='trade'"))
        assertTrue(repo.habits(false).none { it.name == "Trading rules followed" })
    }

    @Test fun backupRestoreRoundTripAndCsv() {
        onboard(sample = true)
        val logs = repo.db.scalarL("SELECT COUNT(*) FROM hour_log")
        assertTrue(logs > 150)
        val json = Backup.exportJson(app)
        repo.db.exec("DELETE FROM hour_log")
        assertEquals(0, repo.db.scalarL("SELECT COUNT(*) FROM hour_log"))
        Backup.restoreJson(app, json)
        assertEquals(logs, repo.db.scalarL("SELECT COUNT(*) FROM hour_log"))
        try { Backup.restoreJson(app, "{\"hello\":1}"); fail("should reject") } catch (e: IllegalArgumentException) { }
        val csv = Backup.csvFiles(app)
        assertEquals(setOf("hour_logs.csv", "reviews.csv", "habits.csv", "habit_amounts.csv", "books.csv", "sleep.csv"), csv.keys)
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
        assertNotNull("user's intent kept", repo.intent())
        assertEquals("templates kept", 4, repo.templates().size)
    }

    @Test fun weeklyReportIsShortAndRuleBased() {
        onboard(sample = true)
        val r = WeeklyReport.build(repo, TimeUtil.weekStart(monday).minusWeeks(1))
        assertTrue("under 200 words: ${r.wordCount()}\n${r.asText()}", r.wordCount() < 200)
        assertEquals(3, r.suggestions.size)
        assertTrue(r.sections.any { it.title == "Hours" })
        assertTrue(r.sections.none { it.title == "Trading" })
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
        a.handleRoute(Intent().putExtra("route", "new_idea")); idle()
        assertTrue(dialogText().contains("New idea"))
    }

    @Test fun habitsStreaksAndNoGuilt() {
        onboard()
        val h = repo.habits().first()
        for (i in 1..3) repo.setHabit(h.id, monday.minusDays(i.toLong() + 2), true)
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        a.selectTab("habits"); idle()
        assertTrue(a.root.allText().contains("Fresh start · best 3"))
    }

    @Test fun habitChainsAndCalendar() {
        onboard()
        val today = monday
        val done = setOf(today, today.minusDays(1), today.minusDays(2), today.minusDays(5), today.minusDays(6))
        assertEquals(3, com.essential.app.ui.screens.Chains.current(done, today))
        assertEquals(2, com.essential.app.ui.screens.Chains.current(done - today, today)) // unticked today doesn't break it yet
        assertEquals(0, com.essential.app.ui.screens.Chains.current(setOf(today.minusDays(3)), today))
        assertEquals(3, com.essential.app.ui.screens.Chains.best(done))
        // add a custom habit and tick it from the calendar
        val id = repo.addHabit("Walking 30 min", "After dinner")
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        a.push(HabitDetailScreen(a, id)); idle()
        val cal = findView(a.root) { it is com.essential.app.ui.screens.HabitCalendar } as com.essential.app.ui.screens.HabitCalendar
        cal.layout(0, 0, 700, 800)
        // tap 5 Oct 2026 (Monday) : first row is 1–4 Oct (Thu–Sun), 5 Oct is row 2, col 0
        val cellW = 700 / 7f; val head = cal.context.resources.displayMetrics.density * 24
        val x = cellW * 0.5f; val y = head + cellW * 0.9f * 1.5f
        cal.handleTouch(android.view.MotionEvent.obtain(0, 0, android.view.MotionEvent.ACTION_UP, x, y, 0))
        idle()
        assertTrue(monday in repo.habitDates(id))
        // future dates can't be ticked
        cal.handleTouch(android.view.MotionEvent.obtain(0, 0, android.view.MotionEvent.ACTION_UP, cellW * 3.5f, head + cellW * 0.9f * 2.5f, 0))
        assertEquals(1, repo.habitDates(id).size)
    }

    private fun findView(v: View, f: (View) -> Boolean): View? {
        if (f(v)) return v
        if (v is android.view.ViewGroup) for (i in 0 until v.childCount) findView(v.getChildAt(i), f)?.let { return it }
        return null
    }

    @Test fun bottomTabsCanBeHidden() {
        onboard()
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        assertEquals(listOf("now", "log", "habits", "insights", "tools", "settings"), a.enabledTabs())
        repo.settings.set("tabs", "habits,tools")
        assertEquals(listOf("habits", "tools", "settings"), a.enabledTabs())
        assertEquals("habits", a.homeTab())
        val b = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        assertTrue("opens on the first visible tab", b.root.allText().contains("Habits"))
        repo.settings.set("tabs", "")
        assertEquals(listOf("settings"), a.enabledTabs())
    }

    @Test fun noPrefilledNamesAndActivitiesAreAddable() {
        onboard()
        assertTrue("no default activities", repo.ventures(true).isEmpty())
        assertTrue(repo.rules().none { it.ventureId != null })
        assertTrue(repo.commitments().isEmpty())
        for (i in 1..25) repo.addVenture("Activity $i", 0)
        assertEquals(25, repo.ventures().size)
        assertEquals(listOf("Walking", "Meditation", "Reading", "Pranayam", "Full breathing (fast)"), repo.habits().map { it.name })
    }

    @Test fun minutesHabitTotalsAndTarget() {
        onboard()
        val walk = repo.habits().first { it.name == "Walking" }
        assertEquals(com.essential.app.data.HabitUnit.MINUTES, walk.unit); assertEquals(30.0, walk.target!!, 0.0)
        repo.logAmount(walk, monday, 20.0)
        assertTrue("any amount counts by default", monday in repo.habitDates(walk.id))
        repo.logAmount(walk, monday, 25.0)
        repo.logAmount(walk, monday.minusDays(1), 40.0)
        repo.logAmount(walk, monday.minusMonths(1), 60.0)
        val t = HabitTotals.of(repo, walk, monday)
        assertEquals(45.0, t.today, 0.0); assertEquals(45.0, t.week, 0.0) // Monday starts the week
        assertEquals(85.0, t.month, 0.0)
        assertEquals(145.0, t.all, 0.0); assertEquals(3, t.days)
        assertEquals("2h 25m", com.essential.app.data.HabitUnit.fmt(walk.unit, t.all))
        // target needed for the chain
        val strict = walk.copy(targetForChain = true)
        repo.updateHabit(strict)
        val e = repo.entries(walk.id, monday, monday).first { it.amount == 25.0 }
        repo.deleteEntry(strict, e)
        assertFalse("20 of 30 minutes isn't enough when the target is required", monday in repo.habitDates(walk.id))
        repo.logAmount(strict, monday, 10.0)
        assertTrue(monday in repo.habitDates(walk.id))
    }

    @Test fun readingPagesMoveTheBook() {
        onboard()
        val reading = repo.habits().first { it.name == "Reading" }
        assertTrue(reading.usesBooks)
        val bookId = repo.addBook("Atomic Habits", "James Clear", 320, 20)
        repo.logAmount(reading, monday, 30.0, bookId)
        var b = repo.book(bookId)!!
        assertEquals(50, b.currentPage); assertEquals(270, b.left)
        val e = repo.recentEntries(reading.id).first()
        repo.deleteEntry(reading, e)
        assertEquals(20, repo.book(bookId)!!.currentPage)
        repo.logAmount(reading, monday, 400.0, bookId)
        b = repo.book(bookId)!!
        assertEquals(320, b.currentPage); assertEquals(0, b.left); assertTrue(b.done)
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        a.push(BooksScreen(a)); idle()
        assertTrue(a.root.allText().contains("Atomic Habits"))
        a.push(HabitDetailScreen(a, reading.id)); idle()
        assertTrue(a.root.allText().contains("All time"))
        AmountSheet.open(a, reading); idle()
        assertTrue(dialogText().contains("+ Add book"))
    }

    @Test fun customUnitHabitAndOptionalTotals() {
        onboard()
        val id = repo.addHabit("Japa", "Morning", unit = "rounds", target = 1.0, showTotals = false)
        val h = repo.habit(id)!!
        repo.logAmount(h, monday, 2.0)
        assertEquals("2 rounds", com.essential.app.data.HabitUnit.fmt(h.unit, repo.amount(id, monday, monday)))
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        a.push(HabitDetailScreen(a, id)); idle()
        assertFalse("totals hidden when switched off", a.root.allText().contains("All time"))
        // plain done-only habits still work
        val plain = repo.habit(repo.addHabit("No phone first hour", null))!!
        assertFalse(plain.measured)
        repo.setHabit(plain.id, monday, true)
        assertTrue(monday in repo.habitDates(plain.id))
    }

    @Test fun sheetButtonsAlwaysVisibleOnSmallScreens() {
        onboard()
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        val h = repo.habits().first { it.name == "Reading" }
        for (open in listOf<() -> kotlin.Unit>({ HabitEditor.open(a, h) }, { HabitEditor.open(a, null) }, { LogHourSheet.open(a, monday, 9) },
                { AmountSheet.open(a, h) }, { ReviewSheet.open(a, monday) })) {
            open(); idle()
            val d = ShadowDialog.getLatestDialog()
            val decor = d.window!!.decorView
            decor.measure(android.view.View.MeasureSpec.makeMeasureSpec(1080, android.view.View.MeasureSpec.EXACTLY),
                android.view.View.MeasureSpec.makeMeasureSpec(1900, android.view.View.MeasureSpec.AT_MOST))
            decor.layout(0, 0, decor.measuredWidth, decor.measuredHeight)
            val save = decor.findText("Save") ?: decor.findText("Save review")!!
            val loc = IntArray(2); save.getLocationInWindow(loc)
            assertTrue("Save must be fully inside the sheet (bottom ${loc[1] + save.height} ≤ ${decor.measuredHeight})", loc[1] + save.height <= decor.measuredHeight)
            assertTrue(save.height > 0)
            d.dismiss(); idle()
        }
    }

    @Test fun colourSwatchesAreSmallCircles() {
        onboard()
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        HabitEditor.open(a, repo.habits().first()); idle()
        val decor = ShadowDialog.getLatestDialog().window!!.decorView
        decor.measure(android.view.View.MeasureSpec.makeMeasureSpec(1080, android.view.View.MeasureSpec.EXACTLY),
            android.view.View.MeasureSpec.makeMeasureSpec(1900, android.view.View.MeasureSpec.AT_MOST))
        decor.layout(0, 0, decor.measuredWidth, decor.measuredHeight)
        val swatch = findView(decor) { it.contentDescription == "Colour" }!!
        assertTrue("swatch width ${swatch.width}", swatch.width in 1..200)
    }

    @Test fun meditationTimerLogsMinutes() {
        onboard()
        val med = repo.habits().first { it.name == "Meditation" }
        at(2026, 10, 5, 6, 0)
        com.essential.app.core.HabitTimer.start(app, med.id, 20, 5)
        assertTrue(com.essential.app.core.HabitTimer.isActive(app))
        assertNotNull("ongoing notification", notifications.getNotification(com.essential.app.notify.Notifier.ID_HTIMER))
        assertTrue("end bell armed", alarms.scheduledAlarms.any { TimeUtil.at(it.triggerAtTime).hour == 6 && TimeUtil.at(it.triggerAtTime).minute == 20 })
        at(2026, 10, 5, 6, 5); com.essential.app.core.HabitTimer.pause(app)
        at(2026, 10, 5, 6, 9); com.essential.app.core.HabitTimer.resume(app)
        assertEquals(15 * 60_000L, com.essential.app.core.HabitTimer.state(app)!!.leftMs())
        at(2026, 10, 5, 6, 24)
        com.essential.app.notify.AlarmReceiver().onReceive(app, Intent(app, com.essential.app.notify.AlarmReceiver::class.java).setAction(com.essential.app.notify.Alarms.ACTION_HTIMER_END))
        assertFalse(com.essential.app.core.HabitTimer.isActive(app))
        assertEquals(20.0, repo.amount(med.id, monday, monday), 0.0)
        assertTrue(monday in repo.habitDates(med.id))
        // open-ended pranayam, finished early from the notification
        val pran = repo.habits().first { it.name == "Pranayam" }
        at(2026, 10, 5, 20, 0)
        com.essential.app.core.HabitTimer.start(app, pran.id, 0, 0)
        at(2026, 10, 5, 20, 12)
        com.essential.app.notify.ActionReceiver().onReceive(app, Intent(com.essential.app.notify.ActionReceiver.HT_FINISH))
        assertEquals(12.0, repo.amount(pran.id, monday, monday), 0.0)
        // timer screen opens
        com.essential.app.core.HabitTimer.start(app, med.id, 10, 0)
        val t = Robolectric.buildActivity(com.essential.app.ui.HabitTimerActivity::class.java).setup().get()
        assertTrue(t.window.decorView.allText().contains("Meditation"))
        com.essential.app.core.HabitTimer.finish(app, save = false)
    }

    @Test fun starterHabitsAddedOnceAndKeepUserHabits() {
        onboard()
        repo.deleteHabit(repo.habits().first { it.name == "Pranayam" }.id)
        repo.addHabit("Swimming", null)
        com.essential.app.data.Seed.addStarterHabits(repo.db.w)
        val names = repo.habits(false).map { it.name }
        assertEquals(1, names.count { it == "Walking" })
        assertTrue("Swimming" in names)
    }

    @Test fun upgradeFromV2RemovesOldNames() {
        onboard()
        val db = repo.db
        val re = repo.addVenture("Real Estate", 0)
        db.insert("keyword_rule", com.essential.app.data.cv("keywords" to com.essential.app.data.Seed.LEGACY_RULES[0], "category" to "Business", "venture_id" to re))
        db.insert("commitment", com.essential.app.data.cv("name" to "Free astrology Q&A group"))
        val t = repo.templates().first().id
        db.exec("UPDATE block SET title='Real estate: calls, visits, meetings', venture_id=$re WHERE template_id=$t AND title='Work block'")
        Logging.quick(app, Logging.Slot(monday, 9), Logging.AS_PLANNED, "app", "My own words")
        db.exec("UPDATE hour_log SET venture_id=$re")
        db.removeDefaultNames()
        assertNull(repo.ventureByName("Real Estate"))
        assertTrue(repo.rules().none { it.ventureId == re })
        assertTrue(repo.commitments().isEmpty())
        assertTrue(repo.blocks(t).any { it.title == "Work block" && it.ventureId == null })
        assertEquals("My own words", repo.logFor(monday, 9)!!.activity)
        assertNull(repo.logFor(monday, 9)!!.ventureId)
    }
}
