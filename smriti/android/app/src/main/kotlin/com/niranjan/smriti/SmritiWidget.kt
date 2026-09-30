package com.niranjan.smriti

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * Shared by all Smriti home-screen widgets. Days left are worked out here
 * from the saved dates, so the countdown stays right even when Smriti
 * hasn't been opened for a while.
 */
abstract class SmritiWidgetBase : HomeWidgetProvider() {
    protected data class Item(
        val title: String,
        val label: String,
        val date: Calendar,
        val days: Int,
        val key: String = "",
        val day: String = "",
    )
    protected data class Row(val root: Int, val days: Int, val name: Int, val label: Int)

    protected abstract val layout: Int

    protected abstract fun fill(views: RemoteViews, items: List<Item>)

    /** Called before [fill] on each update, for widgets that need more saved data. */
    protected open fun prepare(context: Context, widgetData: SharedPreferences) {}

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val items = upcoming(widgetData.getString("items", null))
        prepare(context, widgetData)
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
                if (days >= 0) out.add(Item(o.optString("t"), o.optString("l"), date, days, o.optString("k"), o.getString("d")))
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

/**
 * "Today": who is celebrating today. The border shines while anyone is
 * still to be wished; tapping ✓ Done marks them wished and, once everyone
 * is done, the shine stops. Quiet when there is nothing today.
 */
class SmritiTodayWidget : SmritiWidgetBase() {
    override val layout = R.layout.smriti_widget_today

    private data class TodayRow(val root: Int, val name: Int, val label: Int, val done: Int)

    private val rows = listOf(
        TodayRow(R.id.row1, R.id.row1_name, R.id.row1_label, R.id.row1_done),
        TodayRow(R.id.row2, R.id.row2_name, R.id.row2_label, R.id.row2_done),
        TodayRow(R.id.row3, R.id.row3_name, R.id.row3_label, R.id.row3_done),
    )

    /** How the border shines, from Settings › Today widget flash. */
    private data class Glow(val color: Int, val style: String, val speed: Int, val width: String)

    private var context: Context? = null
    private var done: Set<String> = emptySet()
    private var glow = Glow(Color.parseColor("#E7B75A"), "pulse", 900, "mid")

    override fun prepare(context: Context, widgetData: SharedPreferences) {
        this.context = context
        glow = try {
            val o = JSONObject(widgetData.getString("glow", "{}") ?: "{}")
            Glow(
                Color.parseColor(o.optString("c", "#E7B75A")),
                o.optString("s", "pulse"),
                o.optInt("v", 900).coerceIn(200, 5000),
                o.optString("w", "mid"),
            )
        } catch (_: Exception) {
            Glow(Color.parseColor("#E7B75A"), "pulse", 900, "mid")
        }
        done = try {
            val arr = JSONArray(widgetData.getString("done", "[]"))
            (0 until arr.length()).map { arr.getString(it) }.toSet()
        } catch (_: Exception) {
            emptySet()
        }
    }

    private fun link(context: Context, uri: String) =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(uri))

    override fun fill(views: RemoteViews, items: List<Item>) {
        val ctx = context ?: return
        val today = items.filter { it.days == 0 }.take(3)
        var left = 0
        rows.forEachIndexed { i, row ->
            val item = today.getOrNull(i)
            if (item == null) {
                views.setViewVisibility(row.root, View.GONE)
                return@forEachIndexed
            }
            views.setViewVisibility(row.root, View.VISIBLE)
            views.setTextViewText(row.name, item.title)
            views.setTextViewText(row.label, item.label)
            val key = Uri.encode(item.key)
            views.setOnClickPendingIntent(row.name, link(ctx, "smriti://open?k=$key"))
            views.setOnClickPendingIntent(row.label, link(ctx, "smriti://open?k=$key"))
            if ("${item.key}|${item.day}" in done) {
                views.setTextViewText(row.done, "✓ Wished")
                views.setTextColor(row.done, Color.parseColor("#8FCB8F"))
                views.setInt(row.done, "setBackgroundResource", 0)
                views.setOnClickPendingIntent(row.done, link(ctx, "smriti://open?k=$key"))
            } else {
                left++
                views.setTextViewText(row.done, "✓ Done")
                views.setTextColor(row.done, Color.parseColor("#1E1C1A"))
                views.setInt(row.done, "setBackgroundResource", R.drawable.widget_done_bg)
                views.setOnClickPendingIntent(row.done, link(ctx, "smriti://done?k=$key&d=${item.day}"))
            }
        }

        val shine = left > 0
        showGlow(views, if (shine) glow.style else "off")
        views.setTextColor(R.id.status, if (shine) glow.color else Color.parseColor("#8FCB8F"))
        views.setTextViewText(
            R.id.status,
            when {
                today.isEmpty() -> ""
                shine -> if (left == 1) "1 to wish" else "$left to wish"
                else -> "All wished ✓"
            },
        )

        if (today.isEmpty()) {
            val next = items.firstOrNull()
            views.setTextViewText(
                R.id.empty,
                if (next == null) "Nothing today"
                else "Nothing today · Next: ${next.title} " + if (next.days == 1) "tomorrow" else "in ${next.days} days",
            )
            views.setViewVisibility(R.id.empty, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.empty, View.GONE)
        }
    }

    private fun showGlow(views: RemoteViews, style: String) {
        val ring = when (glow.width) {
            "thin" -> R.drawable.widget_ring_thin
            "thick" -> R.drawable.widget_ring_thick
            else -> R.drawable.widget_ring_mid
        }
        for (id in listOf(R.id.pulse_on, R.id.pulse_off, R.id.blink_on, R.id.glow_steady)) {
            views.setImageViewResource(id, ring)
            views.setInt(id, "setColorFilter", glow.color)
        }
        views.setInt(R.id.pulse_off, "setImageAlpha", 50)
        views.setInt(R.id.glow_pulse, "setFlipInterval", glow.speed)
        views.setInt(R.id.glow_blink, "setFlipInterval", glow.speed)
        views.setViewVisibility(R.id.glow_pulse, if (style == "pulse") View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.glow_blink, if (style == "blink") View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.glow_steady, if (style == "steady") View.VISIBLE else View.GONE)
    }
}
