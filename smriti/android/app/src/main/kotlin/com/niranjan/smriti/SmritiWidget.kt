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
 * Shared by all Smriti home-screen widgets. Days left are worked out here
 * from the saved dates, so the countdown stays right even when Smriti
 * hasn't been opened for a while.
 */
abstract class SmritiWidgetBase : HomeWidgetProvider() {
    protected data class Item(val title: String, val label: String, val date: Calendar, val days: Int)
    protected data class Row(val root: Int, val days: Int, val name: Int, val label: Int)

    protected abstract val layout: Int

    protected abstract fun fill(views: RemoteViews, items: List<Item>)

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val items = upcoming(widgetData.getString("items", null))
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, layout)
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            fill(views, items)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    protected val dateFormat = SimpleDateFormat("EEE d MMM", Locale.getDefault())

    /** "Today", "Tomorrow" or "9 days", for the column on the left of each row. */
    protected fun daysShort(days: Int) = when (days) {
        0 -> "Today"
        1 -> "Tomorrow"
        else -> "$days days"
    }

    /** Big number and the word under it. */
    protected fun setBigDays(views: RemoteViews, days: Int) {
        when (days) {
            0 -> {
                views.setTextViewText(R.id.days, "🎉")
                views.setTextViewText(R.id.days_unit, "Today")
            }
            else -> {
                views.setTextViewText(R.id.days, days.toString())
                views.setTextViewText(R.id.days_unit, if (days == 1) "day" else "days")
            }
        }
    }

    protected fun fillRows(views: RemoteViews, rows: List<Row>, items: List<Item>) {
        rows.forEachIndexed { i, row ->
            val item = items.getOrNull(i)
            if (item == null) {
                views.setViewVisibility(row.root, View.GONE)
            } else {
                views.setViewVisibility(row.root, View.VISIBLE)
                views.setTextViewText(row.days, daysShort(item.days))
                views.setTextViewText(row.name, item.title)
                views.setTextViewText(row.label, item.label)
            }
        }
    }

    protected fun showEmpty(views: RemoteViews, empty: Boolean, vararg hide: Int) {
        views.setViewVisibility(R.id.empty, if (empty) View.VISIBLE else View.GONE)
        for (id in hide) views.setViewVisibility(id, if (empty) View.GONE else View.VISIBLE)
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
                if (days >= 0) out.add(Item(o.optString("t"), o.optString("l"), date, days))
            }
        } catch (_: Exception) {
            return emptyList()
        }
        return out.sortedBy { it.days }
    }
}

/** "Next up": the next date with its countdown right beside the name, and three more below. */
class SmritiWidget : SmritiWidgetBase() {
    override val layout = R.layout.smriti_widget

    private val rows = listOf(
        Row(R.id.row1, R.id.row1_days, R.id.row1_name, R.id.row1_label),
        Row(R.id.row2, R.id.row2_days, R.id.row2_name, R.id.row2_label),
        Row(R.id.row3, R.id.row3_days, R.id.row3_name, R.id.row3_label),
    )

    override fun fill(views: RemoteViews, items: List<Item>) {
        val first = items.firstOrNull()
        showEmpty(views, first == null, R.id.main, R.id.divider)
        if (first == null) {
            fillRows(views, rows, emptyList())
            return
        }
        setBigDays(views, first.days)
        views.setTextViewText(R.id.title, first.title)
        views.setTextViewText(R.id.label, "${first.label}\n${dateFormat.format(first.date.time)}")
        val rest = items.drop(1)
        views.setViewVisibility(R.id.divider, if (rest.isEmpty()) View.GONE else View.VISIBLE)
        fillRows(views, rows, rest)
    }
}

/** "Countdown": one big number with the name and occasion under it. */
class SmritiCountdownWidget : SmritiWidgetBase() {
    override val layout = R.layout.smriti_widget_countdown

    override fun fill(views: RemoteViews, items: List<Item>) {
        val first = items.firstOrNull()
        showEmpty(views, first == null, R.id.main)
        if (first == null) return
        setBigDays(views, first.days)
        views.setTextViewText(R.id.title, first.title)
        views.setTextViewText(R.id.label, first.label)
    }
}

/** "Coming up": the next six dates, each as days · name · occasion. */
class SmritiListWidget : SmritiWidgetBase() {
    override val layout = R.layout.smriti_widget_list

    private val rows = listOf(
        Row(R.id.row1, R.id.row1_days, R.id.row1_name, R.id.row1_label),
        Row(R.id.row2, R.id.row2_days, R.id.row2_name, R.id.row2_label),
        Row(R.id.row3, R.id.row3_days, R.id.row3_name, R.id.row3_label),
        Row(R.id.row4, R.id.row4_days, R.id.row4_name, R.id.row4_label),
        Row(R.id.row5, R.id.row5_days, R.id.row5_name, R.id.row5_label),
        Row(R.id.row6, R.id.row6_days, R.id.row6_name, R.id.row6_label),
    )

    override fun fill(views: RemoteViews, items: List<Item>) {
        showEmpty(views, items.isEmpty())
        fillRows(views, rows, items)
    }
}
