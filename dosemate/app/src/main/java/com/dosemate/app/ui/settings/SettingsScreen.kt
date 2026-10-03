package com.dosemate.app.ui.settings

import android.app.Activity
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Backup
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.DeleteForever
import androidx.compose.material.icons.rounded.PictureAsPdf
import androidx.compose.material.icons.rounded.Restore
import androidx.compose.material.icons.rounded.Shield
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.Checkbox
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.dosemate.app.BuildConfig
import com.dosemate.app.R
import com.dosemate.app.alarm.ReminderEngine
import com.dosemate.app.data.repo.AppSettings
import com.dosemate.app.data.repo.BackupManager
import com.dosemate.app.data.repo.SettingsRepository
import com.dosemate.app.data.repo.ThemeMode
import com.dosemate.app.ui.components.AppCard
import com.dosemate.app.ui.components.ChoiceChips
import com.dosemate.app.ui.components.DatePickDialog
import com.dosemate.app.ui.components.NavRow
import com.dosemate.app.ui.components.SectionHeader
import com.dosemate.app.ui.components.Stepper
import com.dosemate.app.ui.components.SwitchRow
import com.dosemate.app.ui.components.TextInput
import com.dosemate.app.ui.components.TimePickerDialog
import com.dosemate.app.ui.medicines.styleLabel
import com.dosemate.app.ui.setup.Permissions
import com.dosemate.app.ui.theme.Accents
import com.dosemate.app.ui.theme.isDarkTheme
import com.dosemate.app.util.TimeFormat
import com.dosemate.core.AlertStyle
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.LocalDate
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val repo: SettingsRepository,
    private val engine: ReminderEngine,
    val backup: BackupManager,
) : ViewModel() {
    val settings: StateFlow<AppSettings> = repo.settings.stateIn(viewModelScope, SharingStarted.Eagerly, repo.current())

    fun update(transform: (AppSettings) -> AppSettings) = repo.update(transform)

    /** Updates settings that affect alarms and re-plans them. */
    fun updateAndReschedule(transform: (AppSettings) -> AppSettings) {
        repo.update(transform)
        viewModelScope.launch { engine.rescheduleAll() }
    }

    fun setPin(pin: String) {
        repo.setPin(pin)
        repo.update { it.copy(appLock = true) }
    }
}

@Composable
fun SettingsScreen(
    onBack: () -> Unit,
    onOpenSetup: () -> Unit,
    onOpenReport: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel(),
) {
    val s by viewModel.settings.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var timeDialog by remember { mutableStateOf<Int?>(null) } // 0 quiet start, 1 quiet end
    var prescribedDialog by remember { mutableStateOf(false) }
    var pinDialog by remember { mutableStateOf(false) }
    var resetDialog by remember { mutableStateOf(false) }
    var restoreUri by remember { mutableStateOf<android.net.Uri?>(null) }

    val exportLauncher = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/zip")) { uri ->
        if (uri != null) scope.launch {
            val ok = viewModel.backup.export(uri)
            Toast.makeText(context, if (ok) R.string.backup_done else R.string.backup_failed, Toast.LENGTH_LONG).show()
        }
    }
    val importLauncher = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri -> restoreUri = uri }

    fun recreate() = (context as? Activity)?.recreate()

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text(stringResource(R.string.settings)) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, stringResource(R.string.back)) } },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = MaterialTheme.colorScheme.background),
            )
        },
    ) { padding ->
        LazyColumn(contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = padding.calculateTopPadding(), bottom = 40.dp)) {
            // ---- Appearance
            item {
                SectionHeader(stringResource(R.string.appearance))
                AppCard {
                    Text(stringResource(R.string.theme), style = MaterialTheme.typography.labelLarge)
                    ChoiceChips(ThemeMode.entries, s.themeMode, {
                        stringResource(
                            when (it) {
                                ThemeMode.SYSTEM -> R.string.theme_system
                                ThemeMode.LIGHT -> R.string.theme_light
                                ThemeMode.DARK -> R.string.theme_dark
                                ThemeMode.AMOLED -> R.string.theme_amoled
                            },
                        )
                    }, { mode -> viewModel.update { it.copy(themeMode = mode) } })
                    Spacer(Modifier.height(10.dp))
                    Text(stringResource(R.string.accent_colour), style = MaterialTheme.typography.labelLarge)
                    val dark = isDarkTheme(s)
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.padding(vertical = 10.dp)) {
                        Accents.forEachIndexed { i, accent ->
                            Box(
                                Modifier.size(38.dp).clip(CircleShape).background(if (dark) accent.dark else accent.light)
                                    .border(if (s.accent == i) 3.dp else 0.dp, MaterialTheme.colorScheme.onSurface, CircleShape)
                                    .clickable { viewModel.update { it.copy(accent = i) } },
                                contentAlignment = Alignment.Center,
                            ) {
                                if (s.accent == i) Icon(Icons.Rounded.Check, stringResource(accent.nameRes), tint = Color.White)
                            }
                        }
                    }
                    SwitchRow(stringResource(R.string.large_text), s.largeText, { v -> viewModel.update { it.copy(largeText = v) } },
                        subtitle = stringResource(R.string.large_text_hint))
                    SwitchRow(stringResource(R.string.use_24h), s.use24h, { v -> viewModel.updateAndReschedule { it.copy(use24h = v) } })
                    Text(stringResource(R.string.language), style = MaterialTheme.typography.labelLarge)
                    ChoiceChips(listOf("system", "en", "kn"), s.language, {
                        when (it) {
                            "en" -> "English"
                            "kn" -> "ಕನ್ನಡ"
                            else -> stringResource(R.string.theme_system)
                        }
                    }, { lang ->
                        if (lang != s.language) {
                            viewModel.updateAndReschedule { it.copy(language = lang) }
                            recreate()
                        }
                    })
                }
            }

            // ---- Reminders
            item {
                SectionHeader(stringResource(R.string.reminders))
                AppCard {
                    Text(stringResource(R.string.default_snooze), style = MaterialTheme.typography.labelLarge)
                    ChoiceChips(s.snoozeOptions, s.defaultSnooze, { stringResource(R.string.minutes_short, it) },
                        { m -> viewModel.update { it.copy(defaultSnooze = m) } })
                    var snoozeText by remember(s.snoozeOptions) { mutableStateOf(s.snoozeOptions.joinToString(", ")) }
                    OutlinedTextField(
                        value = snoozeText,
                        onValueChange = { text ->
                            snoozeText = text
                            val parsed = text.split(",").mapNotNull { it.trim().toIntOrNull() }.filter { it in 1..240 }.distinct()
                            if (parsed.isNotEmpty()) viewModel.update { it.copy(snoozeOptions = parsed.sorted()) }
                        },
                        label = { Text(stringResource(R.string.snooze_options)) },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
                    )
                    Text(stringResource(R.string.default_style_tablets), style = MaterialTheme.typography.labelLarge)
                    ChoiceChips(AlertStyle.entries, s.defaultTabletStyle, { stringResource(styleLabel(it)) },
                        { st -> viewModel.update { it.copy(defaultTabletStyle = st) } })
                    Text(stringResource(R.string.default_style_other), style = MaterialTheme.typography.labelLarge)
                    ChoiceChips(AlertStyle.entries, s.defaultOtherStyle, { stringResource(styleLabel(it)) },
                        { st -> viewModel.update { it.copy(defaultOtherStyle = st) } })
                    Stepper(stringResource(R.string.repeat_every_default), s.repeatInterval, { v -> viewModel.update { it.copy(repeatInterval = v) } },
                        1..60, format = { context.getString(R.string.minutes_short, it) })
                    Stepper(stringResource(R.string.repeat_max_default), s.repeatMax, { v -> viewModel.update { it.copy(repeatMax = v) } }, 0..20)
                    SwitchRow(stringResource(R.string.escalate), s.escalate, { v -> viewModel.update { it.copy(escalate = v) } },
                        subtitle = stringResource(R.string.escalate_hint))
                    SwitchRow(stringResource(R.string.hide_names), s.hideNames, { v -> viewModel.updateAndReschedule { it.copy(hideNames = v) } },
                        subtitle = stringResource(R.string.hide_names_hint))
                    Stepper(stringResource(R.string.late_after), s.lateAfterMinutes, { v -> viewModel.update { it.copy(lateAfterMinutes = v) } },
                        5..240, step = 5, format = { context.getString(R.string.minutes_short, it) })
                    Stepper(stringResource(R.string.missed_after), s.missedAfterMinutes, { v -> viewModel.updateAndReschedule { it.copy(missedAfterMinutes = v) } },
                        30..720, step = 30, format = { context.getString(R.string.minutes_short, it) })
                }
            }

            // ---- Quiet hours
            item {
                SectionHeader(stringResource(R.string.quiet_hours))
                AppCard {
                    SwitchRow(stringResource(R.string.quiet_hours), s.quietEnabled, { v -> viewModel.update { it.copy(quietEnabled = v) } },
                        subtitle = stringResource(R.string.quiet_hours_hint))
                    if (s.quietEnabled) {
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            OutlinedButton(onClick = { timeDialog = 0 }, modifier = Modifier.weight(1f)) {
                                Text(stringResource(R.string.window_from, TimeFormat.time(s.quietStart, s.use24h)))
                            }
                            OutlinedButton(onClick = { timeDialog = 1 }, modifier = Modifier.weight(1f)) {
                                Text(stringResource(R.string.window_to, TimeFormat.time(s.quietEnd, s.use24h)))
                            }
                        }
                        SwitchRow(stringResource(R.string.quiet_alarms_too), s.quietAlarmsToo, { v -> viewModel.update { it.copy(quietAlarmsToo = v) } })
                    }
                }
            }

            // ---- Alarm
            item {
                SectionHeader(stringResource(R.string.alarm_mode))
                AppCard {
                    Text(stringResource(R.string.start_volume, s.alarmStartVolume), style = MaterialTheme.typography.bodyLarge)
                    Slider(s.alarmStartVolume.toFloat(), { v -> viewModel.update { it.copy(alarmStartVolume = v.toInt()) } }, valueRange = 0f..100f)
                    Stepper(stringResource(R.string.ramp_time), s.alarmRampSeconds, { v -> viewModel.update { it.copy(alarmRampSeconds = v) } },
                        0..180, step = 10, format = { context.getString(R.string.seconds_short, it) })
                    SwitchRow(stringResource(R.string.force_volume), s.forceAlarmVolume, { v -> viewModel.update { it.copy(forceAlarmVolume = v) } },
                        subtitle = stringResource(R.string.force_volume_hint))
                    if (s.forceAlarmVolume) {
                        Text(stringResource(R.string.max_volume, s.alarmMaxVolume), style = MaterialTheme.typography.bodyLarge)
                        Slider(s.alarmMaxVolume.toFloat(), { v -> viewModel.update { it.copy(alarmMaxVolume = v.toInt()) } }, valueRange = 10f..100f)
                    }
                    Stepper(stringResource(R.string.ring_duration), s.ringMinutes, { v -> viewModel.update { it.copy(ringMinutes = v) } },
                        1..30, format = { context.getString(R.string.minutes_short, it) })
                    SwitchRow(stringResource(R.string.dnd_bypass), s.dndBypass, { v ->
                        viewModel.update { it.copy(dndBypass = v) }
                        if (v && !Permissions.dndAccessGranted(context)) Permissions.openDndAccess(context)
                    }, subtitle = stringResource(R.string.dnd_bypass_hint))
                }
            }

            // ---- Prescription
            item {
                SectionHeader(stringResource(R.string.prescription))
                AppCard {
                    TextInput(stringResource(R.string.doctor_name), s.doctorName, { v -> viewModel.update { it.copy(doctorName = v) } })
                    Spacer(Modifier.height(8.dp))
                    OutlinedButton(onClick = { prescribedDialog = true }, modifier = Modifier.fillMaxWidth()) {
                        Text(s.prescribedDate?.let { stringResource(R.string.prescribed_on, TimeFormat.dayMonthYear(it)) }
                            ?: stringResource(R.string.set_prescribed_date))
                    }
                    Spacer(Modifier.height(8.dp))
                    TextInput(stringResource(R.string.diet_note), s.dietNote, { v -> viewModel.update { it.copy(dietNote = v) } }, singleLine = false)
                }
            }

            // ---- Security
            item {
                SectionHeader(stringResource(R.string.security))
                AppCard {
                    SwitchRow(stringResource(R.string.app_lock), s.appLock && s.pinHash.isNotEmpty(), { v ->
                        if (v) pinDialog = true else viewModel.update { it.copy(appLock = false) }
                    }, subtitle = stringResource(R.string.app_lock_hint))
                    if (s.appLock && s.pinHash.isNotEmpty()) {
                        SwitchRow(stringResource(R.string.use_biometric), s.biometric, { v -> viewModel.update { it.copy(biometric = v) } })
                        TextButton(onClick = { pinDialog = true }) { Text(stringResource(R.string.change_pin)) }
                    }
                }
            }

            // ---- Reliability & data
            item {
                SectionHeader(stringResource(R.string.reliability))
                AppCard {
                    NavRow(stringResource(R.string.setup_permissions), stringResource(R.string.setup_permissions_hint), Icons.Rounded.Shield, onOpenSetup)
                    NavRow(stringResource(R.string.doctor_report), null, Icons.Rounded.PictureAsPdf, onOpenReport)
                }
                SectionHeader(stringResource(R.string.data))
                AppCard {
                    NavRow(stringResource(R.string.backup), stringResource(R.string.backup_hint), Icons.Rounded.Backup) {
                        exportLauncher.launch("DoseMate-backup-${TimeFormat.dayMonthYear(LocalDate.now())}.zip")
                    }
                    NavRow(stringResource(R.string.restore), stringResource(R.string.restore_hint), Icons.Rounded.Restore) {
                        importLauncher.launch(arrayOf("application/zip", "application/octet-stream", "*/*"))
                    }
                    NavRow(stringResource(R.string.reset), stringResource(R.string.reset_hint), Icons.Rounded.DeleteForever) { resetDialog = true }
                }
                SectionHeader(stringResource(R.string.about))
                AppCard {
                    Text("DoseMate ${BuildConfig.VERSION_NAME}", style = MaterialTheme.typography.titleMedium)
                    Text(stringResource(R.string.about_text), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }

    timeDialog?.let { which ->
        TimePickerDialog(if (which == 0) s.quietStart else s.quietEnd, s.use24h, onDismiss = { timeDialog = null }) { t ->
            viewModel.update { if (which == 0) it.copy(quietStart = t) else it.copy(quietEnd = t) }
            timeDialog = null
        }
    }
    if (prescribedDialog) {
        DatePickDialog(s.prescribedDate ?: LocalDate.now(), onDismiss = { prescribedDialog = false }) { d ->
            viewModel.update { it.copy(prescribedDate = d) }
        }
    }
    if (pinDialog) {
        PinSetupDialog(onDismiss = { pinDialog = false }) { pin ->
            viewModel.setPin(pin)
            pinDialog = false
        }
    }
    restoreUri?.let { uri ->
        AlertDialog(
            onDismissRequest = { restoreUri = null },
            title = { Text(stringResource(R.string.restore)) },
            text = { Text(stringResource(R.string.restore_confirm)) },
            confirmButton = {
                TextButton(onClick = {
                    restoreUri = null
                    scope.launch {
                        val ok = viewModel.backup.restore(uri)
                        Toast.makeText(context, if (ok) R.string.restore_done else R.string.restore_failed, Toast.LENGTH_LONG).show()
                        if (ok) recreate()
                    }
                }) { Text(stringResource(R.string.restore)) }
            },
            dismissButton = { TextButton(onClick = { restoreUri = null }) { Text(stringResource(R.string.cancel)) } },
        )
    }
    if (resetDialog) {
        var reload by remember { mutableStateOf(true) }
        AlertDialog(
            onDismissRequest = { resetDialog = false },
            title = { Text(stringResource(R.string.reset)) },
            text = {
                Column {
                    Text(stringResource(R.string.reset_confirm))
                    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.clickable { reload = !reload }) {
                        Checkbox(checked = reload, onCheckedChange = { reload = it })
                        Text(stringResource(R.string.reset_reload_plan))
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    resetDialog = false
                    scope.launch {
                        viewModel.backup.reset(reload)
                        recreate()
                    }
                }) { Text(stringResource(R.string.reset), color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = { TextButton(onClick = { resetDialog = false }) { Text(stringResource(R.string.cancel)) } },
        )
    }
}

@Composable
private fun PinSetupDialog(onDismiss: () -> Unit, onSet: (String) -> Unit) {
    var pin by remember { mutableStateOf("") }
    var confirm by remember { mutableStateOf("") }
    val valid = pin.length in 4..8 && pin == confirm
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.set_pin)) },
        text = {
            Column {
                listOf(
                    Triple(R.string.pin, pin) { v: String -> pin = v },
                    Triple(R.string.confirm_pin, confirm) { v: String -> confirm = v },
                ).forEach { (label, value, set) ->
                    OutlinedTextField(
                        value = value,
                        onValueChange = { set(it.filter(Char::isDigit).take(8)) },
                        label = { Text(stringResource(label)) },
                        singleLine = true,
                        visualTransformation = PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                    )
                }
                Text(stringResource(R.string.pin_hint), style = MaterialTheme.typography.bodySmall)
            }
        },
        confirmButton = { TextButton(onClick = { onSet(pin) }, enabled = valid) { Text(stringResource(R.string.save)) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.cancel)) } },
    )
}
