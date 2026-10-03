package com.dosemate.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.updateAll
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.dosemate.app.MainActivity
import com.dosemate.app.R
import com.dosemate.app.alarm.DoseKey
import com.dosemate.app.data.db.AppDatabase
import com.dosemate.app.data.repo.DoseItem
import com.dosemate.app.data.repo.DoseQueries
import com.dosemate.app.data.repo.SettingsRepository
import com.dosemate.app.di.entryPoint
import com.dosemate.app.ui.theme.medicineColor
import com.dosemate.app.util.LocaleHelper
import com.dosemate.app.util.TimeFormat
import com.dosemate.core.DoseStatus
import com.dosemate.core.TimeMath
import dagger.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import javax.inject.Inject
import javax.inject.Singleton

@EntryPoint
@InstallIn(SingletonComponent::class)
interface WidgetEntryPoint {
    fun database(): AppDatabase
}

private suspend fun loadDoses(context: Context, date: LocalDate?): Pair<List<DoseItem>, DoseItem?> {
    val db = EntryPointAccessors.fromApplication(context.applicationContext, WidgetEntryPoint::class.java).database()
    val settings = SettingsRepository.read(context)
    val now = LocalDateTime.now()
    val meds = db.medicineDao().getAll()
    val logs = db.doseLogDao().between(now.minusDays(2), now.plusDays(8))
    val active = db.activeAlertDao().all()
    val today = DoseQueries.dosesOn(date ?: now.toLocalDate(), meds, logs, active, now, settings)
    val next = DoseQueries.nextDose(meds, logs, active, now, settings)
    return today to next
}

/** Refreshes both home-screen widgets after any dose change. */
@Singleton
class WidgetUpdater @Inject constructor(@ApplicationContext private val context: Context) {
    suspend fun updateAll() {
        runCatching { NextDoseWidget.update(context) }
        runCatching { TodayWidget().updateAll(context) }
    }
}

/** Small widget: next dose with a live countdown (a Chronometer counts down without updates). */
class NextDoseWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val pending = goAsync()
        context.entryPoint().scope().launch {
            try {
                update(context)
            } finally {
                pending.finish()
            }
        }
    }

    companion object {
        suspend fun update(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, NextDoseWidget::class.java))
            if (ids.isEmpty()) return
            val settings = SettingsRepository.read(context)
            val res = LocaleHelper.wrap(context, settings.language)
            val (_, next) = loadDoses(context, null)
            val views = RemoteViews(context.packageName, R.layout.widget_next_dose)
            val open = PendingIntent.getActivity(
                context, 3, Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, open)
            views.setTextViewText(R.id.widget_label, res.getString(R.string.widget_next_dose))
            if (next == null) {
                views.setTextViewText(R.id.widget_name, res.getString(R.string.widget_all_done))
                views.setTextViewText(R.id.widget_time, "")
                views.setViewVisibility(R.id.widget_countdown, View.GONE)
            } else {
                val at = next.snoozedUntil ?: next.dueAt
                val name = if (settings.hideNames) res.getString(R.string.notif_private_title) else next.med.medicine.name
                views.setTextViewText(R.id.widget_name, name)
                val dayPrefix = if (at.toLocalDate() != LocalDate.now()) TimeFormat.shortDate(at.toLocalDate()) + " · " else ""
                views.setTextViewText(R.id.widget_time, dayPrefix + TimeFormat.time(at.toLocalTime(), settings.use24h))
                val millisUntil = TimeMath.toEpochMillis(at, ZoneId.systemDefault()) - System.currentTimeMillis()
                views.setViewVisibility(R.id.widget_countdown, View.VISIBLE)
                views.setChronometer(R.id.widget_countdown, SystemClock.elapsedRealtime() + millisUntil, null, true)
                views.setChronometerCountDown(R.id.widget_countdown, true)
            }
            manager.updateAppWidget(ids, views)
        }
    }
}

private val KeyMed = ActionParameters.Key<Long>("med")
private val KeySlot = ActionParameters.Key<Long>("slot")
private val KeyAt = ActionParameters.Key<Long>("at")

/** Large widget: today's checklist; tap a dose to mark it taken. */
class TodayWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val settings = SettingsRepository.read(context)
        val res = LocaleHelper.wrap(context, settings.language)
        val (items, _) = loadDoses(context, null)
        val title = res.getString(R.string.widget_today)
        val empty = res.getString(R.string.widget_no_doses)
        val private = res.getString(R.string.notif_private_title)
        provideContent {
            GlanceTheme {
                Column(
                    GlanceModifier.fillMaxSize().background(GlanceTheme.colors.widgetBackground).cornerRadius(24.dp).padding(14.dp),
                ) {
                    Row(GlanceModifier.fillMaxWidth().clickable(actionStartActivity<MainActivity>()), verticalAlignment = Alignment.CenterVertically) {
                        Text(title, style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 16.sp, fontWeight = FontWeight.Bold), modifier = GlanceModifier.defaultWeight())
                        val done = items.count { it.status == DoseStatus.TAKEN || it.status == DoseStatus.LATE }
                        Text("$done/${items.size}", style = TextStyle(color = GlanceTheme.colors.primary, fontSize = 14.sp, fontWeight = FontWeight.Bold))
                    }
                    Spacer(GlanceModifier.height(8.dp))
                    if (items.isEmpty()) {
                        Text(empty, style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 13.sp))
                    } else {
                        LazyColumn {
                            items(items, itemId = { it.slot.id * 31 + it.scheduledAt.toLocalTime().toSecondOfDay() }) { item ->
                                DoseRow(item, settings.use24h, if (settings.hideNames) private else item.med.medicine.name)
                            }
                        }
                    }
                }
            }
        }
    }

    @androidx.compose.runtime.Composable
    private fun DoseRow(item: DoseItem, use24h: Boolean, name: String) {
        val done = item.status == DoseStatus.TAKEN || item.status == DoseStatus.LATE
        val action = actionRunCallback<MarkTakenAction>(
            actionParametersOf(
                KeyMed to item.med.medicine.id,
                KeySlot to item.slot.id,
                KeyAt to com.dosemate.app.alarm.AlarmContract.encode(item.scheduledAt),
            ),
        )
        Row(
            GlanceModifier.fillMaxWidth().padding(vertical = 5.dp).let { if (!done && item.log == null) it.clickable(action) else it },
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                GlanceModifier.size(26.dp).cornerRadius(13.dp)
                    .background(if (done) ColorProvider(Color(0xFF2FA866)) else ColorProvider(medicineColor(item.med.medicine.colorIndex).copy(alpha = 0.25f))),
                contentAlignment = Alignment.Center,
            ) {
                if (done) Image(ImageProvider(R.drawable.ic_check), null, GlanceModifier.size(16.dp))
            }
            Spacer(GlanceModifier.width(10.dp))
            Column(GlanceModifier.defaultWeight()) {
                Text(name, maxLines = 1, style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 14.sp, fontWeight = FontWeight.Medium))
                Text(
                    TimeFormat.time(item.dueAt.toLocalTime(), use24h),
                    style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 12.sp),
                )
            }
        }
    }
}

class TodayWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = TodayWidget()
}

class MarkTakenAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val med = parameters[KeyMed] ?: return
        val slot = parameters[KeySlot] ?: return
        val at = parameters[KeyAt] ?: return
        context.entryPoint().engine().markTaken(DoseKey(med, slot, com.dosemate.app.alarm.AlarmContract.decode(at)))
    }
}
