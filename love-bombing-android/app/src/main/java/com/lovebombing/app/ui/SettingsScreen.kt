package com.lovebombing.app.ui

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.lovebombing.app.data.Settings
import com.lovebombing.app.data.formatMinutes
import java.time.LocalDate

/** Name, dates and daily times. Shared by onboarding and settings. */
@Composable
fun ProfileFields(s: Settings, onChange: (Settings) -> Unit) {
    val context = LocalContext.current
    OutlinedTextField(
        value = s.wifeName,
        onValueChange = { onChange(s.copy(wifeName = it)) },
        label = { Text("Her name or pet name") },
        placeholder = { Text("e.g. Priya, Jaanu, Chinnu") },
        singleLine = true,
        modifier = Modifier.fillMaxWidth(),
    )
    Spacer(Modifier.height(12.dp))
    PickerRow("Her birthday", s.birthday?.let { LocalDate.ofEpochDay(it).format(dayFormat) } ?: "Set date") {
        pickDate(context, s.birthday?.let { LocalDate.ofEpochDay(it) } ?: LocalDate.now().minusYears(28)) {
            onChange(s.copy(birthday = it.toEpochDay()))
        }
    }
    PickerRow("Wedding anniversary", s.anniversary?.let { LocalDate.ofEpochDay(it).format(dayFormat) } ?: "Set date") {
        pickDate(context, s.anniversary?.let { LocalDate.ofEpochDay(it) } ?: LocalDate.now().minusYears(3)) {
            onChange(s.copy(anniversary = it.toEpochDay()))
        }
    }
    PickerRow("Good-morning time", formatMinutes(s.morningMinutes)) {
        pickTime(context, s.morningMinutes) { onChange(s.copy(morningMinutes = it)) }
    }
    PickerRow("Good-night time", formatMinutes(s.nightMinutes)) {
        pickTime(context, s.nightMinutes) { onChange(s.copy(nightMinutes = it)) }
    }
}

@Composable
private fun PickerRow(label: String, value: String, onClick: () -> Unit) {
    Row(Modifier.fillMaxWidth().padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
        OutlinedButton(onClick = onClick) { Text(value) }
    }
}

@Composable
private fun ToggleRow(title: String, subtitle: String?, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyLarge)
            if (subtitle != null) Text(subtitle, style = MaterialTheme.typography.bodySmall, color = Muted)
        }
        Switch(
            checked = checked, onCheckedChange = onChange,
            colors = SwitchDefaults.colors(checkedTrackColor = Rose, checkedThumbColor = Color.White),
        )
    }
}

@Composable
fun OnboardingScreen(onDone: (Settings) -> Unit) {
    var s by remember { mutableStateOf(Settings()) }
    Column(
        Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background).statusBarsPadding().imePadding()
            .verticalScroll(rememberScrollState()).padding(20.dp),
    ) {
        Box(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(28.dp))
                .background(Brush.linearGradient(listOf(PlumLight, Plum))).padding(24.dp),
        ) {
            Column {
                Text("❤️", style = MaterialTheme.typography.displaySmall)
                Spacer(Modifier.height(8.dp))
                Text("Love Bombing", style = MaterialTheme.typography.displaySmall, color = Color.White)
                Spacer(Modifier.height(8.dp))
                Text(
                    "Daily messages, timely reminders and ideas to keep the romance alive. Everything stays on this phone.",
                    style = MaterialTheme.typography.bodyLarge, color = Color.White.copy(alpha = 0.9f),
                )
            }
        }
        Spacer(Modifier.height(24.dp))
        Text("Tell me about her", style = MaterialTheme.typography.headlineSmall, color = Plum)
        Spacer(Modifier.height(12.dp))
        ProfileFields(s) { s = it }
        Spacer(Modifier.height(8.dp))
        Text("You can change all of this later in Settings.", style = MaterialTheme.typography.bodySmall, color = Muted)
        Spacer(Modifier.height(24.dp))
        Button(
            onClick = { onDone(s.copy(wifeName = s.wifeName.trim())) },
            enabled = s.wifeName.isNotBlank(),
            modifier = Modifier.fillMaxWidth().height(56.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Rose),
        ) { Text("Let's go", style = MaterialTheme.typography.titleMedium) }
    }
}

@Composable
fun SettingsScreen(vm: AppViewModel, settings: Settings) {
    val context = LocalContext.current
    val sender = LocalSender.current
    var draftName by remember(settings.wifeName) { mutableStateOf(settings.wifeName) }
    var confirmImport by remember { mutableStateOf<android.net.Uri?>(null) }
    // Re-read permission state whenever we come back from system settings.
    var resumeTick by remember { mutableIntStateOf(0) }
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(lifecycle) {
        val observer = LifecycleEventObserver { _, e -> if (e == Lifecycle.Event.ON_RESUME) resumeTick++ }
        lifecycle.addObserver(observer)
        onDispose { lifecycle.removeObserver(observer) }
    }
    val notifOk = remember(resumeTick) { notificationsAllowed(context) }
    val exactOk = remember(resumeTick) { !needsExactAlarm(context) }

    val exportLauncher = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/json")) { uri ->
        if (uri != null) vm.export(uri) { err -> sender.toast(if (err == null) "Backup saved" else "Backup failed: ${err.message}") }
    }
    val importLauncher = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) confirmImport = uri
    }

    Column(Modifier.fillMaxSize().imePadding().verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("Settings", style = MaterialTheme.typography.headlineMedium, color = Plum)

        SectionCard {
            Eyebrow("About her")
            Spacer(Modifier.height(12.dp))
            ProfileFields(settings.copy(wifeName = draftName)) { updated ->
                draftName = updated.wifeName
                // Save everything except half-typed names, which are saved below.
                if (updated.copy(wifeName = settings.wifeName) != settings) vm.saveSettings(updated.copy(wifeName = settings.wifeName))
            }
            if (draftName.trim() != settings.wifeName && draftName.isNotBlank()) {
                TextButton(onClick = { vm.saveSettings(settings.copy(wifeName = draftName.trim())) }) { Text("Save name") }
            }
        }

        SectionCard {
            Eyebrow("Reminders")
            Spacer(Modifier.height(4.dp))
            ToggleRow("Good morning", "Daily at ${formatMinutes(settings.morningMinutes)}", settings.morningOn) { vm.saveSettings(settings.copy(morningOn = it)) }
            ToggleRow("Good night", "Daily at ${formatMinutes(settings.nightMinutes)}", settings.nightOn) { vm.saveSettings(settings.copy(nightOn = it)) }
            ToggleRow("Mid-day nudge", "\"Send her something that isn't about chores.\"", settings.middayOn) { vm.saveSettings(settings.copy(middayOn = it)) }
            if (settings.middayOn) {
                PickerRow("Nudge time", formatMinutes(settings.middayMinutes)) {
                    pickTime(context, settings.middayMinutes) { vm.saveSettings(settings.copy(middayMinutes = it)) }
                }
            }
            ToggleRow("Birthday", "7 days before, 1 day before and on the day", settings.birthdayOn) { vm.saveSettings(settings.copy(birthdayOn = it)) }
            ToggleRow("Anniversary", "7 days before, 1 day before and on the day", settings.anniversaryOn) { vm.saveSettings(settings.copy(anniversaryOn = it)) }
            ToggleRow("Festivals", "3 days before Diwali, Valentine's, Ugadi and more", settings.festivalsOn) { vm.saveSettings(settings.copy(festivalsOn = it)) }
            ToggleRow("Plan reminders", "Automatic routines and your own plans: 15 min before; date nights and gifts also 1 day before", settings.plansOn) { vm.saveSettings(settings.copy(plansOn = it)) }
            if (!notifOk || !exactOk) {
                HorizontalDivider(Modifier.padding(vertical = 8.dp), color = MaterialTheme.colorScheme.outlineVariant)
                if (!notifOk) {
                    Text("Notifications are off for this app, so reminders can't appear.", style = MaterialTheme.typography.bodySmall, color = Rose)
                    TextButton(onClick = {
                        context.startActivity(
                            android.content.Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, context.packageName),
                        )
                    }) { Text("Turn on notifications") }
                }
                if (!exactOk) {
                    Text("Exact alarms are off, so reminders may arrive a few minutes late.", style = MaterialTheme.typography.bodySmall, color = Rose)
                    TextButton(onClick = { openExactAlarmSettings(context) }) { Text("Allow exact alarms") }
                }
            }
        }

        SectionCard {
            Eyebrow("Backup")
            Spacer(Modifier.height(8.dp))
            Text(
                "Save everything (settings, history, favourites, plans, wishlist) to a file on your phone, or restore from one. Nothing leaves your phone unless you move the file yourself.",
                style = MaterialTheme.typography.bodyMedium,
            )
            Spacer(Modifier.height(12.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Button(
                    onClick = { exportLauncher.launch("love-bombing-backup-${LocalDate.now()}.json") },
                    colors = ButtonDefaults.buttonColors(containerColor = Plum),
                ) { Text("Export") }
                OutlinedButton(onClick = { importLauncher.launch(arrayOf("application/json", "text/plain", "application/octet-stream")) }) {
                    Text("Import")
                }
            }
        }

        SectionCard(container = MaterialTheme.colorScheme.surfaceVariant) {
            Eyebrow("Privacy", color = Plum)
            Spacer(Modifier.height(6.dp))
            Text(
                "Love Bombing works 100% offline. It has no internet permission, no accounts, no ads and no tracking. WhatsApp sharing just hands the text to WhatsApp on your phone.",
                style = MaterialTheme.typography.bodySmall, color = Muted,
            )
        }
    }

    confirmImport?.let { uri ->
        AlertDialog(
            onDismissRequest = { confirmImport = null },
            title = { Text("Restore backup?") },
            text = { Text("This replaces everything currently in the app with the backup's contents.") },
            confirmButton = {
                TextButton(onClick = {
                    confirmImport = null
                    vm.import(uri) { err -> sender.toast(if (err == null) "Backup restored" else "Restore failed: ${err.message}") }
                }) { Text("Restore") }
            },
            dismissButton = { TextButton(onClick = { confirmImport = null }) { Text("Cancel") } },
        )
    }
}
