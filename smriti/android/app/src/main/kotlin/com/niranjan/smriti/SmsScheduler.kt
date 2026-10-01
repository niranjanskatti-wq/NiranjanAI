package com.niranjan.smriti

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject

/**
 * Sends scheduled text messages by itself. Smriti hands over the list of
 * messages (time, number, text); each gets an exact alarm. When it rings,
 * [SmsAlarmReceiver] sends the SMS, even with the phone locked or Smriti
 * closed. The list is kept so alarms come back after a restart.
 */
object SmsScheduler {
    private const val PREFS = "smriti_sms"
    private const val JOBS = "jobs"
    private const val SENT = "sent"
    private const val CHANNEL = "smriti_sms"

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun jobs(ctx: Context): JSONArray = try {
        JSONArray(prefs(ctx).getString(JOBS, "[]"))
    } catch (_: Exception) {
        JSONArray()
    }

    private fun intent(ctx: Context, id: Int): PendingIntent {
        val i = Intent(ctx, SmsAlarmReceiver::class.java).setAction("com.niranjan.smriti.SEND_SMS").putExtra("id", id)
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

    fun canSend(ctx: Context) =
        ContextCompat.checkSelfPermission(ctx, Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED

    /** Sends the message with this alarm [id], records the result and shows a notice. */
    fun fire(ctx: Context, id: Int) {
        val list = jobs(ctx)
        var job: JSONObject? = null
        val keep = JSONArray()
        for (i in 0 until list.length()) {
            val j = list.getJSONObject(i)
            if (j.getInt("id") == id) job = j else keep.put(j)
        }
        prefs(ctx).edit().putString(JOBS, keep.toString()).apply()
        val j = job ?: return
        var ok = false
        var error = ""
        if (!canSend(ctx)) {
            error = "SMS permission is off"
        } else {
            try {
                val sms = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    ctx.getSystemService(SmsManager::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    SmsManager.getDefault()
                }
                val parts = sms.divideMessage(j.getString("text"))
                if (parts.size > 1) {
                    sms.sendMultipartTextMessage(j.getString("number"), null, parts, null, null)
                } else {
                    sms.sendTextMessage(j.getString("number"), null, j.getString("text"), null, null)
                }
                ok = true
            } catch (e: Exception) {
                error = e.message ?: "Could not send"
            }
        }
        val sent = try {
            JSONArray(prefs(ctx).getString(SENT, "[]"))
        } catch (_: Exception) {
            JSONArray()
        }
        sent.put(JSONObject(j.toString()).put("ok", ok).put("error", error).put("sentAt", System.currentTimeMillis()))
        prefs(ctx).edit().putString(SENT, sent.toString()).apply()
        notify(ctx, id, j, ok, error)
    }

    /** Results since Smriti last asked, so it can mark people as wished. */
    fun drainSent(ctx: Context): String {
        val s = prefs(ctx).getString(SENT, "[]") ?: "[]"
        prefs(ctx).edit().putString(SENT, "[]").apply()
        return s
    }

    private fun notify(ctx: Context, id: Int, j: JSONObject, ok: Boolean, error: String) {
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(NotificationChannel(CHANNEL, "Auto text messages", NotificationManager.IMPORTANCE_DEFAULT))
        }
        val name = j.optString("name")
        val open = PendingIntent.getActivity(
            ctx, id, Intent(ctx, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val n = NotificationCompat.Builder(ctx, CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(if (ok) "✉️ Wish sent to $name" else "Couldn't text $name")
            .setContentText(if (ok) j.optString("text") else "$error. Open Smriti to send it yourself.")
            .setStyle(NotificationCompat.BigTextStyle().bigText(if (ok) j.optString("text") else error))
            .setContentIntent(open)
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
