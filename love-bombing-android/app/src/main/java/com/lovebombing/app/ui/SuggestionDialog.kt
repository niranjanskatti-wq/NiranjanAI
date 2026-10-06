package com.lovebombing.app.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.lovebombing.app.data.Suggest
import java.time.LocalDate

/** Shown when a reminder notification is tapped: a message ready to send. */
@Composable
fun SuggestionDialog(vm: AppViewModel, request: SuggestionRequest, onDismiss: () -> Unit) {
    val sender = LocalSender.current
    var offset by remember { mutableIntStateOf(0) }
    var long by remember { mutableStateOf(request.category == com.lovebombing.app.data.Content.LONG_CATEGORY || vm.preferLong.value) }
    val recent = remember { Suggest.recentIds(vm.sent.value) }
    val message = remember(offset, long) {
        if (long) Suggest.pickLong(vm.content, request.category, recent, LocalDate.now(), offset)
        else Suggest.pick(vm.content, request.category, request.festivalKey, recent, LocalDate.now(), offset)
    }
    if (message == null) {
        LaunchedEffect(Unit) { onDismiss() }
        return
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Ready to send", style = MaterialTheme.typography.titleLarge) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                ChipRow(listOf(false, true), long, { if (it) "Long" else "Short" }, { long = it; offset = 0 },
                    modifier = Modifier.padding(bottom = 8.dp))
                Pill(message.category, MaterialTheme.colorScheme.primaryContainer, Plum)
                Spacer(Modifier.height(12.dp))
                Text(sender.textOf(message), style = MaterialTheme.typography.bodyLarge)
            }
        },
        confirmButton = {
            Row {
                TextButton(onClick = { offset++ }) { Text("Next") }
                TextButton(onClick = { sender.copy(message); onDismiss() }) { Text("Copy") }
                TextButton(onClick = { sender.whatsApp(message); onDismiss() }) { Text("WhatsApp") }
            }
        },
    )
}
