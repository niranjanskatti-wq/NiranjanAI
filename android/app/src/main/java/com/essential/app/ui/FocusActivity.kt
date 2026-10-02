package com.essential.app.ui

import android.app.Activity
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import com.essential.app.core.Days
import com.essential.app.core.Focus
import com.essential.app.core.TimeUtil
import com.essential.app.data.Repo

/** Full-screen, calm countdown. Leaving the app counts as an interruption; on return we ask why. */
class FocusActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var ring: Ring
    private lateinit var time: TextView
    private lateinit var controls: LinearLayout
    private lateinit var sub: TextView
    private var tick: Runnable? = null
    private var lastPaused: Boolean? = null

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
        val st = Focus.state(this)
        col.add(label("Focus"), WRAP, WRAP, top = 40, gravity = Gravity.CENTER_HORIZONTAL)
        col.add(txt(st?.task?.ifBlank { "Essential work" } ?: "Session complete", 22f, Th.text, Fonts.semibold, center = true), MATCH, WRAP, top = 10)
        val ringBox = FrameLayout(this)
        ring = Ring(this)
        ringBox.add(ring, dp(260), dp(260), gravity = Gravity.CENTER)
        time = txt("", 54f, Th.text, Fonts.light, center = true)
        ringBox.add(time, WRAP, WRAP, gravity = Gravity.CENTER)
        col.add(ringBox, MATCH, dp(300), top = 30)
        sub = txt("", 14f, Th.dim, center = true)
        col.add(sub, MATCH, WRAP, top = 6)
        controls = hbox().apply { gravity = Gravity.CENTER }
        col.add(controls, MATCH, WRAP, top = 36)
        root.add(scroll(col), MATCH, MATCH)
        setContentView(root)
        root.setOnApplyWindowInsetsListener { v, ins ->
            if (Build.VERSION.SDK_INT >= 30) {
                val s = ins.getInsets(WindowInsets.Type.systemBars()); v.setPadding(s.left, s.top, s.right, s.bottom)
            }
            ins
        }
        render()
    }

    private fun render() {
        val st = Focus.state(this)
        if (st == null) {
            time.text = "Done"; ring.fraction = 1f; ring.invalidate()
            sub.text = "Logged as Essential. Take a short break."
            controls.removeAllViews()
            controls.add(btn("Close") { finish() }, WRAP, WRAP)
            lastPaused = null
            return
        }
        val left = st.leftMillis()
        time.text = TimeUtil.fmtCountdown(left / 1000)
        ring.fraction = 1f - left.toFloat() / (st.planned * 60_000f)
        ring.invalidate()
        sub.text = if (st.paused) "Paused" else "${st.interruptions} interruption${if (st.interruptions == 1) "" else "s"} · until ${TimeUtil.fmtClock(TimeUtil.at(st.endAt))}"
        if (lastPaused != st.paused) {
            lastPaused = st.paused
            controls.removeAllViews()
            controls.add(btn(if (st.paused) "Resume" else "Pause", Btn.TONAL, if (st.paused) "play" else "pause") {
                if (st.paused) Focus.resume(this) else Focus.pause(this); render()
            }, WRAP, WRAP, end = 12)
            controls.add(btn("End", Btn.TEXT, color = Th.dim) {
                confirm("End this session?", "Time focused so far (if 10 minutes or more) is still logged as Essential.", "End") {
                    Focus.finish(this, false); finish()
                }
            }, WRAP, WRAP)
        }
    }

    override fun onResume() {
        super.onResume()
        val r = object : Runnable { override fun run() { render(); handler.postDelayed(this, 1000) } }
        tick = r; handler.post(r)
        val s = Repo.get(this).settings
        if (s.bool("focus_ask") && Focus.isActive(this)) {
            s.set("focus_ask", false)
            val sh = Sheet(this, "Welcome back", "What pulled you away?")
            val f = Flow(this)
            listOf("Phone", "WhatsApp", "Unplanned call", "Visitor", "Thought", "Break", "Other").forEach { reason ->
                f.addView(chip(reason, false) {
                    val repo = Repo.get(this)
                    repo.addDistraction(TimeUtil.nowMillis(), Days.today(repo), reason)
                    sh.dismiss()
                })
            }
            sh.add(f)
            sh.show()
        }
    }

    override fun onPause() { super.onPause(); tick?.let { handler.removeCallbacks(it) } }

    /** User pressed Home or switched apps (not screen-off). */
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        val st = Focus.state(this) ?: return
        if (!st.paused) { Focus.interrupted(this); Repo.get(this).settings.set("focus_ask", true) }
    }

    class Ring(ctx: Context) : View(ctx) {
        var fraction = 0f
        private val p = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE; strokeCap = Paint.Cap.ROUND }
        override fun onDraw(c: Canvas) {
            val sw = dp(10).toFloat()
            p.strokeWidth = sw
            val r = RectF(sw, sw, width - sw, height - sw)
            p.color = Th.surface2; c.drawArc(r, 0f, 360f, false, p)
            p.color = Th.primary; c.drawArc(r, -90f, 360f * fraction.coerceIn(0f, 1f), false, p)
        }
    }
}
