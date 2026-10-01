package com.essential.app

import android.app.Notification
import android.app.RemoteInput
import android.content.Intent
import android.os.Bundle
import com.essential.app.core.Days
import com.essential.app.core.Focus
import com.essential.app.core.TimeUtil
import com.essential.app.data.Plan
import com.essential.app.data.Source
import com.essential.app.data.Type
import com.essential.app.notify.ActionReceiver
import com.essential.app.notify.AlarmReceiver
import com.essential.app.notify.Alarms
import com.essential.app.notify.Notifier
import com.essential.app.notify.Planner
import com.essential.app.notify.SystemEventReceiver
import org.junit.Assert.*
import org.junit.Test
import java.time.LocalDate

/** Hourly check-ins, action buttons, inline reply, snooze, focus skipping, restart, quiet hours. */
class NotificationFlowTest : AppTestBase() {
    private val monday = LocalDate.of(2026, 10, 5)

    private fun fire() {
        val pending = alarms.scheduledAlarms.filter { it.operation != null }
        val next = pending.minByOrNull { it.triggerAtTime }!!
        at(2026, 10, 5, TimeUtil.at(next.triggerAtTime).hour, TimeUtil.at(next.triggerAtTime).minute)
        AlarmReceiver().onReceive(app, Intent(app, AlarmReceiver::class.java).setAction(Alarms.ACTION_FIRE))
        idle()
    }

    @Test fun nextAlarmIsTheTopOfTheHourCheckin() {
        onboard()
        Alarms.schedule(app)
        val next = alarms.peekNextScheduledAlarm()!!
        val t = TimeUtil.at(next.triggerAtTime)
        assertEquals(10, t.hour); assertEquals(0, t.minute)
        assertTrue("exact alarm while idle", next.allowWhileIdle)
    }

    @Test fun checkinNotificationHasOneTapActionsAndReply() {
        onboard()
        Alarms.schedule(app)
        fire() // 10:00 → "What did you do from 9 AM to 10 AM?"
        val n = notifications.getNotification(Notifier.checkinId(9))
        assertNotNull("check-in posted", n)
        assertEquals("What did you do from 9 AM to 10 AM?", n.extras.getString(Notification.EXTRA_TITLE))
        assertEquals(Notifier.CH_CHECKIN, n.channelId)
        val titles = n.actions.map { it.title.toString() }
        assertEquals(listOf("As planned", "Reply", "Snooze 10 min"), titles)
        assertNotNull("reply has RemoteInput", n.actions[1].remoteInputs?.firstOrNull())
        assertNotNull("custom big view with As planned / Essential / Trivial", n.bigContentView)
        // next alarm armed after firing
        assertTrue(alarms.scheduledAlarms.any { it.triggerAtTime > TimeUtil.nowMillis() })
    }

    @Test fun asPlannedButtonLogsScheduledBlock() {
        onboard()
        at(2026, 10, 5, 10, 0)
        ActionReceiver().onReceive(app, Intent(ActionReceiver.LOG).putExtra("date", monday.toString()).putExtra("hour", 9).putExtra("kind", "as_planned"))
        val l = repo.logFor(monday, 9)!!
        assertEquals("Essential Block 1", l.activity)
        assertEquals(Type.ESSENTIAL, l.type)
        assertEquals(Plan.YES, l.followedPlan)
        assertEquals(Source.NOTIFICATION, l.source)
    }

    @Test fun essentialAndTrivialButtons() {
        onboard()
        at(2026, 10, 5, 12, 0)
        ActionReceiver().onReceive(app, Intent(ActionReceiver.LOG).putExtra("date", monday.toString()).putExtra("hour", 11).putExtra("kind", "trivial"))
        assertEquals(Type.TRIVIAL, repo.logFor(monday, 11)!!.type)
        ActionReceiver().onReceive(app, Intent(ActionReceiver.LOG).putExtra("date", monday.toString()).putExtra("hour", 10).putExtra("kind", "essential"))
        assertEquals(Type.ESSENTIAL, repo.logFor(monday, 10)!!.type)
    }

    @Test fun inlineReplySavesActivityAndAutoCategorises() {
        onboard()
        val walkId = repo.addVenture("Fitness", 0)
        repo.saveRule(com.essential.app.data.KeywordRule(0, "walk, walked, gym", com.essential.app.data.Cat.HEALTH, walkId, null))
        at(2026, 10, 5, 12, 0)
        val i = Intent(ActionReceiver.REPLY).putExtra("date", monday.toString()).putExtra("hour", 11)
        val ri = RemoteInput.Builder(Notifier.KEY_REPLY).build()
        RemoteInput.addResultsToIntent(arrayOf(ri), i, Bundle().apply { putCharSequence(Notifier.KEY_REPLY, "Walked in the park") })
        ActionReceiver().onReceive(app, i)
        val l = repo.logFor(monday, 11)!!
        assertEquals("Walked in the park", l.activity)
        assertEquals(walkId, l.ventureId)
        assertEquals(com.essential.app.data.Cat.HEALTH, l.category)
        assertNull("notification cleared", notifications.getNotification(Notifier.checkinId(11)))
    }

    @Test fun snoozeReschedulesInTenMinutes() {
        onboard()
        at(2026, 10, 5, 10, 0)
        ActionReceiver().onReceive(app, Intent(ActionReceiver.SNOOZE).putExtra("date", monday.toString()).putExtra("hour", 9))
        val now = TimeUtil.nowMillis()
        assertTrue(alarms.scheduledAlarms.any { it.triggerAtTime == now + 10 * 60_000L })
    }

    @Test fun focusSessionSkipsCheckinAndLogsEssential() {
        onboard()
        at(2026, 10, 5, 9, 10)
        Focus.start(app, 50, "JV term sheet")
        assertTrue(Focus.isActive(app))
        assertNotNull("ongoing focus notification", notifications.getNotification(Notifier.ID_FOCUS))
        Alarms.schedule(app)
        at(2026, 10, 5, 10, 0)
        repo.settings.set("last_alarm_handled", TimeUtil.nowMillis() - 60_000)
        AlarmReceiver().onReceive(app, Intent(app, AlarmReceiver::class.java).setAction(Alarms.ACTION_FIRE))
        assertNull("check-in skipped during focus", notifications.getNotification(Notifier.checkinId(9)))
        // finish at 10:00 (50 min from 9:10)
        AlarmReceiver().onReceive(app, Intent(app, AlarmReceiver::class.java).setAction(Alarms.ACTION_FOCUS_END))
        assertFalse(Focus.isActive(app))
        val l = repo.logFor(monday, 9)!!
        assertEquals(Type.ESSENTIAL, l.type)
        assertEquals(Source.FOCUS, l.source)
        assertEquals(50, l.minutes)
        assertEquals(1, repo.focusSessions(monday, monday).count { it.completed })
    }

    @Test fun bootAndTimeChangeRescheduleAlarms() {
        onboard()
        assertTrue(alarms.scheduledAlarms.isEmpty())
        SystemEventReceiver().onReceive(app, Intent(Intent.ACTION_BOOT_COMPLETED))
        assertEquals(10, TimeUtil.at(alarms.peekNextScheduledAlarm()!!.triggerAtTime).hour)
        SystemEventReceiver().onReceive(app, Intent(Intent.ACTION_TIMEZONE_CHANGED))
        assertTrue(alarms.scheduledAlarms.isNotEmpty())
        SystemEventReceiver().onReceive(app, Intent(Intent.ACTION_MY_PACKAGE_REPLACED))
        assertTrue(alarms.scheduledAlarms.isNotEmpty())
    }

    @Test fun plannerProducesAllReminderTypes() {
        onboard()
        val ev = Planner.events(repo, TimeUtil.nowMillis(), 2)
        val kinds = ev.map { it.kind }.toSet()
        for (k in listOf(Planner.K.CHECKIN, Planner.K.BLOCK, Planner.K.REVIEW, Planner.K.WIND, Planner.K.SLEEP))
            assertTrue("has $k", k in kinds)
        val review = ev.first { it.kind == Planner.K.REVIEW && it.date == monday }
        assertEquals(21 * 60 + 30, TimeUtil.minuteOfDay(TimeUtil.at(review.at)))
        val block = ev.first { it.kind == Planner.K.BLOCK && it.blockTitle == "Break" && it.date == monday }
        assertEquals(10 * 60 + 25, TimeUtil.minuteOfDay(TimeUtil.at(block.at))) // 5 min before 10:30
        // 17 hourly check-ins on a Normal weekday (6 AM … 10 PM)
        assertEquals(17, ev.count { it.kind == Planner.K.CHECKIN && it.date == monday.plusDays(1) })
    }

    @Test fun maxModeCheckinAfterMidnightBelongsToDay() {
        onboard()
        repo.addSprint("Push", monday, monday.plusDays(13))
        Days.setMode(repo, monday, com.essential.app.data.Mode.MAX)
        val dayStart = TimeUtil.slotStart(monday, 4, repo.dayStart()).toInstant().toEpochMilli()
        val ev = Planner.events(repo, dayStart, 1).filter { it.kind == Planner.K.CHECKIN && it.date == monday }
        assertEquals(19, ev.size)
        val last = ev.maxByOrNull { it.at }!!
        assertEquals(22, last.hour) // 10–11 PM slot, asked at 11 PM
        val review = Planner.events(repo, dayStart, 1).first { it.kind == Planner.K.REVIEW && it.date == monday }
        assertEquals(22 * 60 + 45, TimeUtil.minuteOfDay(TimeUtil.at(review.at)))
    }

    @Test fun quietHoursSuppressCheckins() {
        onboard()
        repo.settings.set("quiet_enabled", true); repo.settings.set("quiet_start", 9 * 60 + 30); repo.settings.set("quiet_end", 11 * 60)
        Alarms.schedule(app)
        fire()
        assertNull(notifications.getNotification(Notifier.checkinId(9)))
    }

    @Test fun togglesDisableReminderTypes() {
        onboard()
        repo.settings.set("n_checkin", false)
        assertTrue(Planner.events(repo, TimeUtil.nowMillis()).none { it.kind == Planner.K.CHECKIN })
    }

    @Test fun testNotificationAndChannels() {
        onboard()
        Notifier.test(app)
        assertNotNull(notifications.getNotification(3999))
        val channels = notifications.notificationChannels.map { (it as android.app.NotificationChannel).id }.toSet()
        assertTrue(channels.containsAll(listOf("checkin", "block", "review", "wind_down", "sleep_log", "backup", "tools", "focus")))
    }
}
