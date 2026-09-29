package com.niranjan.smriti

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * Home-screen widget: the next date large, then the three after it.
 * Days left are worked out here from the saved dates, so the countdown
 * stays right even when Smriti hasn't been opened for a while.
 */
class SmritiWidget : HomeWidgetProvider() {
    private data class Item(val title: String, val label: String, val date: Calendar, val days: Int)

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val items = upcoming(widgetData.getString("items", null))
        val rows = listOf(R.id.row1, R.id.row2, R.id.row3)
        val fmt = SimpleDateFormat("EEE d MMM", Locale.getDefault())
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.smriti_widget)
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            val first = items.firstOrNull()
            if (first == null) {
                views.setViewVisibility(R.id.main, View.GONE)
                views.setViewVisibility(R.id.empty, View.VISIBLE)
                rows.forEach { views.setViewVisibility(it, View.GONE) }
            } else {
                views.setViewVisibility(R.id.main, View.VISIBLE)
                views.setViewVisibility(R.id.empty, View.GONE)
                views.setTextViewText(R.id.title, first.title)
                views.setTextViewText(R.id.label, "${first.label} · ${fmt.format(first.date.time)}")
                when (first.days) {
                    0 -> {
                        views.setTextViewText(R.id.days, "Today")
                        views.setTextViewText(R.id.days_unit, "")
                    }
                    1 -> {
                        views.setTextViewText(R.id.days, "1")
                        views.setTextViewText(R.id.days_unit, "day")
                    }
                    else -> {
                        views.setTextViewText(R.id.days, first.days.toString())
                        views.setTextViewText(R.id.days_unit, "days")
                    }
                }
                rows.forEachIndexed { i, row ->
                    val item = items.getOrNull(i + 1)
                    if (item == null) {
                        views.setViewVisibility(row, View.GONE)
                    } else {
                        views.setViewVisibility(row, View.VISIBLE)
                        views.setTextViewText(row, "${whenText(item.days)} · ${item.title} · ${item.label}")
                    }
                }
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun whenText(days: Int) = when (days) {
        0 -> "Today"
        1 -> "Tomorrow"
        else -> "In $days days"
    }

    private fun upcoming(json: String?): List<Item> {
        if (json.isNullOrEmpty()) return emptyList()
        val today = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val out = mutableListOf<Item>()
        try {
            val arr = JSONArray(json)
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                val parts = o.getString("d").split("-").map { it.toInt() }
                val date = Calendar.getInstance().apply {
                    clear()
                    set(parts[0], parts[1] - 1, parts[2])
                }
                // Half a day of slack keeps daylight-saving shifts from changing the count.
                val days = ((date.timeInMillis - today.timeInMillis + 43_200_000L) / 86_400_000L).toInt()
                if (days >= 0 && date.timeInMillis + 43_200_000L >= today.timeInMillis) {
                    out.add(Item(o.optString("t"), o.optString("l"), date, days))
                }
            }
        } catch (_: Exception) {
            return emptyList()
        }
        return out.sortedBy { it.days }
    }
}
