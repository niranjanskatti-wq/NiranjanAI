package com.lovebombing.app.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.lovebombing.app.data.Event
import com.lovebombing.app.data.EventKind
import com.lovebombing.app.data.Plan
import com.lovebombing.app.data.PlanType
import com.lovebombing.app.data.SentMessage
import com.lovebombing.app.data.Settings
import com.lovebombing.app.data.eventsBetween
import com.lovebombing.app.data.formatMinutes
import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.time.format.DateTimeFormatter

private val monthFormat = DateTimeFormatter.ofPattern("MMMM yyyy")

@Composable
fun CalendarScreen(vm: AppViewModel, settings: Settings) {
    var mode by rememberSaveable { mutableStateOf(0) }
    var addPlanFor by remember { mutableStateOf<PlanDraft?>(null) }

    Column(Modifier.fillMaxSize()) {
        Row(Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp), verticalAlignment = Alignment.CenterVertically) {
            Text("Calendar", style = MaterialTheme.typography.headlineMedium, color = Plum, modifier = Modifier.weight(1f))
            Button(onClick = { addPlanFor = PlanDraft() }, colors = ButtonDefaults.buttonColors(containerColor = Rose)) {
                Icon(Icons.Filled.Add, contentDescription = null)
                Spacer(Modifier.width(4.dp))
                Text("Add plan")
            }
        }
        Spacer(Modifier.height(8.dp))
        ChipRow(listOf(0, 1, 2), mode, { listOf("Month", "Plans", "History")[it] }, { mode = it })
        Spacer(Modifier.height(8.dp))
        when (mode) {
            0 -> MonthView(vm, settings, onAddPlan = { addPlanFor = PlanDraft(date = it) })
            1 -> PlansView(vm, settings)
            else -> HistoryList(vm)
        }
    }

    addPlanFor?.let { draft ->
        AddPlanDialog(vm, draft, onDismiss = { addPlanFor = null })
    }
}

@Composable
private fun MonthView(vm: AppViewModel, settings: Settings, onAddPlan: (LocalDate) -> Unit) {
    val sent by vm.sent.collectAsState()
    val today = LocalDate.now()
    var monthEpoch by rememberSaveable { mutableStateOf(YearMonth.from(today).atDay(1).toEpochDay()) }
    var selectedEpoch by rememberSaveable { mutableStateOf(today.toEpochDay()) }
    val month = YearMonth.from(LocalDate.ofEpochDay(monthEpoch))
    val selected = LocalDate.ofEpochDay(selectedEpoch)
    val zone = ZoneId.systemDefault()

    val sentByDay = remember(sent) {
        sent.groupBy { Instant.ofEpochMilli(it.sentAt).atZone(zone).toLocalDate() }
    }
    val items = rememberPlanItems(vm, settings, month.atDay(1), month.atEndOfMonth())
    val events = remember(month, settings, items) {
        eventsBetween(month.atDay(1), month.atEndOfMonth(), settings, items, vm.content.festivals)
    }
    val eventsByDay = remember(events) { events.groupBy { it.date } }
    var confirmDelete by remember { mutableStateOf<Plan?>(null) }

    LazyColumn(contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 24.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        item {
            SectionCard {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = { monthEpoch = month.minusMonths(1).atDay(1).toEpochDay() }) {
                        Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, contentDescription = "Previous month")
                    }
                    Text(month.atDay(1).format(monthFormat), style = MaterialTheme.typography.titleLarge, color = Plum,
                        textAlign = TextAlign.Center, modifier = Modifier.weight(1f))
                    IconButton(onClick = { monthEpoch = month.plusMonths(1).atDay(1).toEpochDay() }) {
                        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = "Next month")
                    }
                }
                Spacer(Modifier.height(8.dp))
                MonthGrid(month, today, selected, sentByDay.keys, eventsByDay.keys) { selectedEpoch = it.toEpochDay() }
                Spacer(Modifier.height(12.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Dot(SentGreen); Spacer(Modifier.width(6.dp))
                    Text("Message sent", style = MaterialTheme.typography.bodySmall, color = Muted)
                    Spacer(Modifier.width(16.dp))
                    Dot(Rose); Spacer(Modifier.width(6.dp))
                    Text("Wish or plan", style = MaterialTheme.typography.bodySmall, color = Muted)
                }
            }
        }
        item {
            SectionCard {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(selected.format(dayFormat), style = MaterialTheme.typography.titleLarge, color = Plum, modifier = Modifier.weight(1f))
                    TextButton(onClick = { onAddPlan(selected) }) { Text("+ Plan") }
                }
                val dayEvents = eventsByDay[selected].orEmpty()
                val daySent = sentByDay[selected].orEmpty().sortedBy { it.sentAt }
                if (dayEvents.isEmpty() && daySent.isEmpty()) {
                    Text("Nothing on this day yet.", style = MaterialTheme.typography.bodyMedium, color = Muted)
                }
                if (dayEvents.isNotEmpty()) {
                    Spacer(Modifier.height(4.dp))
                    Eyebrow("Planned")
                    dayEvents.forEach { e ->
                        val item = e.item
                        if (item == null) PlannedRow(e)
                        else PlanItemRow(vm, item, onDelete = item.plan?.let { p -> { confirmDelete = p } })
                    }
                }
                if (daySent.isNotEmpty()) {
                    Spacer(Modifier.height(12.dp))
                    Eyebrow("Sent", color = SentGreen)
                    daySent.forEach { SentRow(it, showDate = false) }
                }
            }
        }
    }

    confirmDelete?.let { plan ->
        AlertDialog(
            onDismissRequest = { confirmDelete = null },
            title = { Text("Delete plan?") },
            text = { Text("\"${plan.title}\" and its reminders will be removed.") },
            confirmButton = { TextButton(onClick = { vm.deletePlan(plan); confirmDelete = null }) { Text("Delete") } },
            dismissButton = { TextButton(onClick = { confirmDelete = null }) { Text("Cancel") } },
        )
    }
}

@Composable
private fun MonthGrid(
    month: YearMonth,
    today: LocalDate,
    selected: LocalDate,
    sentDays: Set<LocalDate>,
    eventDays: Set<LocalDate>,
    onSelect: (LocalDate) -> Unit,
) {
    val labels = listOf("M", "T", "W", "T", "F", "S", "S")
    Row(Modifier.fillMaxWidth()) {
        labels.forEach { Text(it, Modifier.weight(1f), textAlign = TextAlign.Center, style = MaterialTheme.typography.labelMedium, color = Muted) }
    }
    Spacer(Modifier.height(4.dp))
    val first = month.atDay(1)
    val lead = first.dayOfWeek.value - DayOfWeek.MONDAY.value
    val cells = lead + month.lengthOfMonth()
    val rows = (cells + 6) / 7
    for (r in 0 until rows) {
        Row(Modifier.fillMaxWidth()) {
            for (c in 0 until 7) {
                val index = r * 7 + c - lead
                Box(Modifier.weight(1f).aspectRatio(1f).padding(2.dp), contentAlignment = Alignment.Center) {
                    if (index in 0 until month.lengthOfMonth()) {
                        val day = first.plusDays(index.toLong())
                        DayCell(day, day == today, day == selected, day in sentDays, day in eventDays) { onSelect(day) }
                    }
                }
            }
        }
    }
}

@Composable
private fun DayCell(day: LocalDate, isToday: Boolean, isSelected: Boolean, hasSent: Boolean, hasEvent: Boolean, onClick: () -> Unit) {
    val bg = when {
        isSelected -> Plum
        isToday -> MarigoldSoft
        else -> Color.Transparent
    }
    Column(
        Modifier.fillMaxSize().clip(RoundedCornerShape(14.dp)).background(bg)
            .then(if (isToday && !isSelected) Modifier.border(1.5.dp, Marigold, RoundedCornerShape(14.dp)) else Modifier)
            .clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            day.dayOfMonth.toString(),
            style = MaterialTheme.typography.titleSmall,
            color = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurface,
        )
        Row(Modifier.height(8.dp).padding(top = 2.dp), horizontalArrangement = Arrangement.spacedBy(3.dp)) {
            if (hasSent) Dot(SentGreen)
            if (hasEvent) Dot(if (isSelected) Color(0xFFFFB3C1) else Rose)
        }
    }
}

@Composable
private fun PlannedRow(e: Event) {
    Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.width(4.dp).height(36.dp).clip(CircleShape).background(if (e.kind == EventKind.FESTIVAL) Marigold else Rose))
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(e.title, style = MaterialTheme.typography.titleSmall)
            val sub = buildString {
                append(
                    when (e.kind) {
                        EventKind.BIRTHDAY -> "Birthday"
                        EventKind.ANNIVERSARY -> "Anniversary"
                        EventKind.FESTIVAL -> "Festival"
                        EventKind.PLAN -> e.item?.type?.label ?: "Plan"
                    },
                )
                e.minuteOfDay?.let { append(" · ").append(formatMinutes(it)) }
            }
            Text(sub, style = MaterialTheme.typography.bodySmall, color = Muted)
        }
    }
}

@Composable
fun SentRow(s: SentMessage, showDate: Boolean) {
    val at = Instant.ofEpochMilli(s.sentAt).atZone(ZoneId.systemDefault())
    Column(Modifier.fillMaxWidth().padding(vertical = 8.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Pill(s.category, MaterialTheme.colorScheme.primaryContainer, Plum)
            Spacer(Modifier.width(8.dp))
            val whenText = if (showDate) at.format(dayFormat) + " · " + at.format(timeFormat) else at.format(timeFormat)
            Text(whenText, style = MaterialTheme.typography.bodySmall, color = Muted)
        }
        Spacer(Modifier.height(4.dp))
        Text(s.text, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun HistoryList(vm: AppViewModel) {
    val sent by vm.sent.collectAsState()
    var filter by rememberSaveable { mutableStateOf("All") }
    val categories = remember(sent) { listOf("All") + vm.content.categories.filter { c -> sent.any { it.category == c } } }
    val shown = remember(sent, filter) { if (filter == "All") sent else sent.filter { it.category == filter } }

    ChipRow(categories, filter, { it }, { filter = it })
    LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(0.dp)) {
        item {
            Text("${shown.size} sent", style = MaterialTheme.typography.bodySmall, color = Muted, fontWeight = FontWeight.SemiBold)
        }
        if (shown.isEmpty()) {
            item {
                Text("Messages you share from the app show up here automatically.",
                    style = MaterialTheme.typography.bodyLarge, color = Muted, modifier = Modifier.padding(vertical = 24.dp))
            }
        }
        items(shown, key = { it.id }) { s ->
            SentRow(s, showDate = true)
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
        }
    }
}
