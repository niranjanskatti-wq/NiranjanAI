package com.niranjan.deepwork;

import android.content.Context;
import android.content.SharedPreferences;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.HashSet;
import java.util.Set;

/** Focus-blocking state shared between the plugin, the accessibility service and the blocked screen. */
final class BlockerState {
    private static final String PREFS = "deepwork_blocker";

    private BlockerState() {}

    private static SharedPreferences prefs(Context c) {
        return c.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    static void start(Context c, long until, String mode, Set<String> packages, String taskTitle) {
        prefs(c).edit()
            .putLong("until", until)
            .putString("mode", mode)
            .putStringSet("packages", new HashSet<>(packages))
            .putString("task", taskTitle == null ? "" : taskTitle)
            .apply();
    }

    static void stop(Context c) {
        prefs(c).edit().putLong("until", 0).apply();
    }

    static long until(Context c) {
        return prefs(c).getLong("until", 0);
    }

    static boolean active(Context c) {
        return until(c) > System.currentTimeMillis();
    }

    static String mode(Context c) {
        return prefs(c).getString("mode", "block");
    }

    static Set<String> packages(Context c) {
        return prefs(c).getStringSet("packages", new HashSet<>());
    }

    static String task(Context c) {
        return prefs(c).getString("task", "");
    }

    /** Remember an attempt to open a blocked app so the web app can log it as a distraction. */
    static synchronized void recordAttempt(Context c, String pkg, String label) {
        try {
            JSONArray arr = new JSONArray(prefs(c).getString("attempts", "[]"));
            // Collapse repeated events for the same app within a few seconds.
            if (arr.length() > 0) {
                JSONObject last = arr.getJSONObject(arr.length() - 1);
                if (pkg.equals(last.optString("packageName")) && System.currentTimeMillis() - last.optLong("timestamp") < 15000) return;
            }
            JSONObject o = new JSONObject();
            o.put("packageName", pkg);
            o.put("label", label);
            o.put("timestamp", System.currentTimeMillis());
            arr.put(o);
            prefs(c).edit().putString("attempts", arr.toString()).apply();
        } catch (Exception ignored) {
        }
    }

    static synchronized JSONArray takeAttempts(Context c) {
        try {
            JSONArray arr = new JSONArray(prefs(c).getString("attempts", "[]"));
            prefs(c).edit().putString("attempts", "[]").apply();
            return arr;
        } catch (Exception e) {
            return new JSONArray();
        }
    }
}
