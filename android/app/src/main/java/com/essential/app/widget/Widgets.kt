package com.essential.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.widget.RemoteViews
import com.essential.app.R
import com.essential.app.core.Days
import com.essential.app.core.Metrics
import com.essential.app.core.TimeUtil
import com.essential.app.data.Repo
import com.essential.app.notify.ActionReceiver
import com.essential.app.notify.Notifier
import com.essential.app.ui.MainActivity

/** Home-screen widgets. The countdown uses a Chronometer so it ticks without waking the app. */
object Widgets {
    fun updateAll(ctx: Context) {
        val m = AppWidgetManager.getInstance(ctx) ?: return
        try {
            m.getAppWidgetIds(ComponentName(ctx, SmallWidget::class.java)).forEach { m.updateAppWidget(it, build(ctx, false)) }
            m.getAppWidgetIds(ComponentName(ctx, MediumWidget::class.java)).forEach { m.updateAppWidget(it, build(ctx, true)) }
        } catch (_: Exception) { }
    }

    fun build(ctx: Context, medium: Boolean): RemoteViews {
        val repo = Repo.get(ctx)
        val v = RemoteViews(ctx.packageName, if (medium) R.layout.widget_medium else R.layout.widget_small)
        v.setOnClickPendingIntent(R.id.w_root, Notifier.openApp(ctx, "now", 5001))
        if (!repo.settings.bool("onboarded")) {
            v.setTextViewText(R.id.w_block, "Open Abhyasa to begin")
            return v
        }
        val now = Days.now(repo)
        val b = now.current
        v.setTextViewText(R.id.w_block, b?.title ?: "Unplanned time")
        val end = now.currentEnd?.toInstant()?.toEpochMilli()
        if (end != null) {
            val base = SystemClock.elapsedRealtime() + (end - TimeUtil.nowMillis())
            v.setChronometer(R.id.w_left, base, null, true)
            v.setChronometerCountDown(R.id.w_left, true)
        } else {
            v.setChronometer(R.id.w_left, SystemClock.elapsedRealtime(), "–", false)
        }
        if (medium) {
            val eh = Metrics.essentialHours(repo.logs(now.day.date))
            v.setTextViewText(R.id.w_eh, "${TimeUtil.fmtHours(eh)}/${TimeUtil.fmtHours(repo.settings.targetEssential(now.day.mode))}")
            v.setOnClickPendingIntent(R.id.w_planned, Notifier.action(ctx, ActionReceiver.WIDGET_AS_PLANNED, 5002))
            v.setOnClickPendingIntent(R.id.w_log, Notifier.openApp(ctx, "log_hour", 5003))
            v.setOnClickPendingIntent(R.id.w_distracted, Notifier.action(ctx, ActionReceiver.DISTRACTED, 5004))
        }
        return v
    }
}

class SmallWidget : AppWidgetProvider() {
    override fun onUpdate(ctx: Context, m: AppWidgetManager, ids: IntArray) { ids.forEach { m.updateAppWidget(it, Widgets.build(ctx, false)) } }
}

class MediumWidget : AppWidgetProvider() {
    override fun onUpdate(ctx: Context, m: AppWidgetManager, ids: IntArray) { ids.forEach { m.updateAppWidget(it, Widgets.build(ctx, true)) } }
}

/** Quick Settings tile: one tap opens the log sheet for the right hour. */
class LogHourTile : TileService() {
    override fun onStartListening() { qsTile?.let { it.state = Tile.STATE_INACTIVE; it.updateTile() } }
    override fun onClick() {
        val i = Intent(this, MainActivity::class.java).putExtra("route", "log_hour")
            .setAction("route.log_hour.tile").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        if (Build.VERSION.SDK_INT >= 34) {
            startActivityAndCollapse(PendingIntent.getActivity(this, 5010, i, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT))
        } else {
            @Suppress("DEPRECATION") startActivityAndCollapse(i)
        }
    }
}

/** Quick Settings tile: one tap logs a distraction. */
class DistractedTile : TileService() {
    override fun onStartListening() { qsTile?.let { it.state = Tile.STATE_INACTIVE; it.updateTile() } }
    override fun onClick() {
        sendBroadcast(Intent(this, ActionReceiver::class.java).setAction(ActionReceiver.DISTRACTED))
    }
}
