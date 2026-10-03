package com.niranjan.deepwork

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/** Full-screen "Stay with it" screen shown when a paused app is opened during a session. */
class BlockedActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var remaining: TextView

    private val tick = object : Runnable {
        override fun run() {
            val left = BlockerState.until(this@BlockedActivity) - System.currentTimeMillis()
            if (left <= 0) {
                finish()
                return
            }
            val min = (left + 59_999) / 60_000
            remaining.text = if (min == 1L) "1 minute left in this session" else "$min minutes left in this session"
            handler.postDelayed(this, 5_000)
        }
    }

    private fun dp(v: Int) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics).toInt()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val bg = Color.parseColor("#0B0B0F")
        val accent = Color.parseColor("#7C7CFF")
        @Suppress("DEPRECATION")
        window.statusBarColor = bg
        @Suppress("DEPRECATION")
        window.navigationBarColor = bg

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(bg)
            setPadding(dp(32), dp(32), dp(32), dp(32))
        }
        root.addView(View(this).apply {
            background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setStroke(dp(6), accent) }
        }, LinearLayout.LayoutParams(dp(72), dp(72)).apply { bottomMargin = dp(28) })

        root.addView(TextView(this).apply {
            text = "Stay with it"
            setTextColor(Color.parseColor("#EDEDF2"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 28f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        })

        val label = intent.getStringExtra("label") ?: "This app"
        val task = BlockerState.task(this)
        root.addView(TextView(this).apply {
            text = "$label is paused while you focus" + if (task.isNotEmpty()) " on “$task”." else "."
            setTextColor(Color.parseColor("#8A8A99"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            gravity = Gravity.CENTER
        }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(12) })

        remaining = TextView(this).apply {
            setTextColor(accent)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            gravity = Gravity.CENTER
        }
        root.addView(remaining, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(20) })

        root.addView(Button(this).apply {
            text = "Back to Deepwork"
            isAllCaps = false
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            background = GradientDrawable().apply { setColor(accent); cornerRadius = dp(12).toFloat() }
            setOnClickListener {
                startActivity(Intent(this@BlockedActivity, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP))
                finish()
            }
        }, LinearLayout.LayoutParams(-1, dp(52)).apply { topMargin = dp(40) })

        root.addView(Button(this).apply {
            text = "Go to home screen"
            isAllCaps = false
            setTextColor(Color.parseColor("#8A8A99"))
            setBackgroundColor(Color.TRANSPARENT)
            setOnClickListener { goHome() }
        }, LinearLayout.LayoutParams(-1, dp(48)).apply { topMargin = dp(8) })

        setContentView(root)
    }

    private fun goHome() {
        startActivity(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        finish()
    }

    override fun onResume() {
        super.onResume()
        handler.post(tick)
    }

    override fun onPause() {
        super.onPause()
        handler.removeCallbacks(tick)
    }

    @Deprecated("Back should not reveal the paused app underneath.")
    override fun onBackPressed() = goHome()
}
