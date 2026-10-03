package com.dosemate.app.ui.insights

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.LocalFireDepartment
import androidx.compose.material.icons.rounded.PictureAsPdf
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.dosemate.app.R
import com.dosemate.app.data.db.ActiveAlertDao
import com.dosemate.app.data.db.MedicineEntity
import com.dosemate.app.data.repo.DoseQueries
import com.dosemate.app.data.repo.LogRepository
import com.dosemate.app.data.repo.MedicineRepository
import com.dosemate.app.data.repo.SettingsRepository
import com.dosemate.app.ui.components.AppCard
import com.dosemate.app.ui.components.EmptyState
import com.dosemate.app.ui.components.GradientBackground
import com.dosemate.app.ui.components.ProgressRing
import com.dosemate.app.ui.components.SectionHeader
import com.dosemate.app.ui.theme.LocalSettings
import com.dosemate.app.ui.theme.StatusColors
import com.dosemate.app.ui.theme.medicineColor
import com.dosemate.app.ui.today.periodLabel
import com.dosemate.app.util.TimeFormat
import com.dosemate.core.Adherence
import com.dosemate.core.DayPeriod
import com.dosemate.core.DoseOutcome
import com.dosemate.core.Streaks
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import javax.inject.Inject

data class InsightsState(
    val days: Int = 30,
    val overall: Int? = null,
    val streaks: Streaks = Streaks(0, 0),
    val perMedicine: List<Pair<MedicineEntity, Int?>> = emptyList(),
    val daily: List<Pair<LocalDate, Int?>> = emptyList(),
    val mostMissed: List<Pair<LocalTime, Int>> = emptyList(),
    val byPeriod: Map<DayPeriod, Int> = emptyMap(),
    val counts: Map<String, Int> = emptyMap(),
    val loaded: Boolean = false,
)

@HiltViewModel
class InsightsViewModel @Inject constructor(
    medicines: MedicineRepository,
    logs: LogRepository,
    alerts: ActiveAlertDao,
    settingsRepo: SettingsRepository,
) : ViewModel() {
    val range = MutableStateFlow(30)

    val state: StateFlow<InsightsState> = combine(
        medicines.medicines, logs.observeAll(), alerts.observeAll(), settingsRepo.settings, range,
    ) { meds, logList, active, settings, days ->
        val now = LocalDateTime.now()
        val today = now.toLocalDate()
        val outcomesByDay = (0 until maxOf(days, 90)).map { offset ->
            val date = today.minusDays(offset.toLong())
            date to DoseQueries.dosesOn(date, meds, logList, active, now, settings)
                .map { DoseOutcome(it.med.medicine.id, it.slot.id, it.scheduledAt, it.status) }
        }.reversed()
        val window = outcomesByDay.takeLast(days)
        val windowOutcomes = window.flatMap { it.second }
        val streakMap = outcomesByDay.associate { (date, list) -> date to Adherence.dayAdherence(list) }
        InsightsState(
            days = days,
            overall = Adherence.percent(windowOutcomes),
            streaks = Adherence.streaks(streakMap, today),
            perMedicine = meds.map { it.medicine }.filter { m -> windowOutcomes.any { it.medicineId == m.id } }
                .map { m -> m to Adherence.percent(windowOutcomes.filter { it.medicineId == m.id }) },
            daily = window.takeLast(14).map { (date, list) -> date to Adherence.percent(list) },
            mostMissed = Adherence.mostMissedTimes(windowOutcomes),
            byPeriod = Adherence.missedByPeriod(windowOutcomes),
            counts = windowOutcomes.groupingBy { it.status.name }.eachCount(),
            loaded = true,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), InsightsState())
}

@Composable
fun InsightsScreen(onOpenReport: () -> Unit, onOpenSettings: () -> Unit, viewModel: InsightsViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val use24h = LocalSettings.current.use24h
    GradientBackground {
        LazyColumn(
            Modifier.fillMaxWidth().statusBarsPadding(),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, bottom = 32.dp),
        ) {
            item {
                Row(Modifier.fillMaxWidth().padding(top = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(stringResource(R.string.tab_insights), style = MaterialTheme.typography.headlineMedium, modifier = Modifier.weight(1f))
                    IconButton(onClick = onOpenReport) { Icon(Icons.Rounded.PictureAsPdf, stringResource(R.string.doctor_report)) }
                    IconButton(onClick = onOpenSettings) { Icon(Icons.Rounded.Settings, stringResource(R.string.settings)) }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(vertical = 8.dp)) {
                    listOf(7, 30, 90).forEach { d ->
                        FilterChip(selected = state.days == d, onClick = { viewModel.range.value = d },
                            label = { Text(stringResource(R.string.last_n_days, d)) })
                    }
                }
            }
            if (state.loaded && state.overall == null) {
                item { EmptyState(Icons.Rounded.EmojiEvents, stringResource(R.string.insights_empty_title), stringResource(R.string.insights_empty_text)) }
                return@LazyColumn
            }
            item {
                AppCard {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        val pct = state.overall ?: 0
                        ProgressRing(pct / 100f, size = 124.dp, stroke = 12.dp, color = adherenceColor(pct)) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text("$pct%", style = MaterialTheme.typography.headlineMedium)
                                Text(stringResource(R.string.adherence), style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                        Spacer(Modifier.width(18.dp))
                        Column {
                            CountLine(stringResource(R.string.status_taken), (state.counts["TAKEN"] ?: 0), StatusColors.Taken)
                            CountLine(stringResource(R.string.status_late), (state.counts["LATE"] ?: 0), StatusColors.Late)
                            CountLine(stringResource(R.string.status_skipped), (state.counts["SKIPPED"] ?: 0), StatusColors.Skipped)
                            CountLine(stringResource(R.string.status_missed), (state.counts["MISSED"] ?: 0), StatusColors.Missed)
                        }
                    }
                }
                Spacer(Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    StatCard(Icons.Rounded.LocalFireDepartment, pluralStringResource(R.plurals.days_count, state.streaks.current, state.streaks.current),
                        stringResource(R.string.current_streak), Color(0xFFF08A24), Modifier.weight(1f))
                    StatCard(Icons.Rounded.EmojiEvents, pluralStringResource(R.plurals.days_count, state.streaks.best, state.streaks.best),
                        stringResource(R.string.best_streak), Color(0xFFE2B714), Modifier.weight(1f))
                }
            }
            item {
                SectionHeader(stringResource(R.string.last_14_days))
                AppCard { DailyBars(state.daily) }
            }
            if (state.perMedicine.isNotEmpty()) {
                item {
                    SectionHeader(stringResource(R.string.by_medicine))
                    AppCard {
                        state.perMedicine.forEach { (m, pct) ->
                            Column(Modifier.padding(vertical = 6.dp)) {
                                Row {
                                    Text(m.name, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
                                    Text(pct?.let { "$it%" } ?: "—", style = MaterialTheme.typography.labelLarge)
                                }
                                Spacer(Modifier.height(4.dp))
                                LinearProgressIndicator(
                                    progress = { (pct ?: 0) / 100f },
                                    modifier = Modifier.fillMaxWidth().height(8.dp).clip(RoundedCornerShape(4.dp)),
                                    color = medicineColor(m.colorIndex),
                                    trackColor = medicineColor(m.colorIndex).copy(alpha = 0.15f),
                                )
                            }
                        }
                    }
                }
            }
            item {
                SectionHeader(stringResource(R.string.most_missed_times))
                AppCard {
                    if (state.mostMissed.isEmpty()) {
                        Text(stringResource(R.string.nothing_missed), color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    state.mostMissed.forEach { (time, count) ->
                        Row(Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
                            Text(TimeFormat.time(time, use24h), style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
                            Text(pluralStringResource(R.plurals.times_count, count, count), color = StatusColors.Missed)
                        }
                    }
                    if (state.byPeriod.isNotEmpty()) {
                        Spacer(Modifier.height(10.dp))
                        val max = state.byPeriod.values.maxOrNull() ?: 1
                        DayPeriod.entries.forEach { p ->
                            val c = state.byPeriod[p] ?: 0
                            Row(Modifier.fillMaxWidth().padding(vertical = 3.dp), verticalAlignment = Alignment.CenterVertically) {
                                Text(stringResource(periodLabel(p)), Modifier.width(96.dp), style = MaterialTheme.typography.bodySmall)
                                Box(Modifier.weight(1f).height(10.dp).clip(RoundedCornerShape(5.dp)).background(MaterialTheme.colorScheme.surfaceVariant)) {
                                    Box(Modifier.fillMaxWidth(c.toFloat() / max).height(10.dp).clip(RoundedCornerShape(5.dp)).background(StatusColors.Missed))
                                }
                                Text(" $c", style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }
                }
            }
        }
    }
}

fun adherenceColor(pct: Int): Color = when {
    pct >= 90 -> StatusColors.Taken
    pct >= 70 -> StatusColors.Late
    else -> StatusColors.Missed
}

@Composable
private fun CountLine(label: String, count: Int, color: Color) {
    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(vertical = 2.dp)) {
        Box(Modifier.size(10.dp).clip(CircleShape).background(color))
        Spacer(Modifier.width(8.dp))
        Text("$label  $count", style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun StatCard(icon: ImageVector, value: String, label: String, color: Color, modifier: Modifier) {
    AppCard(modifier) {
        Icon(icon, null, tint = color)
        Spacer(Modifier.height(6.dp))
        Text(value, style = MaterialTheme.typography.titleLarge)
        Text(label, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun DailyBars(daily: List<Pair<LocalDate, Int?>>) {
    val track = MaterialTheme.colorScheme.surfaceVariant
    Canvas(Modifier.fillMaxWidth().height(120.dp)) {
        if (daily.isEmpty()) return@Canvas
        val gap = 6.dp.toPx()
        val w = (size.width - gap * (daily.size - 1)) / daily.size
        daily.forEachIndexed { i, (_, pct) ->
            val x = i * (w + gap)
            drawRoundRect(track, Offset(x, 0f), Size(w, size.height), CornerRadius(w / 2))
            if (pct != null) {
                val h = size.height * pct / 100f
                drawRoundRect(adherenceColor(pct), Offset(x, size.height - h), Size(w, h), CornerRadius(w / 2))
            }
        }
    }
    Row(Modifier.fillMaxWidth().padding(top = 4.dp)) {
        Text(daily.firstOrNull()?.first?.let { TimeFormat.shortDate(it) } ?: "", style = MaterialTheme.typography.labelSmall, modifier = Modifier.weight(1f))
        Text(daily.lastOrNull()?.first?.let { TimeFormat.shortDate(it) } ?: "", style = MaterialTheme.typography.labelSmall)
    }
}
