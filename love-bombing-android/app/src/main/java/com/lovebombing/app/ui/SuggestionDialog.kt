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
    val recent = remember { Suggest.recentIds(vm.sent.value) }
    val message = remember(offset) {
        Suggest.pick(vm.content, request.category, request.festivalKey, recent, LocalDate.now(), offset)
    }
    if (message == null) {
        LaunchedEffect(Unit) { onDismiss() }
        return
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Ready to send", style = MaterialTheme.typography.titleLarge) },
        text = {
            Column {
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
