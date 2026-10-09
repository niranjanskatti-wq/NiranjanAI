package com.niranjan.smriti

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
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

    /** Which text-size setting this widget follows (Settings › Widget size & flash). */
    protected abstract val sizeKey: String

    /** Every text on the widget with its normal size in sp, scaled by the setting. */
    protected abstract val texts: Map<Int, Float>

    /** Saved look: text size per widget, and the "big first date" switch. */
    protected var look = JSONObject()

    private fun scale() = when (look.optString(sizeKey, "m")) {
        "xs" -> 0.75f
        "s" -> 0.88f
        "l" -> 1.2f
        else -> 1f
    }

    /** Called before [fill] on each update, for widgets that need more saved data. */
    protected open fun prepare(context: Context, widgetData: SharedPreferences) {}

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val items = upcoming(widgetData.getString("items", null))
        look = try {
            JSONObject(widgetData.getString("look", "{}") ?: "{}")
        } catch (_: Exception) {
            JSONObject()
        }
        prepare(context, widgetData)
        val scale = scale()
        for (id in appWidgetIds) {
            try {
                appWidgetManager.updateAppWidget(id, build(context, appWidgetManager, id, items, scale, rich = true))
            } catch (_: Exception) {
                // Too big for this phone (moving pictures): show the simple version instead.
                appWidgetManager.updateAppWidget(id, build(context, appWidgetManager, id, items, scale, rich = false))
            }
        }
    }

    private fun build(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        items: List<Item>,
        scale: Float,
        rich: Boolean,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, layout)
        views.setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )
        fill(views, items)
        for ((text, sp) in texts) views.setTextViewTextSize(text, TypedValue.COMPLEX_UNIT_SP, sp * scale)
        if (rich) decorate(context, manager, id, views)
        return views
    }

    /** Extra pictures drawn for this widget's own size (the Today widget's moving effects). */
    protected open fun decorate(context: Context, manager: AppWidgetManager, id: Int, views: RemoteViews) {}

    /** Resized on the home screen: draw again at the new size. */
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        super.onAppWidgetOptionsChanged(context, manager, id, options)
        onUpdate(context, manager, intArrayOf(id), HomeWidgetPlugin.getData(context))
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
    override val sizeKey = "next"
    override val texts = mapOf(
        R.id.header to 10f,
        R.id.days to 22f,
        R.id.days_unit to 10f,
        R.id.title to 17f,
        R.id.label to 12f,
        R.id.row1_days to 12f,
        R.id.row1_name to 13f,
        R.id.row1_label to 12f,
        R.id.row2_days to 12f,
        R.id.row2_name to 13f,
        R.id.row2_label to 12f,
        R.id.row3_days to 12f,
        R.id.row3_name to 13f,
        R.id.row3_label to 12f,
        R.id.empty to 13f,
    )

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
        if (!look.optBoolean("nextBig", true)) {
            // Compact: no big first date, just the list.
            views.setViewVisibility(R.id.main, View.GONE)
            views.setViewVisibility(R.id.divider, View.GONE)
            fillRows(views, rows, items)
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
    override val sizeKey = "countdown"
    override val texts = mapOf(
        R.id.header to 9f,
        R.id.days to 44f,
        R.id.days_unit to 11f,
        R.id.title to 17f,
        R.id.label to 11f,
        R.id.empty to 12f,
    )

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
    override val sizeKey = "list"
    override val texts = mapOf(
        R.id.header to 10f,
        R.id.row1_days to 12f,
        R.id.row1_name to 13f,
        R.id.row1_label to 12f,
        R.id.row2_days to 12f,
        R.id.row2_name to 13f,
        R.id.row2_label to 12f,
        R.id.row3_days to 12f,
        R.id.row3_name to 13f,
        R.id.row3_label to 12f,
        R.id.row4_days to 12f,
        R.id.row4_name to 13f,
        R.id.row4_label to 12f,
        R.id.row5_days to 12f,
        R.id.row5_name to 13f,
        R.id.row5_label to 12f,
        R.id.row6_days to 12f,
        R.id.row6_name to 13f,
        R.id.row6_label to 12f,
        R.id.empty to 13f,
    )

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
    override val sizeKey = "today"
    override val texts = mapOf(
        R.id.header to 11f,
        R.id.status to 13f,
        R.id.row1_name to 18f,
        R.id.row1_label to 14f,
        R.id.row1_done to 14f,
        R.id.row2_name to 18f,
        R.id.row2_label to 14f,
        R.id.row2_done to 14f,
        R.id.row3_name to 18f,
        R.id.row3_label to 14f,
        R.id.row3_done to 14f,
        R.id.empty to 15f,
    )

    private data class TodayRow(val root: Int, val name: Int, val label: Int, val done: Int)

    private val rows = listOf(
        TodayRow(R.id.row1, R.id.row1_name, R.id.row1_label, R.id.row1_done),
        TodayRow(R.id.row2, R.id.row2_name, R.id.row2_label, R.id.row2_done),
        TodayRow(R.id.row3, R.id.row3_name, R.id.row3_label, R.id.row3_done),
    )

    /** How the border shines, from Settings › Today widget flash. */
    private data class Glow(val color: Int, val style: String, val speed: Int, val width: String, val natural: Boolean = false)

    private val animIds = listOf(
        R.id.anim_0, R.id.anim_1, R.id.anim_2, R.id.anim_3, R.id.anim_4, R.id.anim_5,
        R.id.anim_6, R.id.anim_7, R.id.anim_8, R.id.anim_9, R.id.anim_10, R.id.anim_11,
    )

    /** Set by [fill]: a moving effect should be drawn for this update. */
    private var animate = false

    private var context: Context? = null
    private var done: Set<String> = emptySet()
    private var glow = Glow(Color.parseColor("#E7B75A"), "pulse", 900, "mid")

    override fun prepare(context: Context, widgetData: SharedPreferences) {
        this.context = context
        glow = try {
            val o = JSONObject(widgetData.getString("glow", "{}") ?: "{}")
            val hex = o.optString("c", "#E7B75A")
            val natural = hex == "auto"
            Glow(
                Color.parseColor(if (natural) "#E7B75A" else hex),
                o.optString("s", "pulse"),
                o.optInt("v", 900).coerceIn(200, 5000),
                o.optString("w", "mid"),
                natural,
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
        animate = shine && glow.style in GlowArt.STYLES
        // A moving effect is added in decorate(); until then (or if it can't be) a pulse shows.
        showGlow(views, if (!shine) "off" else if (animate) "pulse" else glow.style)
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

    override fun decorate(context: Context, manager: AppWidgetManager, id: Int, views: RemoteViews) {
        if (!animate) {
            views.setViewVisibility(R.id.glow_anim, View.GONE)
            return
        }
        val opts = manager.getAppWidgetOptions(id)
        val wDp = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: 300
        val hDp = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 } ?: 100
        // Pixels per dp: sharp enough, but small enough for the widget's picture limit.
        val pxPerDp = minOf(context.resources.displayMetrics.density, 480f / wDp, 260f / hDp)
        val frames = GlowArt.frames(
            glow.style, (wDp * pxPerDp).toInt(), (hDp * pxPerDp).toInt(),
            if (glow.natural) null else glow.color, pxPerDp, glow.width,
        )
        frames.forEachIndexed { i, b -> views.setImageViewBitmap(animIds[i], b) }
        views.setInt(R.id.glow_anim, "setFlipInterval", (glow.speed / 8).coerceIn(60, 240))
        views.setViewVisibility(R.id.glow_anim, View.VISIBLE)
        views.setViewVisibility(R.id.glow_pulse, View.GONE)
        views.setViewVisibility(R.id.glow_blink, View.GONE)
        views.setViewVisibility(R.id.glow_steady, View.GONE)
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
        views.setViewVisibility(R.id.glow_anim, View.GONE)
    }
}
