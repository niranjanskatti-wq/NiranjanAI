package com.lovebombing.app.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.lovebombing.app.R
import com.lovebombing.app.data.Event
import com.lovebombing.app.data.EventKind
import com.lovebombing.app.data.Settings
import com.lovebombing.app.data.Suggest
import com.lovebombing.app.data.eventsBetween
import com.lovebombing.app.data.formatMinutes
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.temporal.ChronoUnit

@Composable
fun HomeScreen(vm: AppViewModel, settings: Settings, onOpenTab: (Tab) -> Unit) {
    val sender = LocalSender.current
    val sent by vm.sent.collectAsState()
    val plans by vm.plans.collectAsState()
    val favorites by vm.favorites.collectAsState()
    val offset by vm.homeOffset.collectAsState()
    val content = vm.content
    val today = LocalDate.now()
    val now = LocalTime.now()

    val events = remember(settings, plans, today) {
        eventsBetween(today, today.plusDays(400), settings, plans, content.festivals)
    }
    val startOfToday = remember(today) { today.atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli() }
    // Exclude only messages sent before today, so today's pick stays put (with a tick) after sharing.
    val recent = remember(sent, startOfToday) { Suggest.recentIds(sent.filter { it.sentAt < startOfToday }) }
    val sentIds = remember(sent) { Suggest.recentIds(sent) }
    val (category, festivalKey) = Suggest.categoryFor(today, now, events)
    val message = remember(category, festivalKey, recent, offset, today) {
        Suggest.pick(content, category, festivalKey, recent, today, offset)
    }
    val streak = remember(sent, today) { Suggest.streak(sent, today) }
    val sentToday = remember(sent, startOfToday) { sent.any { it.sentAt >= startOfToday } }

    LazyColumn(
        contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item { Greeting(settings.wifeName, today, now) }
        item { StreakCard(streak, sentToday) }
        if (message != null) {
            item {
                Eyebrow("Today's message")
                Spacer(Modifier.height(8.dp))
                MessageCard(
                    text = sender.textOf(message),
                    category = message.category,
                    isFavorite = message.id in favorites,
                    isSent = message.id in sentIds,
                    onWhatsApp = { sender.whatsApp(message) },
                    onCopy = { sender.copy(message) },
                    onFavorite = { vm.toggleFavorite(message.id) },
                    extra = { TextButton(onClick = { vm.homeOffset.value = offset + 1 }) { Text("Next") } },
                )
            }
        }
        item { MoveCard(content.moveFor(today)) }
        item { UpcomingCard(events.take(3), today, onOpenCalendar = { onOpenTab(Tab.CALENDAR) }) }
    }
}

@Composable
private fun Greeting(name: String, today: LocalDate, now: LocalTime) {
    val hello = when (now.hour) {
        in 4..11 -> "Good morning"
        in 12..16 -> "Good afternoon"
        else -> "Good evening"
    }
    Box(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(28.dp))
            .background(Brush.linearGradient(listOf(PlumLight, Plum)))
            .padding(24.dp),
    ) {
        Column {
            Text(today.format(longDayFormat), style = MaterialTheme.typography.labelLarge, color = MarigoldSoft)
            Spacer(Modifier.height(6.dp))
            Text("$hello 👋", style = MaterialTheme.typography.headlineMedium, color = Color.White)
            Spacer(Modifier.height(6.dp))
            val who = name.trim().ifEmpty { "her" }
            Text("Make $who smile today.", style = MaterialTheme.typography.bodyLarge, color = Color.White.copy(alpha = 0.85f))
        }
    }
}

@Composable
private fun StreakCard(streak: Int, sentToday: Boolean) {
    SectionCard(container = MarigoldSoft) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(52.dp).clip(RoundedCornerShape(16.dp)).background(Marigold), contentAlignment = Alignment.Center) {
                Icon(painterResource(R.drawable.ic_flame), contentDescription = null, tint = Color.White)
            }
            Spacer(Modifier.width(16.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    if (streak == 1) "1-day streak" else "$streak-day streak",
                    style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onTertiaryContainer,
                )
                Text(
                    when {
                        sentToday -> "You've sent her something today. Nice work."
                        streak > 0 -> "Send a message today to keep it going."
                        else -> "Send her a message to start a streak."
                    },
                    style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onTertiaryContainer,
                )
            }
        }
    }
}

@Composable
private fun MoveCard(move: String) {
    SectionCard(container = MaterialTheme.colorScheme.secondaryContainer) {
        Eyebrow("Today's move", color = Plum)
        Spacer(Modifier.height(8.dp))
        Text(move, style = MaterialTheme.typography.titleLarge, color = Plum)
    }
}

@Composable
private fun UpcomingCard(events: List<Event>, today: LocalDate, onOpenCalendar: () -> Unit) {
    SectionCard {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Eyebrow("Coming up")
            Spacer(Modifier.weight(1f))
            TextButton(onClick = onOpenCalendar) { Text("Calendar") }
        }
        if (events.isEmpty()) {
            Text("Nothing planned yet. Add a date night from the Calendar tab.", style = MaterialTheme.typography.bodyMedium, color = Muted)
        }
        events.forEachIndexed { i, e ->
            if (i > 0) HorizontalDivider(Modifier.padding(vertical = 10.dp), color = MaterialTheme.colorScheme.outlineVariant)
            EventRow(e, today)
        }
    }
}

@Composable
fun EventRow(e: Event, today: LocalDate) {
    val days = ChronoUnit.DAYS.between(today, e.date)
    val whenText = when (days) {
        0L -> "Today"
        1L -> "Tomorrow"
        else -> "In $days days"
    }
    val (dotColor, label) = when (e.kind) {
        EventKind.BIRTHDAY -> Rose to "Birthday"
        EventKind.ANNIVERSARY -> Rose to "Anniversary"
        EventKind.FESTIVAL -> Marigold to "Festival"
        EventKind.PLAN -> Plum to (e.plan?.let { com.lovebombing.app.data.PlanType.of(it.type).label } ?: "Plan")
    }
    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(vertical = 4.dp)) {
        Column(
            Modifier.width(56.dp).clip(RoundedCornerShape(14.dp)).background(MaterialTheme.colorScheme.surfaceVariant).padding(vertical = 6.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(e.date.dayOfMonth.toString(), style = MaterialTheme.typography.titleLarge, color = Plum)
            Text(e.date.month.name.take(3), style = MaterialTheme.typography.labelSmall, color = Muted)
        }
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f)) {
            Text(e.title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Dot(dotColor)
                Spacer(Modifier.width(6.dp))
                val time = e.minuteOfDay?.let { " · " + formatMinutes(it) } ?: ""
                Text("$label · $whenText$time", style = MaterialTheme.typography.bodySmall, color = Muted)
            }
        }
    }
}
