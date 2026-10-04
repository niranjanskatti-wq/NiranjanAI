package com.dosemate.app.ui.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.dosemate.app.R
import com.dosemate.app.data.db.PrescriptionEntity
import com.dosemate.app.ui.components.AppCard
import com.dosemate.app.ui.components.DatePickDialog
import com.dosemate.app.ui.components.TextInput
import com.dosemate.app.util.TimeFormat
import java.time.LocalDate

/** Card showing one prescription: doctor, date, notes and how many medicines belong to it. */
@Composable
fun PrescriptionCard(p: PrescriptionEntity, medicineCount: Int, onClick: (() -> Unit)? = null) {
    AppCard(onClick = onClick, containerColor = MaterialTheme.colorScheme.primaryContainer) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.Person, null, tint = MaterialTheme.colorScheme.primary)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(p.doctorName, style = MaterialTheme.typography.titleMedium)
                val sub = listOfNotNull(
                    p.date?.let { stringResource(R.string.prescribed_on, TimeFormat.dayMonthYear(it)) },
                    pluralStringResource(R.plurals.medicines_count, medicineCount, medicineCount),
                ).joinToString(" · ")
                Text(sub, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        if (p.notes.isNotBlank()) {
            Spacer(Modifier.height(8.dp))
            Text(p.notes, style = MaterialTheme.typography.bodyMedium)
        }
    }
}

/** Add or edit a prescription. [onDelete] is shown only for existing ones. */
@Composable
fun PrescriptionDialog(
    initial: PrescriptionEntity,
    onDismiss: () -> Unit,
    onSave: (PrescriptionEntity) -> Unit,
    onDelete: (() -> Unit)?,
) {
    var doctor by remember { mutableStateOf(initial.doctorName) }
    var date by remember { mutableStateOf(initial.date) }
    var notes by remember { mutableStateOf(initial.notes) }
    var pickDate by remember { mutableStateOf(false) }
    var confirmDelete by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(if (initial.id == 0L) R.string.add_prescription else R.string.edit_prescription)) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                TextInput(stringResource(R.string.doctor_name), doctor, { doctor = it }, isError = doctor.isBlank())
                Spacer(Modifier.height(8.dp))
                OutlinedButton(onClick = { pickDate = true }, modifier = Modifier.fillMaxWidth()) {
                    Text(date?.let { stringResource(R.string.prescribed_on, TimeFormat.dayMonthYear(it)) }
                        ?: stringResource(R.string.set_prescribed_date))
                }
                Spacer(Modifier.height(8.dp))
                TextInput(stringResource(R.string.prescription_notes), notes, { notes = it }, singleLine = false)
                if (onDelete != null) {
                    TextButton(onClick = { confirmDelete = true }, modifier = Modifier.padding(top = 8.dp)) {
                        Text(stringResource(R.string.delete_prescription), color = MaterialTheme.colorScheme.error)
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                enabled = doctor.isNotBlank(),
                onClick = { onSave(initial.copy(doctorName = doctor.trim(), date = date, notes = notes.trim())) },
            ) { Text(stringResource(R.string.save)) }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.cancel)) } },
    )
    if (pickDate) {
        DatePickDialog(date ?: LocalDate.now(), onDismiss = { pickDate = false }) { date = it }
    }
    if (confirmDelete && onDelete != null) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text(stringResource(R.string.delete_prescription)) },
            text = { Text(stringResource(R.string.delete_prescription_confirm)) },
            confirmButton = {
                TextButton(onClick = { confirmDelete = false; onDelete() }) {
                    Text(stringResource(R.string.delete), color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text(stringResource(R.string.cancel)) } },
        )
    }
}
