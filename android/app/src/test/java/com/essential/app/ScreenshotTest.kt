package com.essential.app

import android.graphics.Bitmap
import android.graphics.Canvas
import android.view.View
import com.essential.app.core.Focus
import com.essential.app.ui.FocusActivity
import com.essential.app.ui.MainActivity
import com.essential.app.ui.Screen
import com.essential.app.ui.Th
import com.essential.app.ui.screens.*
import org.junit.Test
import org.robolectric.Robolectric
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import org.robolectric.shadows.ShadowDialog
import java.io.File
import java.io.FileOutputStream
import java.time.LocalDate

/** Renders real screens (native graphics) as PNG files in build/screens for visual review. */
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [34], qualifiers = "w400dp-h860dp-xhdpi")
class ScreenshotTest : AppTestBase() {
    private val out = File(System.getProperty("screens.dir") ?: "build/screens").apply { mkdirs() }

    private fun save(v: View, name: String, fullHeight: Boolean = true) {
        val w = v.width.takeIf { it > 0 } ?: 800
        var h = v.height.takeIf { it > 0 } ?: 1720
        if (fullHeight) {
            v.measure(View.MeasureSpec.makeMeasureSpec(w, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED))
            h = maxOf(h, v.measuredHeight)
            v.layout(0, 0, w, h)
        }
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp); c.drawColor(Th.bg); v.draw(c)
        FileOutputStream(File(out, "$name.png")).use { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }
    }

    /** Render the scrollable content of the current screen at full length. */
    private fun shoot(a: MainActivity, name: String) {
        idle()
        val content = findScrollChild(a.root) ?: a.root
        save(content, name)
    }

    private fun findScrollChild(v: View): View? {
        if (v is android.widget.ScrollView) return v.getChildAt(0)
        if (v is android.view.ViewGroup) for (i in 0 until v.childCount) findScrollChild(v.getChildAt(i))?.let { return it }
        return null
    }

    private fun push(a: MainActivity, s: Screen, name: String) { a.push(s); shoot(a, name); a.back(); idle() }

    private fun sheet(name: String) {
        idle()
        val d = ShadowDialog.getLatestDialog() ?: return
        val root = (d.window!!.decorView as android.view.ViewGroup).getChildAt(0)
        save(root, name)
        d.dismiss(); idle()
    }

    @Test fun renderScreens() {
        at(2026, 10, 1, 7, 30)
        val first = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        shoot(first, "00-onboarding")
        onboard(sample = true)
        repo.setPlanField(LocalDate.of(2026, 10, 1), "one_thing", "Send JV term sheet to Mr. Rao")
        at(2026, 10, 1, 11, 20)
        for (h in 5..10) com.essential.app.core.Logging.quick(app, com.essential.app.core.Logging.Slot(LocalDate.of(2026, 10, 1), h), "as_planned", "app")
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        shoot(a, "01-home")
        a.selectTab(1); shoot(a, "02-plan-vs-actual")
        a.selectTab(2); var n = 0
        while (a.root.findText("Calculating", true) != null && n++ < 200) { Thread.sleep(50); idle() }
        shoot(a, "03-insights")
        a.selectTab(3); shoot(a, "04-tools")
        a.selectTab(4); shoot(a, "05-settings")
        a.selectTab(3)
        push(a, TradingScreen(a), "06-trading")
        push(a, TemplateEditorScreen(a, repo.templates().first().id), "07-template-editor")
        push(a, OpportunityScreen(a), "08-opportunity")
        push(a, NoLogScreen(a), "09-no-scripts")
        push(a, HabitsScreen(a), "10-habits")
        push(a, SleepScreen(a), "11-sleep")
        push(a, WeeklyReportScreen(a), "12-weekly-report")
        push(a, GoalsScreen(a), "13-goals")
        push(a, SprintReportScreen(a, repo.sprints().first().id), "14-sprint-report")
        push(a, PhoneHelpScreen(a), "15-phone-help")
        LogHourSheet.open(a, LocalDate.of(2026, 10, 1), 10); sheet("20-log-hour-sheet")
        ModeSheet.open(a, LocalDate.of(2026, 10, 1)); sheet("21-mode-sheet")
        ScoreSheet.open(a, LocalDate.of(2026, 10, 1)); sheet("22-score-sheet")
        ReviewSheet.open(a, LocalDate.of(2026, 10, 1)); sheet("23-review-sheet")
        Focus.start(app, 50, "JV term sheet drafting")
        val f = Robolectric.buildActivity(FocusActivity::class.java).setup().get()
        idle(); save(f.window.decorView, "24-focus", fullHeight = false)
        Focus.finish(app, false)
        repo.settings.set("theme", "light"); Th.dark = false
        val l = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        shoot(l, "30-home-light")
        Th.dark = true
    }
}
