package com.dosemate.app.ui.medicines

import android.widget.Toast
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Alarm
import androidx.compose.material.icons.rounded.Archive
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material.icons.rounded.Notifications
import androidx.compose.material.icons.rounded.Pause
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.Unarchive
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.dosemate.app.R
import com.dosemate.app.alarm.ReminderEngine
import com.dosemate.app.data.db.DoseLogEntity
import com.dosemate.app.data.db.MedicineWithTimes
import com.dosemate.app.data.repo.LogRepository
import com.dosemate.app.data.repo.MedicineRepository
import com.dosemate.app.data.repo.PhotoStore
import com.dosemate.app.data.repo.engine
import com.dosemate.app.data.repo.sortedTimes
import com.dosemate.app.data.repo.time
import com.dosemate.app.data.repo.toRecord
import com.dosemate.app.data.repo.toSpec
import com.dosemate.app.data.repo.weekdaysFromMask
import com.dosemate.app.ui.components.AppCard
import com.dosemate.app.ui.components.MedicineAvatar
import com.dosemate.app.ui.components.Pill
import com.dosemate.app.ui.components.ProgressRing
import com.dosemate.app.ui.components.SectionHeader
import com.dosemate.app.ui.theme.LocalSettings
import com.dosemate.app.ui.theme.StatusColors
import com.dosemate.app.ui.theme.medicineColor
import com.dosemate.app.util.TimeFormat
import com.dosemate.app.util.doseLine
import com.dosemate.app.util.formatAmount
import com.dosemate.core.Adherence
import com.dosemate.core.DurationType
import com.dosemate.core.LogStatus
import com.dosemate.core.ScheduleType
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.io.File
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.TextStyle
import java.util.Locale
import javax.inject.Inject

@HiltViewModel
class MedicineDetailViewModel @Inject constructor(
    savedState: SavedStateHandle,
    private val repo: MedicineRepository,
    logs: LogRepository,
    private val engine: ReminderEngine,
    photos: PhotoStore,
    prescriptionRepo: com.dosemate.app.data.repo.PrescriptionRepository,
) : ViewModel() {
    val prescriptions: StateFlow<List<com.dosemate.app.data.db.PrescriptionEntity>> =
        prescriptionRepo.prescriptions.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val id: Long = savedState.get<Long>("id") ?: 0L
    val medicine: StateFlow<MedicineWithTimes?> = repo.observe(id).stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)
    val recent: StateFlow<List<DoseLogEntity>> = logs.observeRecent(id, 40).stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())
    val all: StateFlow<List<MedicineWithTimes>> = repo.medicines.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())
    val photoDir: File = photos.dir(PhotoStore.MEDICINE)

    /** Adherence % for this medicine since tracking began. */
    val adherence: StateFlow<Int?> = combine(repo.observe(id), logs.observeAll()) { med, allLogs ->
        med ?: return@combine null
        val records = allLogs.filter { it.medicineId == id }.map { it.toRecord() }
        val outcomes = Adherence.outcomes(listOf(med.toSpec()), records, med.medicine.startDate, LocalDate.now(), LocalDateTime.now())
            .filter { o -> !o.scheduledAt.isBefore(med.medicine.trackFrom) || records.any { it.scheduledAt == o.scheduledAt } }
        Adherence.percent(outcomes)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    fun setPaused(paused: Boolean) = viewModelScope.launch {
        repo.setPaused(id, paused)
        engine.rescheduleAll()
    }

    fun setArchived(archived: Boolean) = viewModelScope.launch {
        repo.setArchived(id, archived)
        engine.rescheduleAll()
    }

    fun delete(onDone: () -> Unit) = viewModelScope.launch {
        repo.delete(id)
        engine.rescheduleAll()
        onDone()
    }

    fun testAlarm() = viewModelScope.launch { engine.testAlarm(id) }
    fun testNotification() = viewModelScope.launch { engine.testNotification(id) }
}

@Composable
fun MedicineDetailScreen(onBack: () -> Unit, onEdit: (Long) -> Unit, viewModel: MedicineDetailViewModel = hiltViewModel()) {
    val med by viewModel.medicine.collectAsStateWithLifecycle()
    val recent by viewModel.recent.collectAsStateWithLifecycle()
    val all by viewModel.all.collectAsStateWithLifecycle()
    val prescriptions by viewModel.prescriptions.collectAsStateWithLifecycle()
    var confirmDelete by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val use24h = LocalSettings.current.use24h

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text(med?.medicine?.name ?: "") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, stringResource(R.string.back)) } },
                actions = { IconButton(onClick = { onEdit(viewModel.id) }) { Icon(Icons.Rounded.Edit, stringResource(R.string.edit)) } },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = MaterialTheme.colorScheme.background),
            )
        },
    ) { padding ->
        val current = med ?: return@Scaffold
        val m = current.medicine
        val engine = current.engine()
        val progress = engine.progress(LocalDate.now())
        val color = medicineColor(m.colorIndex)
        LazyColumn(contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = padding.calculateTopPadding(), bottom = 40.dp)) {
            item {
                AppCard {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        MedicineAvatar(m, viewModel.photoDir, 72.dp)
                        Spacer(Modifier.width(16.dp))
                        Column(Modifier.weight(1f)) {
                            Text(m.name, style = MaterialTheme.typography.titleLarge)
                            Text(context.doseLine(m), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Spacer(Modifier.height(6.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                Pill(stringResource(typeLabel(m.type)), color)
                                Pill(stringResource(styleLabel(m.alertStyle)), MaterialTheme.colorScheme.primary)
                                if (m.paused) Pill(stringResource(R.string.paused), StatusColors.Late)
                            }
                        }
                    }
                    prescriptions.firstOrNull { it.id == m.prescriptionId }?.let { rx ->
                        Spacer(Modifier.height(10.dp))
                        Text(
                            stringResource(R.string.prescribed_by, rx.doctorName) +
                                (rx.date?.let { " · " + TimeFormat.dayMonthYear(it) } ?: ""),
                            style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.primary,
                        )
                    }
                    if (m.instructions.isNotBlank()) {
                        Spacer(Modifier.height(12.dp))
                        Text(m.instructions, style = MaterialTheme.typography.bodyLarge)
                    }
                    if (m.notes.isNotBlank()) {
                        Spacer(Modifier.height(6.dp))
                        Text(m.notes, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    if (m.warning.isNotBlank()) {
                        Spacer(Modifier.height(8.dp))
                        Pill("⚠ " + m.warning, StatusColors.Missed)
                    }
                }
            }
            item {
                Spacer(Modifier.height(12.dp))
                AppCard {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        val pct by viewModel.adherence.collectAsStateWithLifecycle()
                        ProgressRing(progress.fraction, size = 96.dp, stroke = 10.dp, color = color, track = color.copy(alpha = 0.15f)) {
                            Text(if (progress.totalDays != null) "${(progress.fraction * 100).toInt()}%" else "∞", style = MaterialTheme.typography.titleLarge)
                        }
                        Spacer(Modifier.width(18.dp))
                        Column {
                            Text(progressText(progress), style = MaterialTheme.typography.titleMedium)
                            remainingText(progress)?.let {
                                Text(it,
                                    style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                            engine.totalDoses?.let {
                                Text(stringResource(R.string.total_doses, it), style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                            pct?.let {
                                Text(stringResource(R.string.adherence_pct, it), style = MaterialTheme.typography.bodyMedium, color = color)
                            }
                        }
                    }
                }
            }
            item {
                SectionHeader(stringResource(R.string.schedule))
                AppCard {
                    Text(scheduleSummary(current), style = MaterialTheme.typography.bodyLarge)
                    Spacer(Modifier.height(6.dp))
                    current.sortedTimes.forEach { t ->
                        Row(Modifier.fillMaxWidth().padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                            Text(TimeFormat.time(t.time, use24h), style = MaterialTheme.typography.titleMedium,
                                color = if (t.enabled) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.weight(1f))
                            Text(
                                if (!t.enabled) stringResource(R.string.off) else stringResource(styleLabel(t.alertStyle ?: m.alertStyle)),
                                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    }
                    m.linkedMedicineId?.let { leaderId ->
                        val leader = all.firstOrNull { it.medicine.id == leaderId }
                        if (leader != null) {
                            Spacer(Modifier.height(6.dp))
                            Pill(stringResource(R.string.linked_after, m.linkedGapMinutes, leader.medicine.name), MaterialTheme.colorScheme.primary)
                        }
                    }
                    if (m.stockEnabled) {
                        Spacer(Modifier.height(10.dp))
                        Text(stringResource(R.string.stock_remaining, formatAmount(m.stockCount), m.doseUnit),
                            style = MaterialTheme.typography.bodyMedium,
                            color = if (m.stockCount <= m.refillThreshold) StatusColors.Missed else MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
            item {
                SectionHeader(stringResource(R.string.test_reminders))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    FilledTonalButton(onClick = viewModel::testAlarm, modifier = Modifier.weight(1f)) {
                        Icon(Icons.Rounded.Alarm, null)
                        Spacer(Modifier.width(6.dp))
                        Text(stringResource(R.string.test_alarm))
                    }
                    FilledTonalButton(onClick = viewModel::testNotification, modifier = Modifier.weight(1f)) {
                        Icon(Icons.Rounded.Notifications, null)
                        Spacer(Modifier.width(6.dp))
                        Text(stringResource(R.string.test_notification))
                    }
                }
                SectionHeader(stringResource(R.string.manage))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedButton(onClick = { viewModel.setPaused(!m.paused) }, modifier = Modifier.weight(1f)) {
                        Icon(if (m.paused) Icons.Rounded.PlayArrow else Icons.Rounded.Pause, null)
                        Spacer(Modifier.width(6.dp))
                        Text(stringResource(if (m.paused) R.string.resume else R.string.pause))
                    }
                    OutlinedButton(onClick = {
                        viewModel.setArchived(!m.archived)
                        Toast.makeText(context, if (m.archived) R.string.unarchived else R.string.archived_toast, Toast.LENGTH_SHORT).show()
                    }, modifier = Modifier.weight(1f)) {
                        Icon(if (m.archived) Icons.Rounded.Unarchive else Icons.Rounded.Archive, null)
                        Spacer(Modifier.width(6.dp))
                        Text(stringResource(if (m.archived) R.string.unarchive else R.string.archive))
                    }
                }
                TextButton(onClick = { confirmDelete = true }, modifier = Modifier.fillMaxWidth()) {
                    Icon(Icons.Rounded.Delete, null, tint = StatusColors.Missed)
                    Spacer(Modifier.width(6.dp))
                    Text(stringResource(R.string.delete_medicine), color = StatusColors.Missed)
                }
            }
            if (recent.isNotEmpty()) {
                item { SectionHeader(stringResource(R.string.recent_history)) }
                items(recent, key = { it.id }) { log ->
                    Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            TimeFormat.shortDate(log.scheduledAt.toLocalDate()) + "  " + TimeFormat.time(log.scheduledAt.toLocalTime(), use24h),
                            style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f),
                        )
                        val (label, c) = when (log.status) {
                            LogStatus.TAKEN -> stringResource(R.string.status_taken_at, TimeFormat.time(log.actionAt.toLocalTime(), use24h)) to StatusColors.Taken
                            LogStatus.SKIPPED -> (stringResource(R.string.status_skipped) + (log.skipReason?.let { " · $it" } ?: "")) to StatusColors.Skipped
                            LogStatus.MISSED -> stringResource(R.string.status_missed) to StatusColors.Missed
                        }
                        Pill(label, c)
                    }
                }
            }
        }
    }

    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text(stringResource(R.string.delete_medicine)) },
            text = { Text(stringResource(R.string.delete_confirm)) },
            confirmButton = {
                TextButton(onClick = {
                    confirmDelete = false
                    viewModel.delete(onBack)
                }) { Text(stringResource(R.string.delete), color = StatusColors.Missed) }
            },
            dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text(stringResource(R.string.cancel)) } },
        )
    }
}

@Composable
fun scheduleSummary(med: MedicineWithTimes): String {
    val m = med.medicine
    val locale = Locale.getDefault()
    val freq = when (m.scheduleType) {
        ScheduleType.DAILY, ScheduleType.CUSTOM_TIMES -> stringResource(R.string.sched_daily)
        ScheduleType.TIMES_PER_DAY -> stringResource(R.string.sched_times_per_day_n, med.times.count { it.enabled })
        ScheduleType.SPECIFIC_WEEKDAYS -> weekdaysFromMask(m.weekdays).sorted().joinToString(", ") { it.getDisplayName(TextStyle.SHORT, locale) }
        ScheduleType.EVERY_X_DAYS -> stringResource(R.string.sched_every_n_days, m.intervalDays)
        ScheduleType.WEEKLY -> stringResource(
            R.string.sched_weekly_on,
            (weekdaysFromMask(m.weekdays).firstOrNull() ?: m.startDate.dayOfWeek).getDisplayName(TextStyle.FULL, locale),
        )
    }
    val duration = when (m.durationType) {
        DurationType.ONGOING -> stringResource(R.string.dur_ongoing)
        DurationType.END_DATE -> stringResource(R.string.dur_until, TimeFormat.date(m.endDate ?: m.startDate))
        DurationType.DAYS -> stringResource(R.string.dur_days_n, m.durationDays ?: 0)
        DurationType.DOSES -> stringResource(R.string.dur_doses_n, m.durationDoses ?: 0)
    }
    return "$freq · $duration · " + stringResource(R.string.starts_on, TimeFormat.date(m.startDate))
}
