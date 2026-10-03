package com.niranjan.deepwork

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Focus-blocking state shared by the Flutter side, the accessibility service and the blocked screen. */
object BlockerState {
    private const val PREFS = "deepwork_blocker"

    private fun prefs(c: Context) = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun start(c: Context, until: Long, mode: String, packages: Set<String>, task: String) {
        prefs(c).edit().putLong("until", until).putString("mode", mode).putStringSet("packages", packages).putString("task", task).apply()
    }

    fun stop(c: Context) = prefs(c).edit().putLong("until", 0).apply()
    fun until(c: Context) = prefs(c).getLong("until", 0)
    fun active(c: Context) = until(c) > System.currentTimeMillis()
    fun mode(c: Context) = prefs(c).getString("mode", "block") ?: "block"
    fun packages(c: Context): Set<String> = prefs(c).getStringSet("packages", emptySet()) ?: emptySet()
    fun task(c: Context) = prefs(c).getString("task", "") ?: ""

    /** Remember an attempt to open a paused app so Flutter can log it as a distraction. */
    @Synchronized
    fun recordAttempt(c: Context, pkg: String, label: String) {
        val arr = JSONArray(prefs(c).getString("attempts", "[]"))
        if (arr.length() > 0) {
            val last = arr.getJSONObject(arr.length() - 1)
            // Collapse repeated window events for the same app.
            if (last.optString("packageName") == pkg && System.currentTimeMillis() - last.optLong("timestamp") < 15_000) return
        }
        arr.put(JSONObject().put("packageName", pkg).put("label", label).put("timestamp", System.currentTimeMillis()))
        prefs(c).edit().putString("attempts", arr.toString()).apply()
    }

    @Synchronized
    fun takeAttempts(c: Context): List<Map<String, Any>> {
        val arr = JSONArray(prefs(c).getString("attempts", "[]"))
        prefs(c).edit().putString("attempts", "[]").apply()
        return (0 until arr.length()).map {
            val o = arr.getJSONObject(it)
            mapOf("packageName" to o.optString("packageName"), "label" to o.optString("label"), "timestamp" to o.optLong("timestamp"))
        }
    }
}
