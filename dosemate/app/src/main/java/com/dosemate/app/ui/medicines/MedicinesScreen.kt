package com.dosemate.app.ui.medicines

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.ExpandLess
import androidx.compose.material.icons.rounded.ExpandMore
import androidx.compose.material.icons.rounded.Medication
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.dosemate.app.R
import com.dosemate.app.data.db.MedicineWithTimes
import com.dosemate.app.data.repo.AppSettings
import com.dosemate.app.data.repo.MedicineRepository
import com.dosemate.app.data.repo.PhotoStore
import com.dosemate.app.data.repo.SettingsRepository
import com.dosemate.app.data.repo.engine
import com.dosemate.app.data.repo.sortedTimes
import com.dosemate.app.data.repo.time
import com.dosemate.app.ui.components.AppCard
import com.dosemate.app.ui.components.EmptyState
import com.dosemate.app.ui.components.GradientBackground
import com.dosemate.app.ui.components.MedicineAvatar
import com.dosemate.app.ui.components.Pill
import com.dosemate.app.ui.components.SectionHeader
import com.dosemate.app.ui.theme.LocalSettings
import com.dosemate.app.ui.theme.StatusColors
import com.dosemate.app.ui.theme.medicineColor
import com.dosemate.app.util.TimeFormat
import com.dosemate.app.util.doseLine
import com.dosemate.app.util.formatAmount
import com.dosemate.core.CourseProgress
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import java.io.File
import java.time.LocalDate
import javax.inject.Inject

@HiltViewModel
class MedicinesViewModel @Inject constructor(
    repo: MedicineRepository,
    settingsRepo: SettingsRepository,
    photos: PhotoStore,
) : ViewModel() {
    val medicines: StateFlow<List<MedicineWithTimes>?> = repo.medicines.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)
    val settings: StateFlow<AppSettings> = settingsRepo.settings.stateIn(viewModelScope, SharingStarted.Eagerly, settingsRepo.current())
    val photoDir: File = photos.dir(PhotoStore.MEDICINE)
}

@Composable
fun MedicinesScreen(
    onOpen: (Long) -> Unit,
    onAdd: () -> Unit,
    onOpenSettings: () -> Unit,
    viewModel: MedicinesViewModel = hiltViewModel(),
) {
    val meds by viewModel.medicines.collectAsStateWithLifecycle()
    val settings by viewModel.settings.collectAsStateWithLifecycle()
    var showArchived by rememberSaveable { mutableStateOf(false) }
    val active = meds.orEmpty().filter { !it.medicine.archived }
    val archived = meds.orEmpty().filter { it.medicine.archived }

    GradientBackground {
        LazyColumn(
            Modifier.fillMaxWidth().statusBarsPadding(),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, bottom = 100.dp),
        ) {
            item {
                Row(Modifier.fillMaxWidth().padding(top = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(stringResource(R.string.tab_medicines), style = MaterialTheme.typography.headlineMedium, modifier = Modifier.weight(1f))
                    IconButton(onClick = onOpenSettings) { Icon(Icons.Rounded.Settings, stringResource(R.string.settings)) }
                }
                if (settings.doctorName.isNotBlank() || settings.prescribedDate != null) {
                    Spacer(Modifier.height(12.dp))
                    PrescriptionCard(settings)
                }
            }
            if (meds != null && active.isEmpty()) {
                item {
                    EmptyState(Icons.Rounded.Medication, stringResource(R.string.today_no_meds_title), stringResource(R.string.today_no_meds_text))
                }
            }
            if (active.isNotEmpty()) item { SectionHeader(stringResource(R.string.active_courses)) }
            items(active, key = { it.medicine.id }) { med ->
                MedicineRow(med, viewModel.photoDir) { onOpen(med.medicine.id) }
                Spacer(Modifier.height(10.dp))
            }
            if (archived.isNotEmpty()) {
                item {
                    SectionHeader(stringResource(R.string.archived_count, archived.size)) {
                        TextButton(onClick = { showArchived = !showArchived }) {
                            Icon(if (showArchived) Icons.Rounded.ExpandLess else Icons.Rounded.ExpandMore, null)
                        }
                    }
                }
                if (showArchived) {
                    items(archived, key = { it.medicine.id }) { med ->
                        MedicineRow(med, viewModel.photoDir) { onOpen(med.medicine.id) }
                        Spacer(Modifier.height(10.dp))
                    }
                }
            }
        }
        ExtendedFloatingActionButton(
            onClick = onAdd,
            modifier = Modifier.align(Alignment.BottomEnd).padding(20.dp),
            icon = { Icon(Icons.Rounded.Add, null) },
            text = { Text(stringResource(R.string.add_medicine)) },
        )
    }
}

@Composable
private fun PrescriptionCard(settings: AppSettings) {
    AppCard(containerColor = MaterialTheme.colorScheme.primaryContainer) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.Person, null, tint = MaterialTheme.colorScheme.primary)
            Spacer(Modifier.width(12.dp))
            Column {
                Text(settings.doctorName, style = MaterialTheme.typography.titleMedium)
                settings.prescribedDate?.let {
                    Text(stringResource(R.string.prescribed_on, TimeFormat.dayMonthYear(it)), style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
        if (settings.dietNote.isNotBlank()) {
            Spacer(Modifier.height(8.dp))
            Text(settings.dietNote, style = MaterialTheme.typography.bodyMedium)
        }
    }
}

@Composable
fun progressText(p: CourseProgress): String = when {
    p.notStarted -> pluralStringResource(R.plurals.starts_in_days, p.daysUntilStart, p.daysUntilStart)
    p.finished -> stringResource(R.string.course_finished)
    p.totalDoses != null -> stringResource(R.string.dose_n_of_m, p.doseNumber ?: 0, p.totalDoses ?: 0)
    p.totalDays == null -> stringResource(R.string.day_n_ongoing, p.dayNumber)
    else -> stringResource(R.string.day_n_of_m, p.dayNumber, p.totalDays ?: 0)
}

/** "3 doses left" for dose-based courses, otherwise "16 days left". */
@Composable
fun remainingText(p: CourseProgress): String? {
    if (p.finished || p.notStarted) return null
    p.dosesRemaining?.let { return pluralStringResource(R.plurals.doses_left, it, it) }
    return p.daysRemaining?.let { pluralStringResource(R.plurals.days_left, it, it) }
}

@Composable
private fun MedicineRow(med: MedicineWithTimes, photoDir: File, onClick: () -> Unit) {
    val m = med.medicine
    val context = LocalContext.current
    val use24h = LocalSettings.current.use24h
    val progress = med.engine().progress(LocalDate.now())
    AppCard(onClick = onClick) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            MedicineAvatar(m, photoDir, 50.dp)
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text(m.name, style = MaterialTheme.typography.titleMedium, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text(
                    context.doseLine(m) + " · " + med.sortedTimes.filter { it.enabled }.joinToString(", ") { TimeFormat.time(it.time, use24h) },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        Spacer(Modifier.height(12.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(progressText(progress), style = MaterialTheme.typography.labelLarge, modifier = Modifier.weight(1f))
            remainingText(progress)?.let {
                Text(it, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        if (progress.totalDays != null) {
            Spacer(Modifier.height(6.dp))
            LinearProgressIndicator(
                progress = { progress.fraction },
                modifier = Modifier.fillMaxWidth().height(8.dp).clip(RoundedCornerShape(4.dp)),
                color = medicineColor(m.colorIndex),
                trackColor = medicineColor(m.colorIndex).copy(alpha = 0.15f),
            )
        }
        val badges = buildList {
            if (m.paused) add(stringResource(R.string.paused) to StatusColors.Late)
            if (m.stockEnabled && m.stockCount <= m.refillThreshold) add(stringResource(R.string.stock_low, formatAmount(m.stockCount)) to StatusColors.Missed)
            if (m.linkedMedicineId != null) add(stringResource(R.string.linked_badge) to MaterialTheme.colorScheme.primary)
        }
        if (badges.isNotEmpty()) {
            Spacer(Modifier.height(10.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) { badges.forEach { (t, c) -> Pill(t, c) } }
        }
    }
}
