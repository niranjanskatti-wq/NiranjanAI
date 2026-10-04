package com.dosemate.app.ui.medicines

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.CameraAlt
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Image
import androidx.compose.material.icons.rounded.Mic
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.Stop
import androidx.compose.material3.Button
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.core.content.IntentCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.dosemate.app.R
import com.dosemate.app.alarm.BuiltInTone
import com.dosemate.app.data.db.DismissMethod
import com.dosemate.app.data.db.FoodRelation
import com.dosemate.app.data.db.MedIcon
import com.dosemate.app.data.db.MedicineType
import com.dosemate.app.data.db.ToneType
import com.dosemate.app.data.db.VibrationPattern
import com.dosemate.app.data.repo.maskFromWeekdays
import com.dosemate.app.data.repo.weekdaysFromMask
import com.dosemate.app.ui.components.AppCard
import com.dosemate.app.ui.components.ChoiceChips
import com.dosemate.app.ui.components.DatePickDialog
import com.dosemate.app.ui.components.MedicineAvatar
import com.dosemate.app.ui.components.NumberField
import com.dosemate.app.ui.components.SectionHeader
import com.dosemate.app.ui.components.Stepper
import com.dosemate.app.ui.components.SwitchRow
import com.dosemate.app.ui.components.TextInput
import com.dosemate.app.ui.components.TimePickerDialog
import com.dosemate.app.ui.components.medIcon
import com.dosemate.app.ui.theme.LocalSettings
import com.dosemate.app.ui.theme.MedicineColors
import com.dosemate.app.util.TimeFormat
import com.dosemate.core.AlertStyle
import com.dosemate.core.DurationType
import com.dosemate.core.ScheduleType
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.TextStyle
import java.util.Locale

fun typeLabel(type: MedicineType): Int = when (type) {
    MedicineType.TABLET -> R.string.type_tablet
    MedicineType.CAPSULE -> R.string.type_capsule
    MedicineType.CREAM -> R.string.type_cream
    MedicineType.OINTMENT -> R.string.type_ointment
    MedicineType.DROPS -> R.string.type_drops
    MedicineType.SYRUP -> R.string.type_syrup
    MedicineType.INJECTION -> R.string.type_injection
    MedicineType.OTHER -> R.string.type_other
}

fun styleLabel(style: AlertStyle): Int = when (style) {
    AlertStyle.NOTIFICATION -> R.string.style_notification
    AlertStyle.SOUND -> R.string.style_sound
    AlertStyle.ALARM -> R.string.style_alarm
}

private fun foodLabelRes(f: FoodRelation): Int = when (f) {
    FoodRelation.NONE -> R.string.food_none
    FoodRelation.BEFORE -> R.string.food_before
    FoodRelation.AFTER -> R.string.food_after
    FoodRelation.WITH -> R.string.food_with
}

private fun scheduleLabel(t: ScheduleType): Int = when (t) {
    ScheduleType.DAILY -> R.string.sched_daily
    ScheduleType.SPECIFIC_WEEKDAYS -> R.string.sched_weekdays
    ScheduleType.EVERY_X_DAYS -> R.string.sched_every_x
    ScheduleType.WEEKLY -> R.string.sched_weekly
    ScheduleType.TIMES_PER_DAY -> R.string.sched_times_per_day
    ScheduleType.CUSTOM_TIMES -> R.string.sched_custom
}

private fun durationLabel(t: DurationType): Int = when (t) {
    DurationType.ONGOING -> R.string.dur_ongoing
    DurationType.END_DATE -> R.string.dur_end_date
    DurationType.DAYS -> R.string.dur_days
    DurationType.DOSES -> R.string.dur_doses
}

private fun vibrationLabel(v: VibrationPattern): Int = when (v) {
    VibrationPattern.NONE -> R.string.vib_none
    VibrationPattern.GENTLE -> R.string.vib_gentle
    VibrationPattern.STANDARD -> R.string.vib_standard
    VibrationPattern.HEARTBEAT -> R.string.vib_heartbeat
    VibrationPattern.URGENT -> R.string.vib_urgent
}

private fun dismissLabel(d: DismissMethod): Int = when (d) {
    DismissMethod.BUTTONS -> R.string.dismiss_buttons
    DismissMethod.SLIDE -> R.string.dismiss_slide
    DismissMethod.MATH -> R.string.dismiss_math
}

private fun toneLabel(t: ToneType): Int = when (t) {
    ToneType.DEFAULT -> R.string.tone_default
    ToneType.BUILTIN -> R.string.tone_builtin
    ToneType.SYSTEM -> R.string.tone_system
    ToneType.FILE -> R.string.tone_file
    ToneType.VOICE -> R.string.tone_voice
}

@Composable
fun EditMedicineScreen(onBack: () -> Unit, viewModel: EditMedicineViewModel = hiltViewModel()) {
    val d = viewModel.draft
    val context = LocalContext.current
    val use24h = LocalSettings.current.use24h
    val others by viewModel.others.collectAsStateWithLifecycle()
    val prescriptions by viewModel.prescriptions.collectAsStateWithLifecycle()
    var timeDialog by remember { mutableStateOf<Int?>(null) }
    var windowDialog by remember { mutableStateOf<Int?>(null) } // 0 = start, 1 = end
    var dateDialog by remember { mutableStateOf<Int?>(null) } // 0 = start, 1 = end
    var pendingCapture by rememberSaveable { mutableStateOf<String?>(null) }

    val pickPhoto = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        uri?.let(viewModel::importPhoto)
    }
    val takePhoto = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { ok ->
        pendingCapture?.let { viewModel.capturedPhoto(it, ok) }
        pendingCapture = null
    }
    val pickAudio = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        uri?.let(viewModel::importTone)
    }
    val pickRingtone = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            val uri = result.data?.let { IntentCompat.getParcelableExtra(it, RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java) }
            val title = uri?.let { runCatching { RingtoneManager.getRingtone(context, it)?.getTitle(context) }.getOrNull() }
            viewModel.setSystemTone(uri, title)
        }
    }
    val voiceLabel = stringResource(R.string.tone_voice_note)
    val micPermission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) viewModel.startRecording()
    }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text(stringResource(if (viewModel.isNew) R.string.add_medicine else R.string.edit_medicine)) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, stringResource(R.string.back)) } },
                actions = { TextButton(onClick = { viewModel.save(onBack) }) { Text(stringResource(R.string.save)) } },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = MaterialTheme.colorScheme.background),
            )
        },
    ) { padding ->
        if (!viewModel.loaded) return@Scaffold
        LazyColumn(
            Modifier.imePadding(),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = padding.calculateTopPadding(), bottom = 48.dp),
        ) {
            // ---- Basics
            item {
                AppCard {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        MedicineAvatar(d, viewModel.photoDir, 72.dp)
                        Spacer(Modifier.width(14.dp))
                        Column(Modifier.weight(1f)) {
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                FilledTonalButton(onClick = {
                                    pickPhoto.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                                }) { Icon(Icons.Rounded.Image, null) }
                                FilledTonalButton(onClick = {
                                    val (name, uri) = viewModel.newCaptureTarget()
                                    pendingCapture = name
                                    takePhoto.launch(uri)
                                }) { Icon(Icons.Rounded.CameraAlt, null) }
                                if (d.photoPath != null) {
                                    IconButton(onClick = viewModel::removePhoto) { Icon(Icons.Rounded.Delete, stringResource(R.string.remove_photo)) }
                                }
                            }
                            Text(stringResource(R.string.photo_private_hint), style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                    Spacer(Modifier.height(12.dp))
                    TextInput(stringResource(R.string.field_name), d.name, { v -> viewModel.update { it.copy(name = v) } },
                        isError = viewModel.error == R.string.error_name)
                    Spacer(Modifier.height(12.dp))
                    Text(stringResource(R.string.field_type), style = MaterialTheme.typography.labelLarge)
                    ChoiceChips(MedicineType.entries, d.type, { stringResource(typeLabel(it)) }, viewModel::setType)
                    Spacer(Modifier.height(8.dp))
                    Text(stringResource(R.string.field_colour), style = MaterialTheme.typography.labelLarge)
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalArrangement = Arrangement.spacedBy(10.dp),
                        modifier = Modifier.padding(vertical = 8.dp)) {
                        MedicineColors.forEachIndexed { i, c ->
                            Box(
                                Modifier.size(34.dp).clip(CircleShape).background(c)
                                    .border(if (d.colorIndex == i) 3.dp else 0.dp, MaterialTheme.colorScheme.onSurface, CircleShape)
                                    .clickable { viewModel.update { it.copy(colorIndex = i) } },
                            )
                        }
                    }
                    Text(stringResource(R.string.field_icon), style = MaterialTheme.typography.labelLarge)
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.padding(vertical = 8.dp)) {
                        MedIcon.entries.forEach { icon ->
                            val selected = d.icon == icon
                            Box(
                                Modifier.size(42.dp).clip(CircleShape)
                                    .background(if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant)
                                    .clickable { viewModel.update { it.copy(icon = icon) } },
                                contentAlignment = Alignment.Center,
                            ) {
                                Icon(medIcon(icon), null, tint = if (selected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    }
                }
            }

            // ---- Dose
            item {
                SectionHeader(stringResource(R.string.section_dose))
                AppCard {
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        NumberField(stringResource(R.string.field_amount), d.doseAmount, { v -> viewModel.update { it.copy(doseAmount = v) } }, Modifier.weight(1f))
                        TextInput(stringResource(R.string.field_unit), d.doseUnit, { v -> viewModel.update { it.copy(doseUnit = v) } }, Modifier.weight(1.4f))
                    }
                    Spacer(Modifier.height(10.dp))
                    Text(stringResource(R.string.field_food), style = MaterialTheme.typography.labelLarge)
                    ChoiceChips(FoodRelation.entries, d.food, { stringResource(foodLabelRes(it)) }, { f -> viewModel.update { it.copy(food = f) } })
                    Spacer(Modifier.height(8.dp))
                    TextInput(stringResource(R.string.field_instructions), d.instructions, { v -> viewModel.update { it.copy(instructions = v) } }, singleLine = false)
                    Spacer(Modifier.height(8.dp))
                    TextInput(stringResource(R.string.field_notes), d.notes, { v -> viewModel.update { it.copy(notes = v) } }, singleLine = false)
                    Spacer(Modifier.height(8.dp))
                    TextInput(stringResource(R.string.field_warning), d.warning, { v -> viewModel.update { it.copy(warning = v) } }, singleLine = false)
                    Spacer(Modifier.height(8.dp))
                    TextInput(stringResource(R.string.field_banner), d.banner, { v -> viewModel.update { it.copy(banner = v, bannerDismissed = false) } }, singleLine = false)
                }
            }

            // ---- Schedule
            item {
                SectionHeader(stringResource(R.string.schedule))
                AppCard {
                    ChoiceChips(ScheduleType.entries, d.scheduleType, { stringResource(scheduleLabel(it)) }, viewModel::setScheduleType)
                    val locale = Locale.getDefault()
                    when (d.scheduleType) {
                        ScheduleType.SPECIFIC_WEEKDAYS, ScheduleType.WEEKLY -> {
                            val days = weekdaysFromMask(d.weekdays).ifEmpty { setOf(d.startDate.dayOfWeek) }
                            Spacer(Modifier.height(8.dp))
                            FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                DayOfWeek.entries.forEach { day ->
                                    FilterChip(
                                        selected = day in days,
                                        onClick = {
                                            val newDays = if (d.scheduleType == ScheduleType.WEEKLY) setOf(day)
                                            else if (day in days) days - day else days + day
                                            viewModel.update { it.copy(weekdays = maskFromWeekdays(newDays)) }
                                        },
                                        label = { Text(day.getDisplayName(TextStyle.SHORT, locale)) },
                                    )
                                }
                            }
                        }
                        ScheduleType.EVERY_X_DAYS -> Stepper(stringResource(R.string.every_n_days_label), d.intervalDays,
                            { v -> viewModel.update { it.copy(intervalDays = v) } }, 2..60)
                        ScheduleType.TIMES_PER_DAY -> {
                            Stepper(stringResource(R.string.times_per_day_label), d.timesPerDay, { v ->
                                viewModel.update { it.copy(timesPerDay = v) }
                                viewModel.regenerateTimes()
                            }, 1..12)
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                OutlinedButton(onClick = { windowDialog = 0 }, modifier = Modifier.weight(1f)) {
                                    Text(stringResource(R.string.window_from, TimeFormat.time(LocalTime.of(d.windowStartMinute / 60, d.windowStartMinute % 60), use24h)))
                                }
                                OutlinedButton(onClick = { windowDialog = 1 }, modifier = Modifier.weight(1f)) {
                                    Text(stringResource(R.string.window_to, TimeFormat.time(LocalTime.of(d.windowEndMinute / 60, d.windowEndMinute % 60), use24h)))
                                }
                            }
                        }
                        else -> Unit
                    }
                    Spacer(Modifier.height(10.dp))
                    Text(stringResource(R.string.dose_times), style = MaterialTheme.typography.labelLarge)
                    viewModel.times.forEachIndexed { index, row ->
                        TimeRowEditor(
                            row = row,
                            use24h = use24h,
                            defaultStyle = d.alertStyle,
                            canRemove = viewModel.times.size > 1,
                            onPickTime = { timeDialog = index },
                            onChange = { viewModel.setTime(index, it) },
                            onRemove = { viewModel.removeTime(index) },
                        )
                    }
                    if (viewModel.error == R.string.error_times) {
                        Text(stringResource(R.string.error_times), color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                    }
                    TextButton(onClick = viewModel::addTime) {
                        Icon(Icons.Rounded.Add, null)
                        Spacer(Modifier.width(6.dp))
                        Text(stringResource(R.string.add_time))
                    }
                }
            }

            // ---- Duration
            item {
                SectionHeader(stringResource(R.string.section_duration))
                AppCard {
                    OutlinedButton(onClick = { dateDialog = 0 }, modifier = Modifier.fillMaxWidth()) {
                        Text(stringResource(R.string.starts_on, TimeFormat.date(d.startDate)))
                    }
                    Spacer(Modifier.height(8.dp))
                    ChoiceChips(DurationType.entries, d.durationType, { stringResource(durationLabel(it)) }, { t ->
                        viewModel.update {
                            it.copy(
                                durationType = t,
                                durationDays = it.durationDays ?: 7,
                                durationDoses = it.durationDoses ?: 4,
                                endDate = it.endDate ?: it.startDate.plusDays(13),
                            )
                        }
                    })
                    when (d.durationType) {
                        DurationType.END_DATE -> OutlinedButton(onClick = { dateDialog = 1 }, modifier = Modifier.fillMaxWidth()) {
                            Text(stringResource(R.string.dur_until, TimeFormat.date(d.endDate ?: d.startDate)))
                        }
                        DurationType.DAYS -> Stepper(stringResource(R.string.dur_days), d.durationDays ?: 7,
                            { v -> viewModel.update { it.copy(durationDays = v) } }, 1..730)
                        DurationType.DOSES -> Stepper(stringResource(R.string.dur_doses), d.durationDoses ?: 4,
                            { v -> viewModel.update { it.copy(durationDoses = v) } }, 1..1000)
                        DurationType.ONGOING -> Unit
                    }
                }
            }

            // ---- Prescription (which doctor prescribed it)
            item {
                SectionHeader(stringResource(R.string.field_prescription))
                AppCard {
                    var open by remember { mutableStateOf(false) }
                    val current = prescriptions.firstOrNull { it.id == d.prescriptionId }
                    Box {
                        OutlinedButton(onClick = { open = true }, modifier = Modifier.fillMaxWidth()) {
                            Text(current?.let { rx -> rx.doctorName + (rx.date?.let { " · " + TimeFormat.dayMonthYear(it) } ?: "") }
                                ?: stringResource(R.string.prescription_none))
                        }
                        DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
                            DropdownMenuItem(text = { Text(stringResource(R.string.prescription_none)) }, onClick = {
                                open = false
                                viewModel.update { it.copy(prescriptionId = null) }
                            })
                            prescriptions.forEach { rx ->
                                DropdownMenuItem(
                                    text = { Text(rx.doctorName + (rx.date?.let { " · " + TimeFormat.dayMonthYear(it) } ?: "")) },
                                    onClick = {
                                        open = false
                                        viewModel.update { it.copy(prescriptionId = rx.id) }
                                    },
                                )
                            }
                        }
                    }
                    if (prescriptions.isEmpty()) {
                        Text(stringResource(R.string.prescription_add_hint), style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 6.dp))
                    }
                }
            }

            // ---- Linked gap rule
            item {
                SectionHeader(stringResource(R.string.section_link))
                AppCard {
                    var open by remember { mutableStateOf(false) }
                    val leader = others.firstOrNull { it.medicine.id == d.linkedMedicineId }
                    Text(stringResource(R.string.link_explain), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.height(8.dp))
                    Box {
                        OutlinedButton(onClick = { open = true }, modifier = Modifier.fillMaxWidth()) {
                            Text(leader?.medicine?.name ?: stringResource(R.string.link_none))
                        }
                        DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
                            DropdownMenuItem(text = { Text(stringResource(R.string.link_none)) }, onClick = {
                                open = false
                                viewModel.update { it.copy(linkedMedicineId = null) }
                            })
                            others.forEach { o ->
                                DropdownMenuItem(text = { Text(o.medicine.name) }, onClick = {
                                    open = false
                                    viewModel.update { it.copy(linkedMedicineId = o.medicine.id) }
                                })
                            }
                        }
                    }
                    if (d.linkedMedicineId != null) {
                        Stepper(stringResource(R.string.link_gap), d.linkedGapMinutes, { v -> viewModel.update { it.copy(linkedGapMinutes = v) } },
                            5..240, step = 5, format = { context.getString(R.string.minutes_short, it) })
                    }
                }
            }

            // ---- Alerts
            item {
                SectionHeader(stringResource(R.string.section_alerts))
                AppCard {
                    Text(stringResource(R.string.alert_style), style = MaterialTheme.typography.labelLarge)
                    ChoiceChips(AlertStyle.entries, d.alertStyle, { stringResource(styleLabel(it)) }, { s -> viewModel.update { it.copy(alertStyle = s) } })
                    Stepper(stringResource(R.string.pre_alarm), d.preAlarmMinutes, { v -> viewModel.update { it.copy(preAlarmMinutes = v) } },
                        0..120, step = 5, format = { if (it == 0) context.getString(R.string.off) else context.getString(R.string.minutes_short, it) })
                    Stepper(stringResource(R.string.repeat_every), d.repeatIntervalMinutes, { v -> viewModel.update { it.copy(repeatIntervalMinutes = v) } },
                        1..60, format = { context.getString(R.string.minutes_short, it) })
                    Stepper(stringResource(R.string.repeat_max), d.repeatMax, { v -> viewModel.update { it.copy(repeatMax = v) } }, 0..20)

                    Spacer(Modifier.height(8.dp))
                    Text(stringResource(R.string.alarm_tone), style = MaterialTheme.typography.labelLarge)
                    ChoiceChips(ToneType.entries, d.toneType, { stringResource(toneLabel(it)) }, { t ->
                        when (t) {
                            ToneType.DEFAULT -> viewModel.update { it.copy(toneType = t, toneUri = null, toneName = null) }
                            ToneType.BUILTIN -> viewModel.update { it.copy(toneType = t, toneUri = BuiltInTone.CHIME.id, toneName = null) }
                            ToneType.SYSTEM -> pickRingtone.launch(
                                Intent(RingtoneManager.ACTION_RINGTONE_PICKER)
                                    .putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM or RingtoneManager.TYPE_RINGTONE)
                                    .putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                                    .putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true),
                            )
                            ToneType.FILE -> pickAudio.launch(arrayOf("audio/*"))
                            ToneType.VOICE -> viewModel.update { it.copy(toneType = t) }
                        }
                    })
                    when (d.toneType) {
                        ToneType.BUILTIN -> ChoiceChips(BuiltInTone.entries, BuiltInTone.entries.firstOrNull { it.id == d.toneUri },
                            { stringResource(it.label) }, { tone -> viewModel.update { it.copy(toneUri = tone.id) } })
                        ToneType.VOICE -> Row(verticalAlignment = Alignment.CenterVertically) {
                            Button(onClick = {
                                if (viewModel.recording) viewModel.stopRecording(voiceLabel)
                                else micPermission.launch(Manifest.permission.RECORD_AUDIO)
                            }, colors = if (viewModel.recording) androidx.compose.material3.ButtonDefaults.buttonColors(containerColor = Color(0xFFE5484D))
                            else androidx.compose.material3.ButtonDefaults.buttonColors()) {
                                Icon(if (viewModel.recording) Icons.Rounded.Stop else Icons.Rounded.Mic, null)
                                Spacer(Modifier.width(6.dp))
                                Text(stringResource(if (viewModel.recording) R.string.stop_recording else R.string.record_voice))
                            }
                            Spacer(Modifier.width(8.dp))
                            Text(stringResource(R.string.voice_hint), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        ToneType.SYSTEM, ToneType.FILE -> d.toneName?.let { Text(it, style = MaterialTheme.typography.bodyMedium) }
                        ToneType.DEFAULT -> Unit
                    }
                    TextButton(onClick = viewModel::previewTone) {
                        Icon(Icons.Rounded.PlayArrow, null)
                        Spacer(Modifier.width(6.dp))
                        Text(stringResource(R.string.preview_tone))
                    }
                    Text(stringResource(R.string.vibration), style = MaterialTheme.typography.labelLarge)
                    ChoiceChips(VibrationPattern.entries, d.vibration, { stringResource(vibrationLabel(it)) }, { v -> viewModel.update { it.copy(vibration = v) } })
                    SwitchRow(stringResource(R.string.flashlight), d.flashlight, { v -> viewModel.update { it.copy(flashlight = v) } },
                        subtitle = stringResource(R.string.flashlight_hint))
                    Text(stringResource(R.string.dismiss_method), style = MaterialTheme.typography.labelLarge)
                    ChoiceChips(DismissMethod.entries, d.dismissMethod, { stringResource(dismissLabel(it)) }, { m -> viewModel.update { it.copy(dismissMethod = m) } })
                }
            }

            // ---- Stock
            item {
                SectionHeader(stringResource(R.string.section_stock))
                AppCard {
                    SwitchRow(stringResource(R.string.track_stock), d.stockEnabled, { v -> viewModel.update { it.copy(stockEnabled = v) } })
                    if (d.stockEnabled) {
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            NumberField(stringResource(R.string.stock_count), d.stockCount, { v -> viewModel.update { it.copy(stockCount = v, refillAlerted = false) } }, Modifier.weight(1f))
                            NumberField(stringResource(R.string.stock_per_dose), d.stockPerDose, { v -> viewModel.update { it.copy(stockPerDose = v) } }, Modifier.weight(1f))
                        }
                        Spacer(Modifier.height(8.dp))
                        NumberField(stringResource(R.string.refill_threshold), d.refillThreshold, { v -> viewModel.update { it.copy(refillThreshold = v) } }, Modifier.fillMaxWidth())
                    }
                }
            }

            item {
                Spacer(Modifier.height(20.dp))
                viewModel.error?.let {
                    Text(stringResource(it), color = MaterialTheme.colorScheme.error, modifier = Modifier.padding(bottom = 8.dp))
                }
                Button(onClick = { viewModel.save(onBack) }, modifier = Modifier.fillMaxWidth().height(56.dp)) {
                    Text(stringResource(R.string.save))
                }
            }
        }
    }

    timeDialog?.let { index ->
        val row = viewModel.times.getOrNull(index)
        if (row != null) {
            TimePickerDialog(row.time, use24h, onDismiss = { timeDialog = null }) { t ->
                viewModel.setTime(index, row.copy(time = t))
                timeDialog = null
            }
        }
    }
    windowDialog?.let { which ->
        val minute = if (which == 0) d.windowStartMinute else d.windowEndMinute
        TimePickerDialog(LocalTime.of(minute / 60, minute % 60), use24h, onDismiss = { windowDialog = null }) { t ->
            val m = t.hour * 60 + t.minute
            viewModel.update { if (which == 0) it.copy(windowStartMinute = m) else it.copy(windowEndMinute = m) }
            viewModel.regenerateTimes()
            windowDialog = null
        }
    }
    dateDialog?.let { which ->
        DatePickDialog(if (which == 0) d.startDate else d.endDate ?: d.startDate, onDismiss = { dateDialog = null }) { date: LocalDate ->
            viewModel.update { if (which == 0) it.copy(startDate = date) else it.copy(endDate = date) }
        }
    }
}

@Composable
private fun TimeRowEditor(
    row: TimeRow,
    use24h: Boolean,
    defaultStyle: AlertStyle,
    canRemove: Boolean,
    onPickTime: () -> Unit,
    onChange: (TimeRow) -> Unit,
    onRemove: () -> Unit,
) {
    var styleMenu by remember { mutableStateOf(false) }
    Row(Modifier.fillMaxWidth().padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        OutlinedButton(onClick = onPickTime) { Text(TimeFormat.time(row.time, use24h), style = MaterialTheme.typography.titleMedium) }
        Spacer(Modifier.width(8.dp))
        Box(Modifier.weight(1f)) {
            TextButton(onClick = { styleMenu = true }) {
                Text(
                    stringResource(styleLabel(row.style ?: defaultStyle)) + if (row.style == null) " •" else "",
                    style = MaterialTheme.typography.bodySmall,
                )
            }
            DropdownMenu(expanded = styleMenu, onDismissRequest = { styleMenu = false }) {
                DropdownMenuItem(text = { Text(stringResource(R.string.style_same_as_medicine)) }, onClick = {
                    styleMenu = false
                    onChange(row.copy(style = null))
                })
                AlertStyle.entries.forEach { s ->
                    DropdownMenuItem(text = { Text(stringResource(styleLabel(s))) }, onClick = {
                        styleMenu = false
                        onChange(row.copy(style = s))
                    })
                }
            }
        }
        Switch(checked = row.enabled, onCheckedChange = { onChange(row.copy(enabled = it)) })
        if (canRemove) {
            IconButton(onClick = onRemove) { Icon(Icons.Rounded.Delete, stringResource(R.string.delete)) }
        }
    }
}
