package com.essential.app.ui

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.media.AudioManager
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.Gravity
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import com.essential.app.core.HabitTimer
import com.essential.app.core.TimeUtil
import com.essential.app.data.Habit
import com.essential.app.data.Repo

/** Calm full-screen timer for meditation, pranayam and other minute habits. */
class HabitTimerActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var ring: FocusActivity.Ring
    private lateinit var time: TextView
    private lateinit var sub: TextView
    private lateinit var title: TextView
    private lateinit var controls: LinearLayout
    private var tick: Runnable? = null
    private var lastPaused: Boolean? = null
    private var bellsRung = -1L
    private var doneShown = false
    private var habitName = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        val repo = Repo.get(this)
        Th.dark = repo.settings.darkTheme
        setTheme(if (Th.dark) com.essential.app.R.style.Theme_Essential else com.essential.app.R.style.Theme_Essential_Light)
        super.onCreate(savedInstanceState)
        Fonts.load(this)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.statusBarColor = Color.TRANSPARENT; window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= 30) window.setDecorFitsSystemWindows(false)
        val root = FrameLayout(this).apply { setBackgroundColor(Th.bg) }
        val col = vbox().apply { gravity = Gravity.CENTER_HORIZONTAL; setPadding(dp(24), dp(24), dp(24), dp(24)) }
        habitName = HabitTimer.state(this)?.name ?: ""
        col.add(label("Timer"), WRAP, WRAP, top = 40, gravity = Gravity.CENTER_HORIZONTAL)
        title = txt(habitName, 26f, Th.text, Fonts.semibold, center = true)
        col.add(title, MATCH, WRAP, top = 10)
        val ringBox = FrameLayout(this)
        ring = FocusActivity.Ring(this)
        ringBox.add(ring, dp(260), dp(260), gravity = Gravity.CENTER)
        time = txt("", 54f, Th.text, Fonts.light, center = true)
        ringBox.add(time, WRAP, WRAP, gravity = Gravity.CENTER)
        col.add(ringBox, MATCH, dp(300), top = 30)
        sub = txt("", 14f, Th.dim, center = true)
        col.add(sub, MATCH, WRAP, top = 6)
        controls = vbox().apply { gravity = Gravity.CENTER_HORIZONTAL }
        col.add(controls, MATCH, WRAP, top = 32)
        root.add(scroll(col), MATCH, MATCH)
        setContentView(root)
        root.setOnApplyWindowInsetsListener { v, ins ->
            if (Build.VERSION.SDK_INT >= 30) { val s = ins.getInsets(WindowInsets.Type.systemBars()); v.setPadding(s.left, s.top, s.right, s.bottom) }
            ins
        }
        render()
    }

    private fun render() {
        val st = HabitTimer.state(this)
        if (st == null) { showDone(Repo.get(this).settings.int("ht_last_logged")); return }
        val now = TimeUtil.nowMillis()
        val elapsed = st.elapsedMs(now)
        if (!st.open && !st.paused && st.leftMs(now) <= 0) {
            val m = HabitTimer.finish(this, save = true, completed = true)
            bell(true); showDone(m); return
        }
        if (st.open) {
            time.text = TimeUtil.fmtCountdown(elapsed / 1000)
            ring.fraction = ((elapsed / 1000) % 60) / 60f
        } else {
            time.text = TimeUtil.fmtCountdown(st.leftMs(now) / 1000)
            ring.fraction = elapsed.toFloat() / (st.plannedMin * 60_000f)
        }
        ring.invalidate()
        val bells = if (st.intervalMin > 0) " · bell every ${st.intervalMin} min" else ""
        sub.text = when {
            st.paused -> "Paused · ${TimeUtil.fmtDuration(elapsed / 60_000)} so far"
            st.open -> "Open timer$bells"
            else -> "${st.plannedMin} min$bells"
        }
        // interval bells
        if (st.intervalMin > 0 && !st.paused) {
            val n = elapsed / (st.intervalMin * 60_000L)
            if (bellsRung < 0) bellsRung = n
            if (n > bellsRung) { bellsRung = n; bell(false) }
        }
        if (lastPaused != st.paused) {
            lastPaused = st.paused
            controls.removeAllViews()
            val r = hbox().apply { gravity = Gravity.CENTER }
            r.add(btn(if (st.paused) "Resume" else "Pause", Btn.TONAL, if (st.paused) "play" else "pause") {
                if (st.paused) HabitTimer.resume(this) else HabitTimer.pause(this); render()
            }, WRAP, WRAP, end = 12)
            r.add(btn("Finish & save") {
                val m = HabitTimer.finish(this, save = true); showDone(m)
            }, WRAP, WRAP)
            controls.add(r)
            controls.add(btn("Discard", Btn.TEXT, color = Th.dim) {
                confirm("Discard this session?", "Nothing will be logged.", "Discard", danger = true) { HabitTimer.finish(this, save = false); finish() }
            }, WRAP, WRAP, top = 8)
        }
    }

    private fun showDone(minutes: Int) {
        if (doneShown) return
        doneShown = true
        Repo.get(this).settings.set("ht_last_logged", minutes)
        tick?.let { handler.removeCallbacks(it) }
        ring.fraction = 1f; ring.invalidate()
        time.text = "Done"
        sub.text = if (minutes > 0) "$minutes min logged to $habitName" else "Under a minute — nothing logged"
        controls.removeAllViews()
        controls.add(btn("Close") { finish() }, WRAP, WRAP)
    }

    /** Soft tone for interval bells, the phone's notification sound for the final bell. Both offline. */
    private fun bell(final: Boolean) {
        try {
            if (final) RingtoneManager.getRingtone(this, RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))?.play()
            else ToneGenerator(AudioManager.STREAM_NOTIFICATION, 80).startTone(ToneGenerator.TONE_PROP_ACK, 400)
        } catch (_: Exception) { }
        try {
            getSystemService(Vibrator::class.java)?.vibrate(VibrationEffect.createOneShot(if (final) 600 else 150, VibrationEffect.DEFAULT_AMPLITUDE))
        } catch (_: Exception) { }
    }

    override fun onResume() {
        super.onResume()
        if (doneShown) return
        val r = object : Runnable { override fun run() { render(); if (!doneShown) handler.postDelayed(this, 500) } }
        tick = r; handler.post(r)
    }

    override fun onPause() { super.onPause(); tick?.let { handler.removeCallbacks(it) } }

    companion object {
        /** Choose minutes (or open-ended) and an optional interval bell, then start. */
        fun startSheet(a: MainActivity, h: Habit) {
            if (HabitTimer.isActive(a)) { a.startActivity(Intent(a, HabitTimerActivity::class.java)); return }
            val target = h.target?.toInt()?.takeIf { it > 0 } ?: 10
            var minutes = HabitTimer.lastMinutes(a, h.id, target)
            var interval = HabitTimer.lastInterval(a, h.id)
            val sh = Sheet(a, "${h.name} timer", "The minutes are logged to ${h.name} when you finish.")
            sh.add(a.label("Duration"), bottom = 6)
            val custom = a.field("Or type minutes", if (minutes > 0 && minutes !in listOf(5, 10, 15, 20, 30, 45, 60)) "$minutes" else "", numeric = true)
            val opts = (listOf(5, 10, 15, 20, 30, 45, 60) + listOfNotNull(target)).distinct().sorted().map { "$it min" } + "Open (count up)"
            val sel = if (minutes <= 0) "Open (count up)" else "$minutes min"
            sh.add(a.choice(opts, if (sel in opts) sel else null) { v ->
                minutes = if (v == "Open (count up)") 0 else v?.removeSuffix(" min")?.toIntOrNull() ?: minutes; custom.setText("")
            })
            sh.add(custom, top = 6)
            sh.add(a.label("Interval bell"), top = 4, bottom = 6)
            sh.add(a.dimText("A soft bell every few minutes — useful for rounds of pranayam."), bottom = 6)
            sh.add(a.choice(listOf("Off", "1 min", "2 min", "3 min", "5 min", "10 min"), if (interval <= 0) "Off" else "$interval min") { v ->
                interval = if (v == null || v == "Off") 0 else v.removeSuffix(" min").toInt()
            })
            sh.actions("Start") {
                custom.value.toIntOrNull()?.takeIf { it > 0 }?.let { minutes = it }
                HabitTimer.start(a, h.id, minutes, interval)
                sh.dismiss()
                a.startActivity(Intent(a, HabitTimerActivity::class.java))
            }
            sh.show()
        }
    }
}

