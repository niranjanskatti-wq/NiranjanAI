package com.essential.app.ui.screens

import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import com.essential.app.core.TimeUtil
import com.essential.app.data.Habit
import com.essential.app.data.UserAlarm
import com.essential.app.notify.Notifier
import com.essential.app.notify.UserAlarms
import com.essential.app.ui.*

/** Small alarm button for the top of every main page. */
fun MainActivity.alarmBtn(): View = iconBtn("alarm", Th.dim, desc = "Alarms") { push(AlarmsScreen(this, pushed = true)) }

/** All your alarms: wake up, pranayam, meditation, sleep… as many as you like. */
class AlarmsScreen(a: MainActivity, private val pushed: Boolean = false) : Screen(a) {
    override val title: String? get() = if (pushed) "Alarms" else null
    override fun actions() = listOf(a.iconBtn("plus", Th.text, desc = "Add alarm") { AlarmEditor.open(a, null) { a.refresh() } })

    override fun content(): View = page {
        if (!pushed) {
            val h = a.hbox()
            h.add(a.h1("Alarms"), 0, WRAP, 1f)
            h.add(a.iconBtn("plus", Th.text, desc = "Add alarm") { AlarmEditor.open(a, null) { a.refresh() } }, WRAP, WRAP)
            add(h, top = 8, bottom = 2)
        }
        val alarms = repo.alarms()
        val habits = repo.habits(false).associateBy { it.id }
        val next = UserAlarms.next(a)
        add(a.dimText(next?.let { (x, at) -> "Next: ${UserAlarms.title(repo, x)} at ${TimeUtil.fmtTimeFull(TimeUtil.minuteOfDay(TimeUtil.at(at)))} · ${UserAlarms.ringsIn(at).lowercase()}" }
            ?: if (alarms.isEmpty()) "Set alarms for wake-up, pranayam, meditation, sleep — anything." else "All alarms are off."), bottom = 14)

        if (!Perms.notifications(a)) add(warn("Notifications are off, so alarms can't ring. Tap to turn them on.") { Perms.fixNotifications(a) { a.refresh() } }, bottom = 12)
        else if (!Perms.fullScreen(a)) add(warn("Allow full-screen alarms so they show over the lock screen. Tap to allow.") { Perms.fixFullScreen(a) { a.refresh() } }, bottom = 12)

        if (alarms.isEmpty()) {
            val c = a.card(18)
            c.add(a.h3("Quick add"))
            c.add(a.dimText("Tap one to set it up — change the time, days and sound before saving."), top = 4, bottom = 10)
            val f = Flow(a)
            QUICK.forEach { (label, min) ->
                f.addView(a.chip("$label · ${TimeUtil.fmtTimeFull(min)}", false) {
                    val h = repo.habits(false).firstOrNull { it.name.equals(label, true) || it.name.startsWith(label, true) }
                    AlarmEditor.open(a, null, habitId = h?.id, label = if (h != null) "" else label, minute = min) { a.refresh() }
                })
            }
            c.add(f)
            add(c, bottom = 12)
        }

        alarms.forEach { x -> add(row(a, x, habits[x.habitId]) { a.refresh() }, bottom = 10) }
        add(a.btn("Add alarm", Btn.TONAL, "plus") { AlarmEditor.open(a, null) { a.refresh() } }, top = 6)
        add(a.dimText("Alarms ring with your phone's alarm sound, even in battery saver, until you stop or snooze them. " +
            "Choose \"Gentle reminder\" for a single notification sound instead."), top = 14)
    }

    private fun warn(text: String, onClick: () -> Unit): View = a.card(14, Th.alpha(Th.yellow, 0.12f)) { onClick() }.apply {
        val r = a.hbox(); r.add(a.iconView("warn", Th.yellow, 20), WRAP, WRAP, end = 10); r.add(a.txt(text, 14.5f), 0, WRAP, 1f); add(r)
    }

    companion object {
        val QUICK = listOf("Wake up" to 5 * 60, "Pranayam" to 6 * 60, "Meditation" to 6 * 60 + 30, "Walking" to 7 * 60, "Sleep" to 22 * 60)

        /** One alarm card: time, label, days, habit, and an on/off switch. */
        fun row(a: MainActivity, x: UserAlarm, habit: Habit?, compact: Boolean = false, onChange: () -> Unit): View {
            val c = a.card(if (compact) 12 else 16, if (compact) Th.surface2 else Th.surface) { AlarmEditor.open(a, x) { onChange() } }
            val r = a.hbox()
            val col = a.vbox()
            col.add(a.txt(TimeUtil.fmtTimeFull(x.minute), if (compact) 20f else 28f, if (x.enabled) Th.text else Th.faint, Fonts.light))
            val parts = listOfNotNull(x.label.takeIf { it.isNotBlank() }, habit?.takeIf { !compact }?.name?.takeIf { it != x.label }, UserAlarms.daysText(x),
                if (!x.rings) "Gentle" else null)
            col.add(a.txt(parts.joinToString(" · "), 13f, if (x.enabled) Th.dim else Th.faint, maxLines = 2), top = 2)
            UserAlarms.snoozedUntil(a, x.id)?.takeIf { it > TimeUtil.nowMillis() }?.let {
                col.add(a.txt("Snoozed until ${TimeUtil.fmtTimeFull(TimeUtil.minuteOfDay(TimeUtil.at(it)))}", 12.5f, Th.yellow), top = 2)
            }
            if (habit != null) {
                val dot = a.hbox(); dot.add(a.dot(habit.color, 8), a.dp(8), a.dp(8), end = 6)
                if (!compact) { r.add(dot, WRAP, WRAP) }
            }
            r.add(col, 0, WRAP, 1f)
            val sw = android.widget.Switch(a)
            sw.isChecked = x.enabled
            val states = arrayOf(intArrayOf(android.R.attr.state_checked), intArrayOf())
            sw.thumbTintList = android.content.res.ColorStateList(states, intArrayOf(habit?.color ?: Th.primary, Th.dim))
            sw.trackTintList = android.content.res.ColorStateList(states, intArrayOf(Th.alpha(habit?.color ?: Th.primary, 0.45f), Th.surface3))
            sw.contentDescription = "Alarm on"
            sw.setOnCheckedChangeListener { v, on ->
                v.haptic()
                var y = x.copy(enabled = on)
                if (on && y.once && (UserAlarms.nextFire(y, TimeUtil.nowMillis()) == null)) y = y.copy(onceDate = UserAlarms.onceDateFor(y.minute).toString())
                a.repo.saveAlarm(y)
                if (!on) { UserAlarms.clearSnooze(a, x.id); UserAlarms.stop(a, x.id) }
                UserAlarms.changed(a)
                if (on) UserAlarms.nextFire(y, TimeUtil.nowMillis())?.let { a.toast(UserAlarms.ringsIn(it)) }
                onChange()
            }
            r.add(sw, WRAP, WRAP, start = 8)
            c.add(r)
            return c
        }
    }
}

/** Add or edit one alarm. With [persist] false (a habit not saved yet) the alarm is handed back instead of saved. */
object AlarmEditor {
    fun open(a: MainActivity, x: UserAlarm?, habitId: Long? = x?.habitId, label: String = "", minute: Int? = null,
             lockHabit: Boolean = false, persist: Boolean = true, onSaved: (UserAlarm?) -> Unit) {
        val repo = a.repo
        var min = x?.minute ?: minute ?: 6 * 60
        var days = x?.days ?: UserAlarm.EVERY_DAY
        var hid = habitId
        var style = x?.style ?: UserAlarm.STYLE_ALARM
        var snooze = x?.snoozeMin ?: 10
        var vibrate = x?.vibrate ?: true
        val sh = Sheet(a, if (x == null) "New alarm" else "Edit alarm")

        val time = a.txt(TimeUtil.fmtTimeFull(min), 44f, Th.primary, Fonts.light, center = true)
        time.background = ripple(rounded(Th.surface2, a.dp(18).toFloat()), a.dp(18).toFloat())
        time.setPadding(0, a.dp(10), 0, a.dp(10))
        time.contentDescription = "Alarm time"
        time.click(true) { a.pickTime("Alarm time", min) { m -> min = m; time.text = TimeUtil.fmtTimeFull(m) } }
        sh.add(time)
        sh.add(a.dimText("Tap the time to change it").apply { gravity = Gravity.CENTER_HORIZONTAL }, top = -6)

        val name = a.field("Label (optional), e.g. Sleep, Wake up", x?.label ?: label)
        sh.add(name)

        sh.add(a.label("Repeat"), bottom = 6)
        val dayRow = a.hbox()
        val presets = a.vbox()
        fun renderDays() {
            dayRow.removeAllViews()
            for (i in 0..6) {
                val on = days and (1 shl i) != 0
                val t = a.txt(UserAlarms.DAY_SHORT[i], 14f, if (on) Th.onPrimary else Th.dim, Fonts.medium, center = true)
                t.gravity = Gravity.CENTER
                val r = a.dp(20).toFloat()
                t.background = ripple(if (on) rounded(Th.primary, r) else rounded(Color.TRANSPARENT, r, a.dp(1), Th.outline), r)
                t.contentDescription = UserAlarms.DAY_NAMES[i]
                t.click(true) { days = days xor (1 shl i); renderDays() }
                dayRow.add(t, 0, a.dp(40), 1f, start = if (i == 0) 0 else 4)
            }
            presets.removeAllViews()
            val sel = when (days) { UserAlarm.EVERY_DAY -> "Every day"; UserAlarms.WEEKDAYS -> "Mon–Fri"; UserAlarms.WEEKENDS -> "Sat–Sun"; 0 -> "Once"; else -> null }
            presets.add(a.choice(listOf("Every day", "Mon–Fri", "Sat–Sun", "Once"), sel) { v ->
                days = when (v) { "Mon–Fri" -> UserAlarms.WEEKDAYS; "Sat–Sun" -> UserAlarms.WEEKENDS; "Once" -> 0; else -> UserAlarm.EVERY_DAY }
                renderDays()
            }, top = 8)
        }
        renderDays()
        sh.add(dayRow, bottom = 0)
        sh.add(presets)

        val habits = repo.habits(false)
        if (habits.isNotEmpty() && !lockHabit) {
            sh.add(a.label("For a habit · optional"), bottom = 6)
            sh.add(a.dimText("Linked alarms show the habit, with Done and (for minutes) Start timer buttons."), bottom = 6)
            sh.add(a.choice(habits.map { it.name }, habits.firstOrNull { it.id == hid }?.name, allowNone = true) { v ->
                hid = habits.firstOrNull { it.name == v }?.id
            })
        }

        sh.add(a.label("Sound"), bottom = 6)
        val styles = listOf("Ring until stopped" to UserAlarm.STYLE_ALARM, "Gentle reminder" to UserAlarm.STYLE_REMINDER)
        sh.add(a.choice(styles.map { it.first }, styles.first { it.second == style }.first) { v -> style = styles.firstOrNull { it.first == v }?.second ?: style })
        sh.add(a.label("Snooze"), bottom = 6)
        sh.add(a.choice(listOf("5 min", "10 min", "15 min", "20 min", "30 min"), "$snooze min") { v -> snooze = v?.removeSuffix(" min")?.toIntOrNull() ?: snooze })
        sh.add(a.switchRow("Vibrate", null, vibrate) { vibrate = it })

        if (x != null && x.id != 0L) sh.add(a.btn("Delete alarm", Btn.TEXT, "trash", color = Th.red) {
            if (persist) { repo.deleteAlarm(x.id); UserAlarms.clearSnooze(a, x.id); UserAlarms.stop(a, x.id); UserAlarms.changed(a) }
            sh.dismiss(); onSaved(null)
        })
        sh.actions("Save") {
            val y = UserAlarm(x?.id ?: 0, name.value.trim(), min, days, true, hid, style, snooze, vibrate,
                if (days == 0) UserAlarms.onceDateFor(min).toString() else null)
            if (persist) {
                val id = repo.saveAlarm(y)
                if (x != null) UserAlarms.clearSnooze(a, id)
                UserAlarms.changed(a)
                UserAlarms.nextFire(y, TimeUtil.nowMillis())?.let { a.toast(UserAlarms.ringsIn(it)) }
                sh.dismiss(); onSaved(y.copy(id = id))
            } else { sh.dismiss(); onSaved(y) }
        }
        sh.show()
    }
}

/** The "Alarms" block inside a habit's editor or detail page. */
object HabitAlarms {
    /** Lists the habit's alarms with an Add button. For a habit not saved yet, alarms are kept in [pending]. */
    fun section(a: MainActivity, habitId: Long?, pending: MutableList<UserAlarm>? = null, compact: Boolean = true): LinearLayout {
        val box = a.vbox()
        fun render() {
            box.removeAllViews()
            val list = if (habitId != null) a.repo.alarmsFor(habitId) else pending.orEmpty()
            val habit = habitId?.let { a.repo.habit(it) }
            if (list.isEmpty()) box.add(a.dimText("No alarm yet. Add one to be reminded at the right time — or several, e.g. morning and night."), bottom = 8)
            list.forEachIndexed { i, x ->
                if (habitId != null) box.add(AlarmsScreen.row(a, x, habit, compact) { render() }, bottom = 8)
                else {
                    val r = a.listRow(TimeUtil.fmtTimeFull(x.minute), UserAlarms.daysText(x), "alarm", Th.primary) {
                        AlarmEditor.open(a, x, lockHabit = true, persist = false) { y -> if (y == null) pending!!.removeAt(i) else pending!![i] = y; render() }
                    }
                    box.add(r)
                }
            }
            box.add(a.btn("Add alarm", Btn.TONAL, "alarm", color = habit?.color ?: Th.primary) {
                AlarmEditor.open(a, null, habitId = habitId, lockHabit = true, persist = habitId != null,
                    minute = list.lastOrNull()?.minute?.let { (it + 12 * 60) % (24 * 60) }) { y ->
                    if (habitId == null && y != null) pending?.add(y)
                    render()
                }
            }, WRAP, WRAP)
        }
        render()
        return box
    }
}

/** Full-screen alarms over the lock screen need this on Android 14+. */
fun Perms.fullScreen(ctx: android.content.Context): Boolean = Build.VERSION.SDK_INT < 34 || Notifier.nm(ctx).canUseFullScreenIntent()

fun Perms.fixFullScreen(a: MainActivity, done: () -> Unit) {
    if (Build.VERSION.SDK_INT >= 34) {
        val i = Intent(android.provider.Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, Uri.parse("package:${a.packageName}"))
        a.startForResult(i) { _, _ -> done() }
    } else done()
}

/** Choose and arrange the bottom tabs: drag ≡ to reorder, switch to show or hide. */
object TabsSheet {
    val DESC = mapOf("now" to "Current block, ONE thing, score", "log" to "Plan vs actual, hour by hour", "habits" to "Daily habit chains and calendars",
        "alarms" to "Wake-up, pranayam, sleep alarms", "insights" to "Charts and weekly report", "tools" to "Goals, focus, sleep, reviews…",
        "settings" to "Always shown, so tabs can be turned back on")

    fun list(a: MainActivity): DragList {
        val s = a.repo.settings
        val on = s.str("tabs").split(',').map { it.trim() }.toMutableSet()
        val labels = MainActivity.ALL_TABS.toMap()
        val list = DragList(a) { order -> s.set("tab_order", order.joinToString(",")); a.renderNav() }
        MainActivity.tabOrder(s).forEach { id ->
            val row = a.hbox().apply { setPadding(0, a.dp(6), 0, a.dp(6)) }
            val handle = a.iconView("drag", Th.dim, 22).apply { contentDescription = "Drag to reorder ${labels[id]}"; setPadding(a.dp(10), a.dp(10), a.dp(10), a.dp(10)) }
            row.add(handle, a.dp(44), a.dp(44), end = 4)
            row.add(a.iconView(MainActivity.ICONS[id]!!, Th.dim, 20), a.dp(24), a.dp(24), end = 12)
            val col = a.vbox()
            col.add(a.txt(labels[id]!!, 15.5f))
            col.add(a.dimText(DESC[id]), top = 2)
            row.add(col, 0, WRAP, 1f)
            if (id != "settings") {
                val sw = android.widget.Switch(a)
                sw.isChecked = id in on
                val states = arrayOf(intArrayOf(android.R.attr.state_checked), intArrayOf())
                sw.thumbTintList = android.content.res.ColorStateList(states, intArrayOf(Th.primary, Th.dim))
                sw.trackTintList = android.content.res.ColorStateList(states, intArrayOf(Th.alpha(Th.primary, 0.45f), Th.surface3))
                sw.contentDescription = "Show ${labels[id]}"
                sw.setOnCheckedChangeListener { v, b ->
                    v.haptic(); if (b) on.add(id) else on.remove(id)
                    s.set("tabs", MainActivity.ALL_TABS.map { t -> t.first }.filter { t -> t in on }.joinToString(","))
                    a.renderNav()
                }
                row.add(sw, WRAP, WRAP, start = 8)
                row.click { sw.toggle() }
            }
            list.addRow(id, row, handle)
        }
        return list
    }

    fun open(a: MainActivity) {
        val sh = Sheet(a, "Arrange tabs", "Drag ≡ to put your most used tab first. The first tab opens when the app starts.")
        sh.add(list(a))
        sh.footer.add(a.btn("Done") { sh.dismiss() }, top = 10)
        sh.onDismiss { a.refresh() }
        sh.show()
    }
}
