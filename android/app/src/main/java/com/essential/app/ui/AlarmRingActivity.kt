package com.essential.app.ui

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.Toast
import com.essential.app.core.HabitTimer
import com.essential.app.core.TimeUtil
import com.essential.app.data.HabitUnit
import com.essential.app.data.Repo
import com.essential.app.notify.UserAlarms

/** Full-screen alarm (also over the lock screen): Stop, Snooze, and for habits Start timer / Mark done. */
class AlarmRingActivity : Activity() {
    companion object {
        const val EXTRA_ID = "alarm_id"
        const val EXTRA_START_TIMER = "start_timer"
        /** Notifications are off, so this screen plays the alarm sound itself. */
        const val EXTRA_SELF_SOUND = "self_sound"
    }

    private val handler = Handler(Looper.getMainLooper())
    private var tone: Ringtone? = null
    private var alarmId = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        val repo = Repo.get(this)
        Th.dark = repo.settings.darkTheme
        setTheme(if (Th.dark) com.essential.app.R.style.Theme_Essential else com.essential.app.R.style.Theme_Essential_Light)
        super.onCreate(savedInstanceState)
        Fonts.load(this)
        setShowWhenLocked(true); setTurnScreenOn(true)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.statusBarColor = Color.TRANSPARENT; window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= 30) window.setDecorFitsSystemWindows(false)
        handle(intent)
    }

    override fun onNewIntent(intent: Intent) { super.onNewIntent(intent); setIntent(intent); handle(intent) }

    private fun handle(i: Intent) {
        val repo = Repo.get(this)
        alarmId = i.getLongExtra(EXTRA_ID, 0)
        val x = repo.alarm(alarmId)
        if (x == null) { finish(); return }
        val habit = x.habitId?.let { repo.habit(it) }
        if (i.getBooleanExtra(EXTRA_START_TIMER, false) && habit != null) { startTimer(habit.id, habit.target); return }
        if (i.getBooleanExtra(EXTRA_SELF_SOUND, false) && tone == null) playSelf()

        val root = FrameLayout(this).apply { setBackgroundColor(Th.bg) }
        val col = vbox().apply { gravity = Gravity.CENTER_HORIZONTAL; setPadding(dp(24), dp(24), dp(24), dp(24)) }
        col.add(iconView("alarm", habit?.color ?: Th.primary, 44), dp(56), dp(56), top = 48, gravity = Gravity.CENTER_HORIZONTAL)
        val now = TimeUtil.now()
        col.add(txt(TimeUtil.fmtTimeFull(TimeUtil.minuteOfDay(now)), 60f, Th.text, Fonts.light, center = true), MATCH, WRAP, top = 12)
        col.add(txt(UserAlarms.title(repo, x), 26f, Th.text, Fonts.semibold, center = true), MATCH, WRAP, top = 8)
        habit?.let { col.add(txt(UserAlarms.habitLine(repo, it), 15f, Th.dim, center = true), MATCH, WRAP, top = 6) }
        val buttons = vbox()
        if (habit != null) {
            if (habit.unit == HabitUnit.MINUTES) buttons.add(btn("Start ${habit.name.lowercase()} timer", icon = "timer", color = habit.color) {
                startTimer(habit.id, habit.target)
            }, MATCH, WRAP, bottom = 10)
            buttons.add(btn("Mark done", Btn.TONAL, "check", color = habit.color) {
                stopAll(); UserAlarms.markHabitDone(this, habit.id)
                Toast.makeText(this, "${habit.name} done today ✓", Toast.LENGTH_SHORT).show(); finish()
            }, MATCH, WRAP, bottom = 10)
        }
        val pair = hbox()
        pair.add(btn("Snooze ${x.snoozeMin} min", Btn.TONAL) {
            stopAll(); val at = UserAlarms.snooze(this, x.id)
            Toast.makeText(this, "Snoozed until ${TimeUtil.fmtTimeFull(TimeUtil.minuteOfDay(TimeUtil.at(at)))}", Toast.LENGTH_SHORT).show(); finish()
        }, 0, WRAP, 1f, end = 10)
        pair.add(btn("Stop", if (habit == null) Btn.FILLED else Btn.TONAL, "stop") { stopAll(); finish() }, 0, WRAP, 1f)
        buttons.add(pair)
        col.add(buttons, MATCH, WRAP, top = 48)
        root.add(scroll(col), MATCH, MATCH)
        setContentView(root)
        root.setOnApplyWindowInsetsListener { v, ins ->
            if (Build.VERSION.SDK_INT >= 30) { val s = ins.getInsets(WindowInsets.Type.systemBars()); v.setPadding(s.left, s.top, s.right, s.bottom) }
            ins
        }
        // Like the notification, stop by itself after 10 minutes.
        handler.removeCallbacksAndMessages(null)
        handler.postDelayed({ stopAll(); finish() }, 10 * 60_000L)
    }

    private fun startTimer(habitId: Long, target: Double?) {
        stopAll()
        val t = target?.toInt()?.takeIf { it > 0 } ?: 10
        if (!HabitTimer.isActive(this)) HabitTimer.start(this, habitId, HabitTimer.lastMinutes(this, habitId, t), HabitTimer.lastInterval(this, habitId))
        startActivity(Intent(this, HabitTimerActivity::class.java))
        finish()
    }

    private fun playSelf() {
        try {
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM) ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            tone = RingtoneManager.getRingtone(this, uri)?.apply {
                audioAttributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build()
                if (Build.VERSION.SDK_INT >= 28) isLooping = true
                play()
            }
        } catch (_: Exception) { }
    }

    private fun stopAll() {
        try { tone?.stop() } catch (_: Exception) { }
        tone = null
        UserAlarms.stop(this, alarmId)
        handler.removeCallbacksAndMessages(null)
    }

    override fun onDestroy() { try { tone?.stop() } catch (_: Exception) { }; handler.removeCallbacksAndMessages(null); super.onDestroy() }
}
