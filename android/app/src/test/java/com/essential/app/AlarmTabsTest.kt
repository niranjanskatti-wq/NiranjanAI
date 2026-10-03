package com.essential.app

import android.app.Notification
import android.content.Intent
import android.view.View
import com.essential.app.core.HabitTimer
import com.essential.app.core.TimeUtil
import com.essential.app.data.Db
import com.essential.app.data.UserAlarm
import com.essential.app.notify.ActionReceiver
import com.essential.app.notify.AlarmReceiver
import com.essential.app.notify.UserAlarms
import com.essential.app.ui.AlarmRingActivity
import com.essential.app.ui.DragList
import com.essential.app.ui.MainActivity
import com.essential.app.ui.screens.*
import org.junit.Assert.*
import org.junit.Test
import org.robolectric.Robolectric
import org.robolectric.Shadows.shadowOf
import org.robolectric.shadows.ShadowDialog
import java.time.LocalDate
import java.time.ZonedDateTime

class AlarmTabsTest : AppTestBase() {
    private fun ms(y: Int, mo: Int, d: Int, h: Int, mi: Int) = ZonedDateTime.of(y, mo, d, h, mi, 0, 0, TimeUtil.IST).toInstant().toEpochMilli()
    private fun alarm(minute: Int, days: Int = UserAlarm.EVERY_DAY, habitId: Long? = null, label: String = "", style: String = UserAlarm.STYLE_ALARM) =
        UserAlarm(0, label, minute, days, true, habitId, style, 10, true, if (days == 0) UserAlarms.onceDateFor(minute).toString() else null)

    private fun userAlarmTimes(): List<Long> = alarms.scheduledAlarms
        .filter { shadowOf(it.operation).savedIntent.action == UserAlarms.ACTION }.map { it.triggerAtTime }

    private fun fire() = AlarmReceiver().onReceive(app, Intent(UserAlarms.ACTION))

    private fun findView(v: View, f: (View) -> Boolean): View? {
        if (f(v)) return v
        if (v is android.view.ViewGroup) for (i in 0 until v.childCount) findView(v.getChildAt(i), f)?.let { return it }
        return null
    }

    @Test fun nextFireForDailyWeekdaysAndOnce() {
        // Monday 5 Oct 2026, 9:59 AM
        val now = TimeUtil.nowMillis()
        assertEquals(ms(2026, 10, 5, 22, 0), UserAlarms.nextFire(alarm(22 * 60), now))
        assertEquals("already passed today → tomorrow", ms(2026, 10, 6, 6, 0), UserAlarms.nextFire(alarm(6 * 60), now))
        assertEquals("weekends only → Saturday", ms(2026, 10, 10, 6, 0), UserAlarms.nextFire(alarm(6 * 60, UserAlarms.WEEKENDS), now))
        val once = alarm(6 * 60, days = 0)
        assertEquals(LocalDate.of(2026, 10, 6).toString(), once.onceDate)
        assertEquals(ms(2026, 10, 6, 6, 0), UserAlarms.nextFire(once, now))
        assertNull("past one-time alarm", UserAlarms.nextFire(once, ms(2026, 10, 6, 7, 0)))
        assertNull("off", UserAlarms.nextFire(alarm(22 * 60).copy(enabled = false), now))
        assertEquals("Rings in 12 h 1 min", UserAlarms.ringsIn(ms(2026, 10, 5, 22, 0)))
        assertEquals("Mon–Fri", UserAlarms.daysText(alarm(60, UserAlarms.WEEKDAYS)))
        assertEquals("Once · tomorrow", UserAlarms.daysText(once))
    }

    @Test fun manyAlarmsArmTheEarliestAsAnAlarmClock() {
        repo.saveAlarm(alarm(22 * 60, label = "Sleep"))
        repo.saveAlarm(alarm(6 * 60, label = "Pranayam"))
        repo.saveAlarm(alarm(10 * 60 + 30, label = "Walk"))
        UserAlarms.changed(app)
        assertEquals(listOf(ms(2026, 10, 5, 10, 30)), userAlarmTimes())
        assertEquals("Walk", UserAlarms.next(app)!!.first.label)
        // works even before setup is finished (no onboarding needed)
        assertFalse(repo.settings.bool("onboarded"))
    }

    @Test fun alarmRingsInsistentlyWithFullScreenAndReArms() {
        val pranayam = repo.habits().first { it.name == "Pranayam" }
        val id = repo.saveAlarm(alarm(10 * 60, habitId = pranayam.id))
        val sleep = repo.saveAlarm(alarm(22 * 60, label = "Sleep"))
        UserAlarms.changed(app)
        at(2026, 10, 5, 10, 0); fire()
        val n = notifications.getNotification((UserAlarms.ID_BASE + id).toInt())
        assertNotNull("rings", n)
        assertTrue("keeps ringing until stopped", n.flags and Notification.FLAG_INSISTENT != 0)
        assertNotNull("shows over the lock screen", n.fullScreenIntent)
        assertEquals(Notification.CATEGORY_ALARM, n.category)
        val actions = n.actions.map { it.title.toString() }
        assertEquals(listOf("Start timer", "Done", "Snooze 10 min", "Stop"), actions)
        assertEquals("Pranayam", n.extras.getString(Notification.EXTRA_TITLE))
        assertNull("sleep alarm not yet", notifications.getNotification((UserAlarms.ID_BASE + sleep).toInt()))
        assertEquals("next one armed", listOf(ms(2026, 10, 5, 22, 0)), userAlarmTimes())
        // Stop from the notification
        ActionReceiver().onReceive(app, Intent(ActionReceiver.UA_STOP).putExtra("alarm_id", id))
        assertNull(notifications.getNotification((UserAlarms.ID_BASE + id).toInt()))
    }

    @Test fun noRingForATimeThatPassedBeforeTheAlarmWasMade() {
        repo.saveAlarm(alarm(10 * 60 + 30, label = "Later"))
        UserAlarms.changed(app)
        at(2026, 10, 5, 9, 0 + 59) // unchanged clock
        at(2026, 10, 5, 9, 59)
        // add a 9:45 alarm at 9:59 — it must not ring when the 10:30 one fires
        val early = repo.saveAlarm(alarm(9 * 60 + 45, label = "Early"))
        UserAlarms.changed(app)
        at(2026, 10, 5, 10, 30); fire()
        assertNull(notifications.getNotification((UserAlarms.ID_BASE + early).toInt()))
        assertEquals(1, notifications.allNotifications.size)
    }

    @Test fun onceAlarmTurnsItselfOffAndSnoozeRingsAgain() {
        val id = repo.saveAlarm(alarm(10 * 60 + 15, days = 0, label = "Call"))
        UserAlarms.changed(app)
        at(2026, 10, 5, 10, 15); fire()
        assertFalse("one-time alarm switches off", repo.alarm(id)!!.enabled)
        ActionReceiver().onReceive(app, Intent(ActionReceiver.UA_SNOOZE).putExtra("alarm_id", id))
        assertNull("snooze stops the sound", notifications.getNotification((UserAlarms.ID_BASE + id).toInt()))
        assertEquals(listOf(ms(2026, 10, 5, 10, 25)), userAlarmTimes())
        at(2026, 10, 5, 10, 25); fire()
        assertNotNull("rings again after snooze", notifications.getNotification((UserAlarms.ID_BASE + id).toInt()))
        assertTrue(userAlarmTimes().isEmpty() || UserAlarms.next(app) == null)
    }

    @Test fun gentleReminderIsNotInsistent() {
        val walk = repo.habits().first { it.name == "Walking" }
        val id = repo.saveAlarm(alarm(10 * 60, habitId = walk.id, style = UserAlarm.STYLE_REMINDER))
        UserAlarms.changed(app)
        at(2026, 10, 5, 10, 0); fire()
        val n = notifications.getNotification((UserAlarms.ID_BASE + id).toInt())
        assertEquals(0, n.flags and Notification.FLAG_INSISTENT)
        assertNull(n.fullScreenIntent)
    }

    @Test fun doneFromAlarmLogsTheHabitTarget() {
        val pranayam = repo.habits().first { it.name == "Pranayam" }
        val id = repo.saveAlarm(alarm(10 * 60, habitId = pranayam.id))
        UserAlarms.changed(app)
        at(2026, 10, 5, 10, 0); fire()
        ActionReceiver().onReceive(app, Intent(ActionReceiver.UA_DONE).putExtra("alarm_id", id))
        val today = LocalDate.of(2026, 10, 5)
        assertTrue(pranayam.id in repo.habitDone(today))
        assertEquals(15.0, repo.amount(pranayam.id, today, today), 0.0)
        assertNull(notifications.getNotification((UserAlarms.ID_BASE + id).toInt()))
    }

    @Test fun ringScreenStartsTheTimer() {
        val pranayam = repo.habits().first { it.name == "Pranayam" }
        val id = repo.saveAlarm(alarm(10 * 60, habitId = pranayam.id))
        UserAlarms.changed(app)
        at(2026, 10, 5, 10, 0); fire()
        val act = Robolectric.buildActivity(AlarmRingActivity::class.java,
            Intent(app, AlarmRingActivity::class.java).putExtra(AlarmRingActivity.EXTRA_ID, id)).setup().get()
        val text = act.window.decorView.allText()
        assertTrue(text, text.contains("Pranayam") && text.contains("Snooze 10 min") && text.contains("Stop") && text.contains("Mark done"))
        act.window.decorView.findText("Start pranayam timer")!!.performClick(); idle()
        assertTrue(HabitTimer.isActive(app))
        assertEquals("Pranayam", HabitTimer.state(app)!!.name)
        assertNull("stopped ringing", notifications.getNotification((UserAlarms.ID_BASE + id).toInt()))
        assertEquals(com.essential.app.ui.HabitTimerActivity::class.java.name, shadowOf(act).nextStartedActivity.component!!.className)
        HabitTimer.finish(app, save = false)
    }

    @Test fun deletingAHabitDeletesItsAlarms() {
        val h = repo.habits().first()
        repo.saveAlarm(alarm(6 * 60, habitId = h.id)); repo.saveAlarm(alarm(21 * 60, habitId = h.id)); repo.saveAlarm(alarm(22 * 60, label = "Sleep"))
        assertEquals(2, repo.alarmsFor(h.id).size)
        repo.deleteHabit(h.id)
        assertEquals(listOf("Sleep"), repo.alarms().map { it.label })
    }

    @Test fun migrationAddsAlarmTable() {
        val db = Db.get(app)
        db.w.execSQL("DROP TABLE alarm")
        db.onUpgrade(db.w, 4, 5)
        assertTrue(repo.saveAlarm(alarm(60)) > 0)
        assertTrue("alarms are in backups", "alarm" in Db.TABLES)
    }

    // ------------------------------------------------------------ screens

    @Test fun alarmsPageAddAndToggle() {
        onboard()
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        a.push(AlarmsScreen(a, pushed = true)); idle()
        assertTrue(a.root.allText().contains("Quick add"))
        a.root.findText("Sleep · 10:00 PM")!!.performClick(); idle()
        val d = ShadowDialog.getLatestDialog().window!!.decorView
        assertTrue(d.allText().contains("10:00 PM"))
        d.findText("Mon–Fri")!!.performClick(); idle()
        d.findText("Save")!!.performClick(); idle()
        val x = repo.alarms().single()
        assertEquals("Sleep", x.label); assertEquals(22 * 60, x.minute); assertEquals(UserAlarms.WEEKDAYS, x.days)
        assertEquals(listOf(ms(2026, 10, 5, 22, 0)), userAlarmTimes())
        a.refresh(); idle()
        assertTrue(a.root.allText().contains("Sleep · Mon–Fri"))
        val sw = findView(a.root) { it is android.widget.Switch && it.contentDescription == "Alarm on" } as android.widget.Switch
        sw.performClick(); idle()
        assertFalse(repo.alarm(x.id)!!.enabled)
        assertTrue(userAlarmTimes().isEmpty())
    }

    @Test fun habitEditorAddsAlarmsToANewHabit() {
        onboard()
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        HabitEditor.open(a, null); idle()
        val editor = ShadowDialog.getLatestDialog()
        val ed = findView(editor.window!!.decorView) { it is android.widget.EditText } as android.widget.EditText
        ed.setText("Evening yoga")
        editor.window!!.decorView.findText("Add alarm")!!.performClick(); idle()
        val alarmSheet = ShadowDialog.getLatestDialog()
        assertNotSame(editor, alarmSheet)
        alarmSheet.window!!.decorView.findText("Save")!!.performClick(); idle()
        assertTrue(editor.window!!.decorView.allText().contains("6:00 AM"))
        editor.window!!.decorView.findText("Save")!!.performClick(); idle()
        val h = repo.habits().first { it.name == "Evening yoga" }
        assertEquals(listOf(6 * 60), repo.alarmsFor(h.id).map { it.minute })
        // the habit card shows its alarm time; the detail page lists it
        a.selectTab("habits"); idle()
        assertTrue(a.root.allText().contains("6:00 AM"))
        a.push(HabitDetailScreen(a, h.id)); idle()
        assertTrue(a.root.allText().contains("Alarms"))
    }

    @Test fun everyMainPageHasAnAlarmButton() {
        onboard()
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        for (t in listOf("now", "log", "habits", "insights", "tools", "settings")) {
            a.selectTab(t); idle()
            assertNotNull("alarm button on $t", findView(a.root) { it.contentDescription == "Alarms" })
        }
        findView(a.root) { it.contentDescription == "Alarms" }!!.performClick(); idle()
        assertTrue(a.root.allText().contains("Quick add"))
    }

    @Test fun tabsFollowYourOrder() {
        onboard()
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        assertEquals("unchanged for existing users", listOf("now", "log", "habits", "insights", "tools", "settings"), a.enabledTabs())
        repo.settings.set("tab_order", "habits,settings,now,tools")
        assertEquals("missing ids keep their place at the end", listOf("habits", "settings", "now", "tools", "log", "insights"), a.enabledTabs())
        assertEquals("habits", a.homeTab())
        repo.settings.set("tabs", "now,log,habits,alarms,insights,tools")
        assertTrue("alarms can be a tab", "alarms" in a.enabledTabs())
    }

    @Test fun dragToReorderInSettings() {
        onboard()
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        a.selectTab("settings"); idle()
        val list = findView(a.root) { it is DragList } as DragList
        assertEquals(listOf("now", "log", "habits", "alarms", "insights", "tools", "settings"), list.keys())
        list.move("habits", 0)
        assertEquals(listOf("habits", "now", "log", "insights", "tools", "settings"), a.enabledTabs())
        // a real drag on the handle: pull "insights" above "log"
        val ins = (0 until list.childCount).map { list.getChildAt(it) }.first { it.tag == "insights" }
        val handle = findView(ins) { it.contentDescription == "Drag to reorder Insights" }!!
        val rowH = 120f
        (0 until list.childCount).forEach { list.getChildAt(it).layout(0, (it * rowH).toInt(), 800, ((it + 1) * rowH).toInt()) }
        fun ev(action: Int, y: Float) = android.view.MotionEvent.obtain(0, 0, action, 10f, y, 0).also { it.setLocation(10f, y) }
        val down = ev(android.view.MotionEvent.ACTION_DOWN, 500f)
        handle.dispatchTouchEvent(down)
        var y = 500f
        repeat(10) { y -= 30f; handle.dispatchTouchEvent(ev(android.view.MotionEvent.ACTION_MOVE, y)); (0 until list.childCount).forEach { i -> list.getChildAt(i).layout(0, (i * rowH).toInt(), 800, ((i + 1) * rowH).toInt()) } }
        handle.dispatchTouchEvent(ev(android.view.MotionEvent.ACTION_UP, y))
        val order = MainActivity.tabOrder(repo.settings)
        assertTrue("insights moved up: $order", order.indexOf("insights") < order.indexOf("log"))
        // switching a tab on from the same list
        val alarmsRow = (0 until list.childCount).map { list.getChildAt(it) }.first { it.tag == "alarms" }
        alarmsRow.performClick(); idle()
        assertTrue("alarms" in a.enabledTabs())
    }

    @Test fun longPressBottomBarOpensArrangeTabs() {
        onboard()
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        val nowTab = findView(a.root) { it.contentDescription == "Now" && it.isLongClickable }!!
        nowTab.performLongClick(); idle()
        val d = ShadowDialog.getLatestDialog().window!!.decorView
        assertTrue(d.allText().contains("Arrange tabs"))
        assertNotNull(findView(d) { it is DragList })
    }
}
