package com.dosemate.app.ui.history

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.rounded.KeyboardArrowRight
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.dosemate.app.R
import com.dosemate.app.alarm.ReminderEngine
import com.dosemate.app.data.db.ActiveAlertDao
import com.dosemate.app.data.repo.DoseItem
import com.dosemate.app.data.repo.DoseQueries
import com.dosemate.app.data.repo.LogRepository
import com.dosemate.app.data.repo.MedicineRepository
import com.dosemate.app.data.repo.SettingsRepository
import com.dosemate.app.ui.components.AppCard
import com.dosemate.app.ui.components.GradientBackground
import com.dosemate.app.ui.components.Pill
import com.dosemate.app.ui.components.SectionHeader
import com.dosemate.app.ui.theme.LocalSettings
import com.dosemate.app.ui.theme.StatusColors
import com.dosemate.app.ui.theme.medicineColor
import com.dosemate.app.ui.today.statusColor
import com.dosemate.app.util.TimeFormat
import com.dosemate.core.Adherence
import com.dosemate.core.DayAdherence
import com.dosemate.core.DoseOutcome
import com.dosemate.core.DoseStatus
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale
import javax.inject.Inject

data class HistoryState(
    val month: YearMonth = YearMonth.now(),
    val days: Map<LocalDate, DayAdherence> = emptyMap(),
    val selected: LocalDate = LocalDate.now(),
    val items: List<DoseItem> = emptyList(),
    val monthPercent: Int? = null,
)

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class HistoryViewModel @Inject constructor(
    medicines: MedicineRepository,
    private val logs: LogRepository,
    alerts: ActiveAlertDao,
    settingsRepo: SettingsRepository,
    private val engine: ReminderEngine,
) : ViewModel() {
    private val month = MutableStateFlow(YearMonth.now())
    private val selected = MutableStateFlow(LocalDate.now())

    val state: StateFlow<HistoryState> = month.flatMapLatest { ym ->
        combine(
            medicines.medicines,
            logs.observeBetween(ym.atDay(1).minusDays(1), ym.atEndOfMonth().plusDays(1)),
            alerts.observeAll(),
            settingsRepo.settings,
            selected,
        ) { meds, logList, active, settings, sel ->
            val now = LocalDateTime.now()
            val byDay = mutableMapOf<LocalDate, DayAdherence>()
            val all = mutableListOf<DoseOutcome>()
            var d = ym.atDay(1)
            while (!d.isAfter(ym.atEndOfMonth())) {
                val items = DoseQueries.dosesOn(d, meds, logList, active, now, settings)
                val outcomes = items.map { DoseOutcome(it.med.medicine.id, it.slot.id, it.scheduledAt, it.status) }
                byDay[d] = Adherence.dayAdherence(outcomes)
                all += outcomes
                d = d.plusDays(1)
            }
            val selItems = if (YearMonth.from(sel) == ym) DoseQueries.dosesOn(sel, meds, logList, active, now, settings) else emptyList()
            HistoryState(ym, byDay, sel, selItems, Adherence.percent(all))
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), HistoryState())

    fun previousMonth() { month.value = month.value.minusMonths(1); selected.value = month.value.atDay(1) }
    fun nextMonth() { month.value = month.value.plusMonths(1); selected.value = month.value.atDay(1) }
    fun select(date: LocalDate) { selected.value = date }

    fun markTaken(item: DoseItem) = viewModelScope.launch { engine.markTaken(item.key, item.scheduledAt) }
    fun markSkipped(item: DoseItem) = viewModelScope.launch { engine.markSkipped(item.key, null) }
    fun markMissed(item: DoseItem) = viewModelScope.launch { engine.markMissed(item.key) }
    fun clear(item: DoseItem) = viewModelScope.launch { engine.clear(item.key) }
}

fun dayColor(status: DayAdherence?): Color? = when (status) {
    DayAdherence.TAKEN -> StatusColors.Taken
    DayAdherence.LATE -> StatusColors.Late
    DayAdherence.SKIPPED -> StatusColors.Skipped
    DayAdherence.MISSED -> StatusColors.Missed
    else -> null
}

@Composable
fun HistoryScreen(onOpenSettings: () -> Unit, viewModel: HistoryViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val use24h = LocalSettings.current.use24h
    val locale = Locale.getDefault()
    GradientBackground {
        LazyColumn(
            Modifier.fillMaxWidth().statusBarsPadding(),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, bottom = 32.dp),
        ) {
            item {
                Row(Modifier.fillMaxWidth().padding(top = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(stringResource(R.string.tab_history), style = MaterialTheme.typography.headlineMedium, modifier = Modifier.weight(1f))
                    IconButton(onClick = onOpenSettings) { Icon(Icons.Rounded.Settings, stringResource(R.string.settings)) }
                }
                Spacer(Modifier.height(12.dp))
                AppCard {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        IconButton(onClick = viewModel::previousMonth) { Icon(Icons.AutoMirrored.Rounded.KeyboardArrowLeft, null) }
                        Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(DateTimeFormatter.ofPattern("MMMM yyyy", locale).format(state.month), style = MaterialTheme.typography.titleMedium)
                            state.monthPercent?.let {
                                Text(stringResource(R.string.adherence_pct, it), style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                        IconButton(onClick = viewModel::nextMonth) { Icon(Icons.AutoMirrored.Rounded.KeyboardArrowRight, null) }
                    }
                    Spacer(Modifier.height(8.dp))
                    MonthGrid(state, locale, viewModel::select)
                    Spacer(Modifier.height(12.dp))
                    Legend()
                }
            }
            item {
                SectionHeader(TimeFormat.date(state.selected))
                if (state.items.isEmpty()) {
                    Text(stringResource(R.string.no_doses_day), color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            items(state.items, key = { "${it.slot.id}-${it.scheduledAt}" }) { item ->
                HistoryRow(item, use24h, viewModel)
                Spacer(Modifier.height(8.dp))
            }
        }
    }
}

@Composable
private fun MonthGrid(state: HistoryState, locale: Locale, onSelect: (LocalDate) -> Unit) {
    val first = state.month.atDay(1)
    val lead = (first.dayOfWeek.value - DayOfWeek.MONDAY.value)
    val days = state.month.lengthOfMonth()
    val today = LocalDate.now()
    Row(Modifier.fillMaxWidth()) {
        DayOfWeek.entries.forEach {
            Text(
                it.getDisplayName(TextStyle.NARROW, locale), Modifier.weight(1f), textAlign = TextAlign.Center,
                style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
    val cells = lead + days
    val rows = (cells + 6) / 7
    for (r in 0 until rows) {
        Row(Modifier.fillMaxWidth()) {
            for (c in 0 until 7) {
                val dayNum = r * 7 + c - lead + 1
                Box(Modifier.weight(1f).aspectRatio(1f).padding(3.dp), contentAlignment = Alignment.Center) {
                    if (dayNum in 1..days) {
                        val date = state.month.atDay(dayNum)
                        val status = state.days[date]
                        val color = dayColor(status)
                        val selected = date == state.selected
                        Box(
                            Modifier
                                .size(38.dp)
                                .clip(CircleShape)
                                .background(color?.copy(alpha = if (selected) 1f else 0.85f) ?: Color.Transparent)
                                .border(
                                    width = if (selected) 2.dp else if (date == today || status == DayAdherence.PENDING) 1.dp else 0.dp,
                                    color = if (selected) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.outline,
                                    shape = CircleShape,
                                )
                                .clickable { onSelect(date) },
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                "$dayNum",
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = if (date == today) FontWeight.Bold else FontWeight.Normal,
                                color = if (color != null) Color.White else MaterialTheme.colorScheme.onSurface,
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun Legend() {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        listOf(
            R.string.status_taken to StatusColors.Taken,
            R.string.status_late to StatusColors.Late,
            R.string.status_skipped to StatusColors.Skipped,
            R.string.status_missed to StatusColors.Missed,
        ).forEach { (label, color) ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(10.dp).clip(CircleShape).background(color))
                Spacer(Modifier.width(6.dp))
                Text(stringResource(label), style = MaterialTheme.typography.labelMedium)
            }
        }
    }
}

@Composable
private fun HistoryRow(item: DoseItem, use24h: Boolean, viewModel: HistoryViewModel) {
    var menu by remember { mutableStateOf(false) }
    Box {
        AppCard(onClick = { menu = true }) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(12.dp).clip(CircleShape).background(medicineColor(item.med.medicine.colorIndex)))
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(item.med.medicine.name, style = MaterialTheme.typography.titleSmall)
                    Text(TimeFormat.time(item.dueAt.toLocalTime(), use24h), style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Pill(
                    when (item.status) {
                        DoseStatus.TAKEN -> stringResource(R.string.status_taken_at, TimeFormat.time(item.log!!.actionAt.toLocalTime(), use24h))
                        DoseStatus.LATE -> stringResource(R.string.status_late_at, TimeFormat.time(item.log!!.actionAt.toLocalTime(), use24h))
                        DoseStatus.SKIPPED -> stringResource(R.string.status_skipped) + (item.log?.skipReason?.let { " · $it" } ?: "")
                        DoseStatus.MISSED -> stringResource(R.string.status_missed)
                        DoseStatus.DUE -> stringResource(R.string.status_due)
                        DoseStatus.UPCOMING -> stringResource(R.string.status_upcoming)
                    },
                    statusColor(item.status),
                )
            }
        }
        DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
            DropdownMenuItem(text = { Text(stringResource(R.string.mark_taken_on_time)) }, onClick = { menu = false; viewModel.markTaken(item) })
            DropdownMenuItem(text = { Text(stringResource(R.string.mark_skipped)) }, onClick = { menu = false; viewModel.markSkipped(item) })
            DropdownMenuItem(text = { Text(stringResource(R.string.mark_missed)) }, onClick = { menu = false; viewModel.markMissed(item) })
            if (item.log != null) {
                DropdownMenuItem(text = { Text(stringResource(R.string.clear_record)) }, onClick = { menu = false; viewModel.clear(item) })
            }
        }
    }
}
