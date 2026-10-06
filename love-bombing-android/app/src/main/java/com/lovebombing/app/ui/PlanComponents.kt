package com.lovebombing.app.ui

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.lovebombing.app.data.PlanItem
import com.lovebombing.app.data.PlanStatus
import com.lovebombing.app.data.PlanType
import com.lovebombing.app.data.Settings
import com.lovebombing.app.data.Suggest
import com.lovebombing.app.data.formatMinutes
import com.lovebombing.app.data.planItems
import java.time.LocalDate

/** Plan items (manual + automatic) for [start]..[end], recomputed when anything they depend on changes. */
@Composable
fun rememberPlanItems(vm: AppViewModel, settings: Settings, start: LocalDate, end: LocalDate): List<PlanItem> {
    val plans by vm.plans.collectAsState()
    val autos by vm.autoPlans.collectAsState()
    val statuses by vm.statuses.collectAsState()
    return remember(settings, plans, autos, statuses, start, end) {
        planItems(start, end, settings, plans, autos, statuses, vm.content.festivals)
    }
}

fun statusColors(status: PlanStatus): Pair<Color, Color> = when (status) {
    PlanStatus.DONE -> Color(0xFFDDF3E5) to SentGreen
    PlanStatus.SKIPPED -> Color(0xFFEDE7EB) to Muted
    PlanStatus.NOT_DONE -> RoseSoft to Color(0xFFB3263E)
    PlanStatus.PENDING -> MarigoldSoft to Color(0xFF8A5A00)
}

/** "Change": pick a new date, then a new time, for just this occurrence. */
fun changeItem(context: Context, vm: AppViewModel, item: PlanItem) {
    pickDate(context, item.date) { date ->
        pickTime(context, item.minuteOfDay) { minutes -> vm.moveItem(item, date, minutes) }
    }
}

/**
 * One plan with its status and actions: Done / Not done / Skip / Change.
 * "Send" appears for message plans and marks the plan done after sharing.
 */
@Composable
fun PlanItemRow(vm: AppViewModel, item: PlanItem, showDate: Boolean = false, onDelete: (() -> Unit)? = null) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val sender = LocalSender.current
    val status = item.effectiveStatus()
    val (chipBg, chipFg) = statusColors(status)
    val finished = status == PlanStatus.DONE || status == PlanStatus.SKIPPED

    Column(Modifier.fillMaxWidth().padding(vertical = 8.dp)) {
        Row(verticalAlignment = Alignment.Top) {
            Box(Modifier.padding(top = 6.dp).width(4.dp).height(40.dp).clip(CircleShape).background(if (item.isAuto) Plum else Rose))
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    item.title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold,
                    textDecoration = if (finished) TextDecoration.LineThrough else null,
                    color = if (finished) Muted else MaterialTheme.colorScheme.onSurface,
                )
                val whenText = (if (showDate) item.date.format(shortDayFormat) + " · " else "") + formatMinutes(item.minuteOfDay)
                Text(
                    "$whenText · ${item.type.label}${if (item.isAuto) " · Auto" else ""}",
                    style = MaterialTheme.typography.bodySmall, color = Muted,
                )
                if (item.note.isNotBlank() && !finished) {
                    Text(item.note, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.padding(top = 2.dp))
                }
                item.messageText?.let {
                    Text("“$it”", style = MaterialTheme.typography.bodySmall, color = Plum, modifier = Modifier.padding(top = 2.dp))
                }
            }
            Spacer(Modifier.width(8.dp))
            Pill(status.label, chipBg, chipFg)
        }
        Spacer(Modifier.height(8.dp))
        Row(
            Modifier.horizontalScroll(rememberScrollState()).padding(start = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            val pad = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
            if (item.type == PlanType.MESSAGE && !finished) {
                Button(
                    onClick = {
                        val msg = vm.content.message(item.messageId) ?: run {
                            val recent = Suggest.recentIds(vm.sent.value)
                            if (item.messageCategory == com.lovebombing.app.data.Content.LONG_CATEGORY) {
                                Suggest.pickLong(vm.content, null, recent, item.date, 0)
                            } else {
                                Suggest.pick(vm.content, item.messageCategory ?: "Romantic", null, recent, item.date, 0)
                            }
                        }
                        if (msg != null) {
                            sender.whatsApp(msg)
                            vm.setStatus(item, PlanStatus.DONE)
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Rose), contentPadding = pad,
                ) { Text("Send") }
            }
            StatusButton("Done ✓", status == PlanStatus.DONE, SentGreen, pad) { vm.setStatus(item, PlanStatus.DONE) }
            StatusButton("Not done", status == PlanStatus.NOT_DONE, Color(0xFFB3263E), pad) { vm.setStatus(item, PlanStatus.NOT_DONE) }
            StatusButton("Skip", status == PlanStatus.SKIPPED, Muted, pad) { vm.setStatus(item, PlanStatus.SKIPPED) }
            OutlinedButton(onClick = { changeItem(context, vm, item) }, contentPadding = pad) { Text("Change") }
            if (onDelete != null) OutlinedButton(onClick = onDelete, contentPadding = pad) { Text("Delete") }
        }
    }
}

@Composable
private fun StatusButton(label: String, selected: Boolean, color: Color, pad: PaddingValues, onClick: () -> Unit) {
    if (selected) {
        Button(onClick = onClick, colors = ButtonDefaults.buttonColors(containerColor = color), contentPadding = pad,
            shape = RoundedCornerShape(50)) { Text(label) }
    } else {
        OutlinedButton(onClick = onClick, contentPadding = pad, shape = RoundedCornerShape(50)) { Text(label, color = color) }
    }
}
