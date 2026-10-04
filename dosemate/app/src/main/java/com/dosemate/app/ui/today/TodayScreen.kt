package com.dosemate.app.ui.today

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Info
import androidx.compose.material.icons.rounded.Link
import androidx.compose.material.icons.rounded.MedicalServices
import androidx.compose.material.icons.rounded.NotificationsActive
import androidx.compose.material.icons.rounded.Restaurant
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material.icons.rounded.Snooze
import androidx.compose.material.icons.rounded.WarningAmber
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.dosemate.app.R
import com.dosemate.app.alarm.SkipReasonDialog
import com.dosemate.app.data.repo.DoseItem
import com.dosemate.app.ui.components.AppCard
import com.dosemate.app.ui.components.EmptyState
import com.dosemate.app.ui.components.GradientBackground
import com.dosemate.app.ui.components.MedicineAvatar
import com.dosemate.app.ui.components.Pill
import com.dosemate.app.ui.components.ProgressRing
import com.dosemate.app.ui.components.SectionHeader
import com.dosemate.app.ui.theme.LocalSettings
import com.dosemate.app.ui.theme.StatusColors
import com.dosemate.app.ui.theme.medicineColor
import com.dosemate.app.util.TimeFormat
import com.dosemate.app.util.doseLine
import com.dosemate.core.DayPeriod
import com.dosemate.core.DoseStatus
import kotlinx.coroutines.delay
import java.io.File
import java.time.Duration
import java.time.LocalDateTime
import java.time.LocalTime

@Composable
fun TodayScreen(
    onOpenSettings: () -> Unit,
    onOpenMedicine: (Long) -> Unit,
    onAddMedicine: () -> Unit,
    viewModel: TodayViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val use24h = LocalSettings.current.use24h
    val grouped = state.items.groupBy { DayPeriod.of(it.dueAt.toLocalTime()) }
    var skipFor by remember { mutableStateOf<DoseItem?>(null) }
    val haptics = LocalHapticFeedback.current

    GradientBackground {
        LazyColumn(
            Modifier.fillMaxWidth().statusBarsPadding(),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(start = 20.dp, end = 20.dp, bottom = 32.dp),
        ) {
            item {
                Row(Modifier.fillMaxWidth().padding(top = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(greeting(), style = MaterialTheme.typography.headlineMedium)
                        Text(
                            TimeFormat.date(state.date),
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    IconButton(onClick = onOpenSettings) { Icon(Icons.Rounded.Settings, stringResource(R.string.settings)) }
                }
                Spacer(Modifier.height(16.dp))
                HeroCard(state, use24h)
            }

            if (state.recentlyMissed.isNotEmpty()) {
                item { MissedCard(state.recentlyMissed, use24h, onTakeLate = viewModel::takenLate, onDismiss = viewModel::dismissMissed) }
            }
            items(state.banners, key = { "banner${it.id}" }) { med ->
                BannerCard(
                    icon = Icons.Rounded.Info,
                    title = med.name,
                    text = med.banner,
                    color = MaterialTheme.colorScheme.tertiary,
                    onDismiss = { viewModel.dismissBanner(med.id) },
                )
            }
            items(state.dietNotes, key = { "diet${it.first}${it.second.hashCode()}" }) { (doctor, notes) ->
                BannerCard(
                    icon = Icons.Rounded.Restaurant,
                    title = stringResource(R.string.diet_note) + " · " + doctor,
                    text = notes,
                    color = MaterialTheme.colorScheme.primary,
                    onDismiss = null,
                )
            }

            if (state.loaded && state.items.isEmpty()) {
                item {
                    EmptyState(
                        Icons.Rounded.MedicalServices,
                        stringResource(if (state.hasMedicines) R.string.today_empty_title else R.string.today_no_meds_title),
                        stringResource(if (state.hasMedicines) R.string.today_empty_text else R.string.today_no_meds_text),
                    )
                    if (!state.hasMedicines) {
                        Button(onClick = onAddMedicine, modifier = Modifier.fillMaxWidth()) {
                            Icon(Icons.Rounded.Add, null)
                            Spacer(Modifier.width(8.dp))
                            Text(stringResource(R.string.add_medicine))
                        }
                    }
                }
            }

            DayPeriod.entries.forEach { period ->
                val list = grouped[period].orEmpty()
                if (list.isNotEmpty()) {
                    item(key = "header$period") { SectionHeader(stringResource(periodLabel(period))) }
                    items(list, key = { "${it.slot.id}-${it.scheduledAt}" }) { item ->
                        DoseCard(
                            item = item,
                            photoDir = viewModel.photoDir,
                            use24h = use24h,
                            snoozeOptions = LocalSettings.current.snoozeOptions,
                            onTake = {
                                haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                                viewModel.markTaken(item)
                            },
                            onSkip = { skipFor = item },
                            onSnooze = { viewModel.snooze(item, it) },
                            onUndo = { viewModel.undo(item) },
                            onOpen = { onOpenMedicine(item.med.medicine.id) },
                        )
                        Spacer(Modifier.height(10.dp))
                    }
                }
            }
        }
    }

    skipFor?.let { item ->
        SkipReasonDialog(onDismiss = { skipFor = null }, onConfirm = { reason ->
            viewModel.skip(item, reason)
            skipFor = null
        })
    }
}

@Composable
private fun greeting(): String {
    val hour = LocalTime.now().hour
    return stringResource(
        when (hour) {
            in 4..11 -> R.string.greeting_morning
            in 12..16 -> R.string.greeting_afternoon
            in 17..21 -> R.string.greeting_evening
            else -> R.string.greeting_night
        },
    )
}

fun periodLabel(period: DayPeriod): Int = when (period) {
    DayPeriod.MORNING -> R.string.period_morning
    DayPeriod.AFTERNOON -> R.string.period_afternoon
    DayPeriod.EVENING -> R.string.period_evening
    DayPeriod.NIGHT -> R.string.period_night
}

@Composable
private fun HeroCard(state: TodayState, use24h: Boolean) {
    val total = state.items.size
    val done = state.items.count { it.status == DoseStatus.TAKEN || it.status == DoseStatus.LATE }
    var now by remember { mutableStateOf(LocalDateTime.now()) }
    LaunchedEffect(Unit) {
        while (true) {
            now = LocalDateTime.now()
            delay(1000)
        }
    }
    AppCard(containerColor = MaterialTheme.colorScheme.primaryContainer) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            ProgressRing(if (total == 0) 0f else done.toFloat() / total, size = 112.dp, stroke = 11.dp) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("$done/$total", style = MaterialTheme.typography.headlineSmall)
                    Text(stringResource(R.string.taken_lower), style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Spacer(Modifier.width(20.dp))
            Column(Modifier.weight(1f)) {
                val next = state.next
                if (next == null) {
                    Text(stringResource(R.string.all_done_title), style = MaterialTheme.typography.titleLarge)
                    Text(stringResource(R.string.all_done_text), style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                } else {
                    val at = next.snoozedUntil ?: next.dueAt
                    Text(stringResource(R.string.next_dose), style = MaterialTheme.typography.labelLarge,
                        color = MaterialTheme.colorScheme.primary)
                    Text(next.med.medicine.name, style = MaterialTheme.typography.titleLarge, maxLines = 2,
                        overflow = TextOverflow.Ellipsis)
                    Spacer(Modifier.height(4.dp))
                    Text(
                        TimeFormat.countdown(Duration.between(now, at)),
                        style = MaterialTheme.typography.headlineMedium,
                        color = MaterialTheme.colorScheme.onPrimaryContainer,
                    )
                    val dayPrefix = if (at.toLocalDate() != now.toLocalDate()) TimeFormat.shortDate(at.toLocalDate()) + " · " else ""
                    Text(dayPrefix + TimeFormat.time(at.toLocalTime(), use24h), style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

@Composable
private fun BannerCard(icon: androidx.compose.ui.graphics.vector.ImageVector, title: String, text: String, color: Color, onDismiss: (() -> Unit)?) {
    Spacer(Modifier.height(12.dp))
    AppCard(containerColor = color.copy(alpha = 0.10f)) {
        Row(verticalAlignment = Alignment.Top) {
            Icon(icon, null, tint = color)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.titleSmall, color = color)
                Text(text, style = MaterialTheme.typography.bodyMedium)
            }
            if (onDismiss != null) {
                IconButton(onClick = onDismiss, modifier = Modifier.size(32.dp)) {
                    Icon(Icons.Rounded.Close, stringResource(R.string.dismiss))
                }
            }
        }
    }
}

@Composable
private fun MissedCard(missed: List<DoseItem>, use24h: Boolean, onTakeLate: (DoseItem) -> Unit, onDismiss: () -> Unit) {
    Spacer(Modifier.height(12.dp))
    AppCard(containerColor = StatusColors.Missed.copy(alpha = 0.10f)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.WarningAmber, null, tint = StatusColors.Missed)
            Spacer(Modifier.width(10.dp))
            Text(
                androidx.compose.ui.res.pluralStringResource(R.plurals.missed_summary, missed.size, missed.size),
                style = MaterialTheme.typography.titleSmall,
                modifier = Modifier.weight(1f),
            )
            TextButton(onClick = onDismiss) { Text(stringResource(R.string.dismiss)) }
        }
        missed.take(5).forEach { item ->
            Row(Modifier.fillMaxWidth().padding(top = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "${item.med.medicine.name} · ${TimeFormat.shortDate(item.scheduledAt.toLocalDate())} ${TimeFormat.time(item.scheduledAt.toLocalTime(), use24h)}",
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.weight(1f),
                )
                TextButton(onClick = { onTakeLate(item) }) { Text(stringResource(R.string.action_took_it)) }
            }
        }
    }
}

@Composable
private fun DoseCard(
    item: DoseItem,
    photoDir: File,
    use24h: Boolean,
    snoozeOptions: List<Int>,
    onTake: () -> Unit,
    onSkip: () -> Unit,
    onSnooze: (Int) -> Unit,
    onUndo: () -> Unit,
    onOpen: () -> Unit,
) {
    val m = item.med.medicine
    val context = LocalContext.current
    var menu by remember { mutableStateOf(false) }
    val done = item.status == DoseStatus.TAKEN || item.status == DoseStatus.LATE
    val statusColor = statusColor(item.status)
    val checkBg by animateColorAsState(if (done) StatusColors.Taken else MaterialTheme.colorScheme.surfaceVariant, label = "check")
    val checkScale by animateFloatAsState(if (done) 1.1f else 1f, spring(Spring.DampingRatioMediumBouncy), label = "scale")

    Box {
        Row(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(22.dp))
                .background(MaterialTheme.colorScheme.surface)
                .combinedClickable(
                    onClick = { if (item.log == null) onTake() else menu = true },
                    onLongClick = { menu = true },
                )
                .animateContentSize(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(Modifier.width(6.dp).height(86.dp).background(medicineColor(m.colorIndex)))
            Spacer(Modifier.width(12.dp))
            MedicineAvatar(m, photoDir, 46.dp)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f).padding(vertical = 12.dp)) {
                Text(m.name, style = MaterialTheme.typography.titleMedium, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text(context.doseLine(m), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1, overflow = TextOverflow.Ellipsis)
                Spacer(Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(TimeFormat.time(item.dueAt.toLocalTime(), use24h), style = MaterialTheme.typography.labelLarge)
                    if (item.dueAt != item.scheduledAt) Icon(Icons.Rounded.Link, null, Modifier.size(14.dp), tint = MaterialTheme.colorScheme.primary)
                    when {
                        item.snoozedUntil != null && item.log == null ->
                            Pill(stringResource(R.string.snoozed_until, TimeFormat.time(item.snoozedUntil.toLocalTime(), use24h)), MaterialTheme.colorScheme.primary)
                        item.status != DoseStatus.UPCOMING -> Pill(statusText(item, use24h), statusColor)
                    }
                }
            }
            Box(
                Modifier
                    .padding(end = 14.dp)
                    .size(48.dp)
                    .scale(checkScale)
                    .clip(CircleShape)
                    .background(checkBg),
                contentAlignment = Alignment.Center,
            ) {
                when (item.status) {
                    DoseStatus.SKIPPED -> Icon(Icons.Rounded.Close, null, tint = StatusColors.Skipped)
                    DoseStatus.MISSED -> Icon(Icons.Rounded.WarningAmber, null, tint = StatusColors.Missed)
                    DoseStatus.DUE -> Icon(Icons.Rounded.NotificationsActive, null, tint = MaterialTheme.colorScheme.primary)
                    else -> Icon(Icons.Rounded.Check, null, tint = if (done) Color.White else MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
        DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
            if (item.log == null || item.status != DoseStatus.TAKEN) {
                DropdownMenuItem(text = { Text(stringResource(R.string.action_taken)) }, leadingIcon = { Icon(Icons.Rounded.Check, null) },
                    onClick = { menu = false; onTake() })
            }
            if (item.log == null) {
                snoozeOptions.forEach { minutes ->
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.action_snooze_min, minutes)) },
                        leadingIcon = { Icon(Icons.Rounded.Snooze, null) },
                        onClick = { menu = false; onSnooze(minutes) },
                    )
                }
                DropdownMenuItem(text = { Text(stringResource(R.string.action_skip)) }, leadingIcon = { Icon(Icons.Rounded.Close, null) },
                    onClick = { menu = false; onSkip() })
            } else {
                DropdownMenuItem(text = { Text(stringResource(R.string.action_undo)) }, onClick = { menu = false; onUndo() })
            }
            HorizontalDivider()
            DropdownMenuItem(text = { Text(stringResource(R.string.open_medicine)) }, onClick = { menu = false; onOpen() })
        }
    }
}

@Composable
fun statusColor(status: DoseStatus): Color = when (status) {
    DoseStatus.TAKEN -> StatusColors.Taken
    DoseStatus.LATE -> StatusColors.Late
    DoseStatus.SKIPPED -> StatusColors.Skipped
    DoseStatus.MISSED -> StatusColors.Missed
    DoseStatus.DUE -> MaterialTheme.colorScheme.primary
    DoseStatus.UPCOMING -> StatusColors.Pending
}

@Composable
private fun statusText(item: DoseItem, use24h: Boolean): String = when (item.status) {
    DoseStatus.TAKEN -> stringResource(R.string.status_taken_at, TimeFormat.time(item.log!!.actionAt.toLocalTime(), use24h))
    DoseStatus.LATE -> stringResource(R.string.status_late_at, TimeFormat.time(item.log!!.actionAt.toLocalTime(), use24h))
    DoseStatus.SKIPPED -> stringResource(R.string.status_skipped)
    DoseStatus.MISSED -> stringResource(R.string.status_missed)
    DoseStatus.DUE -> stringResource(R.string.status_due)
    DoseStatus.UPCOMING -> stringResource(R.string.status_upcoming)
}
