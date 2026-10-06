package com.lovebombing.app.ui

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
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.lovebombing.app.data.AutoPlanSetting
import com.lovebombing.app.data.AutoPlans
import com.lovebombing.app.data.AutoTemplate
import com.lovebombing.app.data.PlanStatus
import com.lovebombing.app.data.Recurrence
import com.lovebombing.app.data.Settings
import com.lovebombing.app.data.formatMinutes
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.YearMonth

/** Automatic routines (on/off + change), this month's score, and the next two weeks of plans. */
@Composable
fun PlansView(vm: AppViewModel, settings: Settings) {
    val autos by vm.autoPlans.collectAsState()
    val today = LocalDate.now()
    val month = YearMonth.from(today)
    val monthItems = rememberPlanItems(vm, settings, month.atDay(1), today)
    val upcoming = rememberPlanItems(vm, settings, today, today.plusDays(14))
    var editing by remember { mutableStateOf<AutoTemplate?>(null) }
    val name = settings.wifeName.trim().ifEmpty { "her" }

    LazyColumn(contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 24.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        item {
            val counts = monthItems.groupingBy { it.effectiveStatus() }.eachCount()
            SectionCard(container = MarigoldSoft) {
                Eyebrow("This month", color = Plum)
                Spacer(Modifier.height(8.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Stat("Done", counts[PlanStatus.DONE] ?: 0, SentGreen)
                    Stat("Not done", counts[PlanStatus.NOT_DONE] ?: 0, Color(0xFFB3263E))
                    Stat("Skipped", counts[PlanStatus.SKIPPED] ?: 0, Muted)
                    Stat("Planned", counts[PlanStatus.PENDING] ?: 0, Plum)
                }
            }
        }
        item {
            SectionCard {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Eyebrow("Automatic routines")
                    Spacer(Modifier.weight(1f))
                    TextButton(onClick = { vm.setAllAutoPlans(true) }) { Text("All on") }
                    TextButton(onClick = { vm.setAllAutoPlans(false) }) { Text("All off") }
                }
                Text(
                    "These plans fill your calendar by themselves and remind you before each one. Switch any off, or tap Change to move its day or time.",
                    style = MaterialTheme.typography.bodySmall, color = Muted,
                )
                AutoPlans.templates.forEachIndexed { i, t ->
                    val cfg = autos[t.id]
                    val on = cfg?.enabled ?: t.defaultOn
                    if (i > 0) HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
                    Row(Modifier.fillMaxWidth().padding(vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text(t.title.replace("{name}", name), style = MaterialTheme.typography.titleSmall,
                                color = if (on) MaterialTheme.colorScheme.onSurface else Muted)
                            Text(AutoPlans.describe(t, cfg), style = MaterialTheme.typography.bodySmall, color = Muted)
                            if (on) TextButton(onClick = { editing = t }, contentPadding = PaddingValues(0.dp)) { Text("Change") }
                        }
                        Switch(
                            checked = on,
                            onCheckedChange = { vm.saveAutoPlan((cfg ?: AutoPlanSetting(t.id, it)).copy(enabled = it)) },
                            colors = SwitchDefaults.colors(checkedTrackColor = Rose, checkedThumbColor = Color.White),
                        )
                    }
                }
                if (settings.birthday == null || settings.anniversary == null) {
                    Text("Add her birthday and your anniversary in Settings to switch on those routines.",
                        style = MaterialTheme.typography.bodySmall, color = Rose)
                }
            }
        }
        item {
            SectionCard {
                Eyebrow("Next 14 days")
                if (upcoming.isEmpty()) Text("Nothing planned. Switch on a routine above.", color = Muted)
                upcoming.forEachIndexed { i, item ->
                    if (i > 0) HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
                    PlanItemRow(vm, item, showDate = true)
                }
            }
        }
    }

    editing?.let { t -> RoutineDialog(vm, t, autos[t.id], onDismiss = { editing = null }) }
}

@Composable
private fun Stat(label: String, value: Int, color: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value.toString(), style = MaterialTheme.typography.headlineSmall, color = color, fontWeight = FontWeight.Bold)
        Text(label, style = MaterialTheme.typography.labelSmall, color = Muted)
    }
}

/** Change a routine's day (weekly/monthly) and time for all future occurrences. */
@Composable
private fun RoutineDialog(vm: AppViewModel, t: AutoTemplate, cfg: AutoPlanSetting?, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val defaultDay = when (val r = t.recurrence) {
        is Recurrence.Weekly -> r.day
        is Recurrence.MonthlyNth -> r.day
        else -> null
    }
    var day by remember { mutableStateOf(cfg?.dayOfWeek?.let { DayOfWeek.of(it) } ?: defaultDay) }
    var minutes by remember { mutableStateOf(cfg?.minuteOfDay ?: t.minuteOfDay) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Change routine") },
        text = {
            Column {
                Text(t.idea, style = MaterialTheme.typography.bodyMedium)
                if (t.dayAdjustable && day != null) {
                    Spacer(Modifier.height(12.dp))
                    Text("Day", style = MaterialTheme.typography.labelLarge, color = Muted)
                    ChipRow(DayOfWeek.entries, day, { it.name.take(3).lowercase().replaceFirstChar { c -> c.uppercase() } }, { day = it },
                        modifier = Modifier.padding(top = 4.dp))
                }
                Spacer(Modifier.height(12.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("Time", style = MaterialTheme.typography.labelLarge, color = Muted, modifier = Modifier.width(60.dp))
                    OutlinedButton(onClick = { pickTime(context, minutes) { minutes = it } }) { Text(formatMinutes(minutes)) }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = {
                vm.saveAutoPlan(
                    (cfg ?: AutoPlanSetting(t.id, true)).copy(
                        enabled = true,
                        minuteOfDay = minutes,
                        dayOfWeek = if (t.dayAdjustable) day?.value else null,
                    ),
                )
                onDismiss()
            }) { Text("Save") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}
