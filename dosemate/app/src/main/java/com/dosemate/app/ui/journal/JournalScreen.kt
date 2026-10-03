package com.dosemate.app.ui.journal

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.AutoStories
import androidx.compose.material.icons.rounded.CameraAlt
import androidx.compose.material.icons.rounded.CompareArrows
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Image
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.dosemate.app.R
import com.dosemate.app.alarm.ReminderEngine
import com.dosemate.app.data.db.JournalEntryEntity
import com.dosemate.app.data.repo.JournalRepository
import com.dosemate.app.data.repo.PhotoStore
import com.dosemate.app.data.repo.SettingsRepository
import com.dosemate.app.ui.components.AppCard
import com.dosemate.app.ui.components.DatePickDialog
import com.dosemate.app.ui.components.EmptyState
import com.dosemate.app.ui.components.GradientBackground
import com.dosemate.app.ui.components.PhotoBox
import com.dosemate.app.ui.components.Pill
import com.dosemate.app.ui.components.SectionHeader
import com.dosemate.app.ui.components.TextInput
import com.dosemate.app.util.TimeFormat
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.io.File
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.TextStyle
import java.util.Locale
import javax.inject.Inject

@HiltViewModel
class JournalViewModel @Inject constructor(
    private val repo: JournalRepository,
    private val photos: PhotoStore,
    private val settingsRepo: SettingsRepository,
    private val engine: ReminderEngine,
) : ViewModel() {
    val entries: StateFlow<List<JournalEntryEntity>> = repo.entries.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())
    val settings = settingsRepo.settings.stateIn(viewModelScope, SharingStarted.Eagerly, settingsRepo.current())
    val photoDir: File = photos.dir(PhotoStore.JOURNAL)

    fun newCaptureTarget(): Pair<String, Uri> = photos.newCaptureTarget(PhotoStore.JOURNAL)

    suspend fun importPhoto(uri: Uri): String? = photos.import(PhotoStore.JOURNAL, uri)

    suspend fun finishCapture(name: String, ok: Boolean): String? =
        if (ok && photos.normalize(PhotoStore.JOURNAL, name)) name else {
            photos.delete(PhotoStore.JOURNAL, name)
            null
        }

    fun save(entry: JournalEntryEntity) = viewModelScope.launch { repo.save(entry) }
    fun delete(entry: JournalEntryEntity) = viewModelScope.launch { repo.delete(entry) }

    fun setReminder(enabled: Boolean, day: Int) = viewModelScope.launch {
        settingsRepo.update { it.copy(journalReminder = enabled, journalDay = day) }
        engine.rescheduleAll()
    }
}

@Composable
fun JournalScreen(onCompare: () -> Unit, onOpenSettings: () -> Unit, viewModel: JournalViewModel = hiltViewModel()) {
    val entries by viewModel.entries.collectAsStateWithLifecycle()
    val settings by viewModel.settings.collectAsStateWithLifecycle()
    var editing by remember { mutableStateOf<JournalEntryEntity?>(null) }
    var deleting by remember { mutableStateOf<JournalEntryEntity?>(null) }

    GradientBackground {
        LazyColumn(
            Modifier.fillMaxWidth().statusBarsPadding(),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, bottom = 100.dp),
        ) {
            item {
                Row(Modifier.fillMaxWidth().padding(top = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(stringResource(R.string.tab_journal), style = MaterialTheme.typography.headlineMedium, modifier = Modifier.weight(1f))
                    if (entries.count { it.photoPath != null } >= 2) {
                        IconButton(onClick = onCompare) { Icon(Icons.Rounded.CompareArrows, stringResource(R.string.compare)) }
                    }
                    IconButton(onClick = onOpenSettings) { Icon(Icons.Rounded.Settings, stringResource(R.string.settings)) }
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Rounded.Lock, null, Modifier.size(14.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.width(6.dp))
                    Text(stringResource(R.string.journal_private), style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Spacer(Modifier.height(12.dp))
                ReminderCard(settings.journalReminder, settings.journalDay, viewModel::setReminder)
            }
            if (entries.size >= 2) {
                item {
                    SectionHeader(stringResource(R.string.itch_trend))
                    AppCard { ItchChart(entries.sortedBy { it.date }) }
                }
            }
            if (entries.isEmpty()) {
                item { EmptyState(Icons.Rounded.AutoStories, stringResource(R.string.journal_empty_title), stringResource(R.string.journal_empty_text)) }
            } else {
                item { SectionHeader(stringResource(R.string.entries)) }
            }
            items(entries, key = { it.id }) { entry ->
                AppCard(onClick = { editing = entry }) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        PhotoBox(entry.photoPath?.let { File(viewModel.photoDir, it) }, Modifier.size(84.dp)) {
                            Icon(Icons.Rounded.Image, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Spacer(Modifier.width(14.dp))
                        Column(Modifier.weight(1f)) {
                            Text(TimeFormat.date(entry.date), style = MaterialTheme.typography.titleMedium)
                            Spacer(Modifier.height(4.dp))
                            Pill(stringResource(R.string.itch_score_n, entry.itchScore), itchColor(entry.itchScore))
                            if (entry.notes.isNotBlank()) {
                                Spacer(Modifier.height(4.dp))
                                Text(entry.notes, style = MaterialTheme.typography.bodySmall, maxLines = 2,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                        IconButton(onClick = { deleting = entry }) { Icon(Icons.Rounded.Delete, stringResource(R.string.delete)) }
                    }
                }
                Spacer(Modifier.height(10.dp))
            }
        }
        ExtendedFloatingActionButton(
            onClick = { editing = JournalEntryEntity(date = LocalDate.now()) },
            modifier = Modifier.align(Alignment.BottomEnd).padding(20.dp),
            icon = { Icon(Icons.Rounded.Add, null) },
            text = { Text(stringResource(R.string.add_entry)) },
        )
    }

    editing?.let { entry ->
        EntryDialog(entry, viewModel, onDismiss = { editing = null }) {
            viewModel.save(it)
            editing = null
        }
    }
    deleting?.let { entry ->
        AlertDialog(
            onDismissRequest = { deleting = null },
            title = { Text(stringResource(R.string.delete_entry)) },
            confirmButton = { TextButton(onClick = { viewModel.delete(entry); deleting = null }) { Text(stringResource(R.string.delete)) } },
            dismissButton = { TextButton(onClick = { deleting = null }) { Text(stringResource(R.string.cancel)) } },
        )
    }
}

fun itchColor(score: Int): Color = when {
    score <= 3 -> Color(0xFF2FA866)
    score <= 6 -> Color(0xFFF2A93B)
    else -> Color(0xFFE5484D)
}

@Composable
private fun ReminderCard(enabled: Boolean, day: Int, onChange: (Boolean, Int) -> Unit) {
    AppCard {
        com.dosemate.app.ui.components.SwitchRow(
            stringResource(R.string.weekly_photo_reminder), enabled, { onChange(it, day) },
            subtitle = stringResource(R.string.weekly_photo_reminder_hint, DayOfWeek.of(day.coerceIn(1, 7)).getDisplayName(TextStyle.FULL, Locale.getDefault())),
        )
        if (enabled) {
            com.dosemate.app.ui.components.ChoiceChips(
                (1..7).toList(), day, { DayOfWeek.of(it).getDisplayName(TextStyle.SHORT, Locale.getDefault()) }, { onChange(true, it) },
            )
        }
    }
}

@Composable
private fun ItchChart(entries: List<JournalEntryEntity>) {
    val line = MaterialTheme.colorScheme.primary
    val grid = MaterialTheme.colorScheme.outlineVariant
    Canvas(Modifier.fillMaxWidth().height(140.dp)) {
        val n = entries.size
        if (n < 2) return@Canvas
        for (i in 0..2) {
            val y = size.height * i / 2f
            drawLine(grid, Offset(0f, y), Offset(size.width, y), 1f)
        }
        val path = Path()
        entries.forEachIndexed { i, e ->
            val x = size.width * i / (n - 1)
            val y = size.height * (1f - e.itchScore / 10f)
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        drawPath(path, line, style = Stroke(4.dp.toPx(), cap = StrokeCap.Round))
        entries.forEachIndexed { i, e ->
            val x = size.width * i / (n - 1)
            val y = size.height * (1f - e.itchScore / 10f)
            drawCircle(itchColor(e.itchScore), 6.dp.toPx(), Offset(x, y))
        }
    }
    Row(Modifier.fillMaxWidth().padding(top = 4.dp)) {
        Text(TimeFormat.shortDate(entries.first().date), style = MaterialTheme.typography.labelSmall, modifier = Modifier.weight(1f))
        Text(TimeFormat.shortDate(entries.last().date), style = MaterialTheme.typography.labelSmall)
    }
}

@Composable
private fun EntryDialog(
    initial: JournalEntryEntity,
    viewModel: JournalViewModel,
    onDismiss: () -> Unit,
    onSave: (JournalEntryEntity) -> Unit,
) {
    var entry by remember { mutableStateOf(initial) }
    var itch by remember { mutableIntStateOf(initial.itchScore) }
    var pickDate by remember { mutableStateOf(false) }
    var pendingCapture by rememberSaveable { mutableStateOf<String?>(null) }
    val scope = androidx.compose.runtime.rememberCoroutineScope()

    val pick = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) scope.launch { viewModel.importPhoto(uri)?.let { entry = entry.copy(photoPath = it) } }
    }
    val take = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { ok ->
        val name = pendingCapture
        pendingCapture = null
        if (name != null) scope.launch { viewModel.finishCapture(name, ok)?.let { entry = entry.copy(photoPath = it) } }
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(if (initial.id == 0L) R.string.add_entry else R.string.edit_entry)) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                PhotoBox(entry.photoPath?.let { File(viewModel.photoDir, it) }, Modifier.fillMaxWidth().aspectRatio(1.2f)) {
                    Text(stringResource(R.string.add_weekly_photo), color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Spacer(Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilledTonalButton(onClick = {
                        val (name, uri) = viewModel.newCaptureTarget()
                        pendingCapture = name
                        take.launch(uri)
                    }) {
                        Icon(Icons.Rounded.CameraAlt, null)
                        Spacer(Modifier.width(6.dp))
                        Text(stringResource(R.string.camera))
                    }
                    FilledTonalButton(onClick = { pick.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)) }) {
                        Icon(Icons.Rounded.Image, null)
                        Spacer(Modifier.width(6.dp))
                        Text(stringResource(R.string.gallery))
                    }
                }
                Spacer(Modifier.height(12.dp))
                OutlinedButton(onClick = { pickDate = true }, modifier = Modifier.fillMaxWidth()) { Text(TimeFormat.date(entry.date)) }
                Spacer(Modifier.height(12.dp))
                Text(stringResource(R.string.itch_score_n, itch), style = MaterialTheme.typography.titleMedium, color = itchColor(itch))
                Slider(value = itch.toFloat(), onValueChange = { itch = it.toInt() }, valueRange = 0f..10f, steps = 9)
                Text(stringResource(R.string.itch_scale_hint), style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.height(8.dp))
                TextInput(stringResource(R.string.field_notes), entry.notes, { entry = entry.copy(notes = it) }, singleLine = false)
            }
        },
        confirmButton = { TextButton(onClick = { onSave(entry.copy(itchScore = itch)) }) { Text(stringResource(R.string.save)) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.cancel)) } },
    )
    if (pickDate) {
        DatePickDialog(entry.date, onDismiss = { pickDate = false }) { entry = entry.copy(date = it) }
    }
}
