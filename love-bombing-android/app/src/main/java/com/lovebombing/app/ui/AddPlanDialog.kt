package com.lovebombing.app.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.lovebombing.app.data.Message
import com.lovebombing.app.data.Plan
import com.lovebombing.app.data.PlanType
import com.lovebombing.app.data.formatMinutes
import com.lovebombing.app.data.personalize
import java.time.LocalDate

/** Initial values for the "Add plan" form (Gifts pre-fills it via "Plan it"). */
data class PlanDraft(
    val type: PlanType = PlanType.DATE_NIGHT,
    val title: String = "",
    val date: LocalDate = LocalDate.now().plusDays(1),
    val minuteOfDay: Int = 19 * 60,
    val note: String = "",
)

private fun defaultTitle(type: PlanType) = when (type) {
    PlanType.MESSAGE -> "Send her a message"
    PlanType.DATE_NIGHT -> "Date night"
    PlanType.SURPRISE -> "Surprise for her"
    PlanType.GIFT -> "Give her a gift"
    PlanType.TRIP -> "Trip together"
    PlanType.CUSTOM -> ""
}

@Composable
fun AddPlanDialog(vm: AppViewModel, draft: PlanDraft, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val sender = LocalSender.current
    var type by remember { mutableStateOf(draft.type) }
    var title by remember { mutableStateOf(draft.title) }
    var date by remember { mutableStateOf(draft.date) }
    var minutes by remember { mutableStateOf(draft.minuteOfDay) }
    var note by remember { mutableStateOf(draft.note) }
    var attached by remember { mutableStateOf<Message?>(null) }
    var picking by remember { mutableStateOf(false) }

    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Surface(
            Modifier.fillMaxWidth().padding(16.dp).imePadding(),
            shape = RoundedCornerShape(28.dp),
            color = MaterialTheme.colorScheme.background,
        ) {
            Column(Modifier.verticalScroll(rememberScrollState()).padding(vertical = 20.dp)) {
                Row(Modifier.padding(horizontal = 20.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text("Add plan", style = MaterialTheme.typography.headlineSmall, color = Plum, modifier = Modifier.weight(1f))
                    IconButton(onClick = onDismiss) { Icon(Icons.Filled.Close, contentDescription = "Close") }
                }
                Spacer(Modifier.height(12.dp))
                Text("Type", style = MaterialTheme.typography.labelLarge, color = Muted, modifier = Modifier.padding(horizontal = 20.dp))
                Spacer(Modifier.height(6.dp))
                ChipRow(PlanType.entries, type, { it.label }, {
                    if (title.isBlank() || title == defaultTitle(type)) title = defaultTitle(it)
                    type = it
                })
                Column(Modifier.padding(horizontal = 20.dp)) {
                    Spacer(Modifier.height(12.dp))
                    OutlinedTextField(
                        value = title, onValueChange = { title = it },
                        label = { Text("What's the plan?") }, singleLine = true, modifier = Modifier.fillMaxWidth(),
                    )
                    Spacer(Modifier.height(12.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        OutlinedButton(onClick = { pickDate(context, date) { date = it } }, modifier = Modifier.weight(1f)) {
                            Text(date.format(dayFormat))
                        }
                        OutlinedButton(onClick = { pickTime(context, minutes) { minutes = it } }) {
                            Text(formatMinutes(minutes))
                        }
                    }
                    Spacer(Modifier.height(12.dp))
                    OutlinedTextField(
                        value = note, onValueChange = { note = it },
                        label = { Text("Note (optional)") }, modifier = Modifier.fillMaxWidth(), minLines = 2,
                    )
                    Spacer(Modifier.height(12.dp))
                    if (attached == null) {
                        TextButton(onClick = { picking = true }) { Text("+ Attach a message from the library") }
                    } else {
                        SectionCard(container = MaterialTheme.colorScheme.primaryContainer) {
                            Eyebrow("Attached message", color = Plum)
                            Spacer(Modifier.height(6.dp))
                            Text(sender.textOf(attached!!), style = MaterialTheme.typography.bodyMedium)
                            Row {
                                TextButton(onClick = { picking = true }) { Text("Change") }
                                TextButton(onClick = { attached = null }) { Text("Remove") }
                            }
                        }
                    }
                    Spacer(Modifier.height(8.dp))
                    Text(
                        "You'll get a reminder 15 minutes before" +
                            if (type == PlanType.DATE_NIGHT || type == PlanType.GIFT) ", and one the day before." else ".",
                        style = MaterialTheme.typography.bodySmall, color = Muted,
                    )
                    Spacer(Modifier.height(16.dp))
                    Button(
                        onClick = {
                            val msg = attached
                            vm.savePlan(
                                Plan(
                                    type = type.name,
                                    title = title.trim().ifEmpty { type.label },
                                    dateEpochDay = date.toEpochDay(),
                                    minuteOfDay = minutes,
                                    note = note.trim(),
                                    messageId = msg?.id,
                                    messageText = msg?.let { sender.textOf(it) },
                                ),
                            )
                            sender.toast("Plan saved for ${date.format(shortDayFormat)}")
                            onDismiss()
                        },
                        modifier = Modifier.fillMaxWidth().height(52.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Plum),
                    ) { Text("Save plan") }
                }
            }
        }
    }

    if (picking) {
        MessagePickerDialog(vm, onPick = { attached = it; picking = false }, onDismiss = { picking = false })
    }
}

@Composable
fun MessagePickerDialog(vm: AppViewModel, onPick: (Message) -> Unit, onDismiss: () -> Unit) {
    val content = vm.content
    val name = (vm.settings.value as? SettingsState.Ready)?.settings?.wifeName.orEmpty()
    var query by remember { mutableStateOf("") }
    var category by remember { mutableStateOf("All") }
    val chips = remember { listOf("All") + content.categories }
    val shown = remember(query, category) {
        content.messages.filter {
            (category == "All" || it.category == category) && (query.isBlank() || it.text.contains(query.trim(), ignoreCase = true))
        }
    }
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Surface(Modifier.fillMaxSize().padding(12.dp).imePadding(), shape = RoundedCornerShape(28.dp), color = MaterialTheme.colorScheme.background) {
            Column(Modifier.padding(top = 16.dp)) {
                Row(Modifier.padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text("Pick a message", style = MaterialTheme.typography.titleLarge, color = Plum, modifier = Modifier.weight(1f))
                    IconButton(onClick = onDismiss) { Icon(Icons.Filled.Close, contentDescription = "Close") }
                }
                OutlinedTextField(
                    value = query, onValueChange = { query = it }, singleLine = true,
                    leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
                    placeholder = { Text("Search") },
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                    shape = RoundedCornerShape(50),
                )
                ChipRow(chips, category, { it }, { category = it })
                LazyColumn(contentPadding = PaddingValues(16.dp)) {
                    items(shown, key = { it.id }) { m ->
                        Column(Modifier.fillMaxWidth().clickable { onPick(m) }.padding(vertical = 12.dp)) {
                            Text(m.category, style = MaterialTheme.typography.labelSmall, color = Rose)
                            Spacer(Modifier.width(4.dp))
                            Text(personalize(m.text, name), style = MaterialTheme.typography.bodyMedium)
                        }
                        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
                    }
                }
            }
        }
    }
}
