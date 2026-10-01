package com.niranjan.smriti

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject

/**
 * Scheduled text messages. Smriti hands over the list (time, number, text);
 * each gets an exact alarm. When it rings, [SmsAlarmReceiver] shows a
 * notification that opens the Messages app with the number and wish already
 * typed, so sending is one tap. Smriti never sends an SMS by itself (that
 * needs the SEND_SMS permission, which Play Protect blocks for apps installed
 * outside the Play Store). The list is kept so alarms come back after a restart.
 */
object SmsScheduler {
    private const val PREFS = "smriti_sms"
    private const val JOBS = "jobs"
    private const val SENT = "sent"
    private const val CHANNEL = "smriti_sms_prompt"

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun jobs(ctx: Context): JSONArray = try {
        JSONArray(prefs(ctx).getString(JOBS, "[]"))
    } catch (_: Exception) {
        JSONArray()
    }

    private fun intent(ctx: Context, id: Int): PendingIntent {
        val i = Intent(ctx, SmsAlarmReceiver::class.java).setAction("com.niranjan.smriti.SMS_DUE").putExtra("id", id)
        return PendingIntent.getBroadcast(
            ctx, id, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** Replaces every scheduled message with [json] (a list of {id, at, number, text, name, label…}). */
    fun schedule(ctx: Context, json: String) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val old = jobs(ctx)
        for (i in 0 until old.length()) am.cancel(intent(ctx, old.getJSONObject(i).getInt("id")))
        val next = JSONArray(json)
        prefs(ctx).edit().putString(JOBS, next.toString()).apply()
        arm(ctx, next)
    }

    /** Sets the alarms again (after a restart or update). */
    fun rearm(ctx: Context) = arm(ctx, jobs(ctx))

    private fun arm(ctx: Context, list: JSONArray) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val now = System.currentTimeMillis()
        for (i in 0 until list.length()) {
            val j = list.getJSONObject(i)
            val at = j.getLong("at")
            if (at <= now) continue
            val pi = intent(ctx, j.getInt("id"))
            val exact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) am.canScheduleExactAlarms() else true
            if (exact) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
            } else {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
            }
        }
    }

    /** Shows the "tap to send" notice for the message with this alarm [id]. */
    fun fire(ctx: Context, id: Int) {
        val list = jobs(ctx)
        var job: JSONObject? = null
        val keep = JSONArray()
        for (i in 0 until list.length()) {
            val j = list.getJSONObject(i)
            if (j.getInt("id") == id) job = j else keep.put(j)
        }
        prefs(ctx).edit().putString(JOBS, keep.toString()).apply()
        notify(ctx, id, job ?: return)
    }

    /** Nothing is sent by Smriti itself, so there is nothing to report. */
    fun drainSent(@Suppress("UNUSED_PARAMETER") ctx: Context): String = "[]"

    private fun notify(ctx: Context, id: Int, j: JSONObject) {
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL, "Scheduled text messages", NotificationManager.IMPORTANCE_HIGH).apply {
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 400, 200, 400)
                },
            )
        }
        val name = j.optString("name")
        val text = j.optString("text")
        val compose = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:" + j.optString("number")))
            .putExtra("sms_body", text)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val send = PendingIntent.getActivity(
            ctx, id, compose, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val n = NotificationCompat.Builder(ctx, CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("✉️ Time to wish $name: tap to send")
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setContentIntent(send)
            .addAction(0, "Send SMS", send)
            .setAutoCancel(true)
            .build()
        try {
            nm.notify(900000 + (id and 0xFFFF), n)
        } catch (_: SecurityException) {
        }
    }
}

class SmsAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra("id", -1)
        if (id != -1) SmsScheduler.fire(context, id)
    }
}

/** Puts the alarms back after the phone restarts or Smriti is updated. */
class SmsBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        SmsScheduler.rearm(context)
    }
}
