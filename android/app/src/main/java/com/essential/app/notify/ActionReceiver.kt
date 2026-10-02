package com.essential.app.notify

import android.app.RemoteInput
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.widget.Toast
import com.essential.app.core.Days
import com.essential.app.core.Focus
import com.essential.app.core.Hooks
import com.essential.app.core.Logging
import com.essential.app.core.TimeUtil
import com.essential.app.data.Repo
import com.essential.app.data.Source
import java.time.LocalDate

/** Handles notification, widget and tile actions without opening the app. */
class ActionReceiver : BroadcastReceiver() {
    companion object {
        const val LOG = "com.essential.app.LOG"
        const val REPLY = "com.essential.app.REPLY"
        const val SNOOZE = "com.essential.app.SNOOZE"
        const val FOCUS_PAUSE = "com.essential.app.FOCUS_PAUSE"
        const val FOCUS_RESUME = "com.essential.app.FOCUS_RESUME"
        const val FOCUS_STOP = "com.essential.app.FOCUS_STOP"
        const val HT_PAUSE = "com.essential.app.HT_PAUSE"
        const val HT_RESUME = "com.essential.app.HT_RESUME"
        const val HT_FINISH = "com.essential.app.HT_FINISH"
        const val DISTRACTED = "com.essential.app.DISTRACTED"
        const val WIDGET_AS_PLANNED = "com.essential.app.WIDGET_AS_PLANNED"

        fun haptic(ctx: Context) {
            if (!Repo.get(ctx).settings.bool("haptics")) return
            val v = ctx.getSystemService(Vibrator::class.java) ?: return
            if (Build.VERSION.SDK_INT >= 29) v.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK))
            else v.vibrate(VibrationEffect.createOneShot(25, VibrationEffect.DEFAULT_AMPLITUDE))
        }

        fun logDistraction(ctx: Context, reason: String? = null): Long {
            val repo = Repo.get(ctx)
            val id = repo.addDistraction(TimeUtil.nowMillis(), Days.today(repo), reason)
            Hooks.afterChange(ctx)
            return id
        }
    }

    override fun onReceive(ctx: Context, intent: Intent) {
        val date = intent.getStringExtra("date")?.let { LocalDate.parse(it) }
        val hour = intent.getIntExtra("hour", -1)
        when (intent.action) {
            LOG -> if (date != null && hour >= 0) {
                val kind = intent.getStringExtra("kind") ?: Logging.AS_PLANNED
                val l = Logging.quick(ctx, Logging.Slot(date, hour), kind, Source.NOTIFICATION)
                Notifier.cancelCheckin(ctx, hour)
                haptic(ctx)
                toast(ctx, "Logged ${TimeUtil.fmtTime(hour * 60)}: ${l.activity} · ${l.type}")
            }
            REPLY -> if (date != null && hour >= 0) {
                val text = RemoteInput.getResultsFromIntent(intent)?.getCharSequence(Notifier.KEY_REPLY)?.toString()?.trim()
                if (!text.isNullOrEmpty()) {
                    val l = Logging.quick(ctx, Logging.Slot(date, hour), "reply", Source.NOTIFICATION, text)
                    haptic(ctx)
                    toast(ctx, "Logged: ${l.activity} · ${l.type}")
                }
                Notifier.cancelCheckin(ctx, hour)
            }
            SNOOZE -> if (date != null && hour >= 0) {
                Notifier.cancelCheckin(ctx, hour)
                Alarms.snooze(ctx, date, hour)
                toast(ctx, "Reminding you in 10 minutes")
            }
            FOCUS_PAUSE -> Focus.pause(ctx)
            FOCUS_RESUME -> Focus.resume(ctx)
            FOCUS_STOP -> Focus.finish(ctx, false)
            HT_PAUSE -> com.essential.app.core.HabitTimer.pause(ctx)
            HT_RESUME -> com.essential.app.core.HabitTimer.resume(ctx)
            HT_FINISH -> { val m = com.essential.app.core.HabitTimer.finish(ctx, save = true); if (m > 0) toast(ctx, "$m min logged") }
            DISTRACTED -> { logDistraction(ctx); haptic(ctx); toast(ctx, "Distraction noted. Back to what matters.") }
            WIDGET_AS_PLANNED -> {
                val slot = Logging.targetSlot(Repo.get(ctx))
                val l = Logging.quick(ctx, slot, Logging.AS_PLANNED, Source.WIDGET)
                Notifier.cancelCheckin(ctx, slot.hour)
                haptic(ctx)
                toast(ctx, "Logged ${TimeUtil.fmtTime(slot.hour * 60)} as planned: ${l.activity}")
            }
        }
    }

    private fun toast(ctx: Context, msg: String) = Toast.makeText(ctx, msg, Toast.LENGTH_SHORT).show()
}
