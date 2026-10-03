package com.dosemate.app.ui.journal

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.dosemate.app.R
import com.dosemate.app.data.db.JournalEntryEntity
import com.dosemate.app.ui.components.AppCard
import com.dosemate.app.ui.components.PhotoBox
import com.dosemate.app.ui.components.Pill
import com.dosemate.app.util.TimeFormat
import java.io.File
import java.time.temporal.ChronoUnit

/** Side-by-side comparison of any two journal dates. */
@Composable
fun CompareScreen(onBack: () -> Unit, viewModel: JournalViewModel = hiltViewModel()) {
    val entries by viewModel.entries.collectAsStateWithLifecycle()
    val withPhotos = entries.filter { it.photoPath != null }.sortedBy { it.date }
    var leftId by remember { mutableStateOf<Long?>(null) }
    var rightId by remember { mutableStateOf<Long?>(null) }
    val left = withPhotos.firstOrNull { it.id == leftId } ?: withPhotos.firstOrNull()
    val right = withPhotos.firstOrNull { it.id == rightId } ?: withPhotos.lastOrNull()

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text(stringResource(R.string.compare)) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, stringResource(R.string.back)) } },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = MaterialTheme.colorScheme.background),
            )
        },
    ) { padding ->
        Column(Modifier.padding(padding).padding(16.dp).verticalScroll(rememberScrollState())) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                ComparePane(left, withPhotos, viewModel.photoDir, Modifier.weight(1f)) { leftId = it }
                ComparePane(right, withPhotos, viewModel.photoDir, Modifier.weight(1f)) { rightId = it }
            }
            if (left != null && right != null) {
                Spacer(Modifier.height(16.dp))
                AppCard {
                    val days = ChronoUnit.DAYS.between(left.date, right.date)
                    val diff = right.itchScore - left.itchScore
                    Text(stringResource(R.string.compare_days_apart, kotlin.math.abs(days)), style = MaterialTheme.typography.titleMedium)
                    Text(
                        when {
                            diff < 0 -> stringResource(R.string.compare_itch_better, -diff)
                            diff > 0 -> stringResource(R.string.compare_itch_worse, diff)
                            else -> stringResource(R.string.compare_itch_same)
                        },
                        style = MaterialTheme.typography.bodyLarge,
                    )
                }
            }
        }
    }
}

@Composable
private fun ComparePane(
    entry: JournalEntryEntity?,
    all: List<JournalEntryEntity>,
    dir: File,
    modifier: Modifier,
    onSelect: (Long) -> Unit,
) {
    var open by remember { mutableStateOf(false) }
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        PhotoBox(entry?.photoPath?.let { File(dir, it) }, Modifier.fillMaxWidth().aspectRatio(0.75f))
        Spacer(Modifier.height(8.dp))
        Box {
            OutlinedButton(onClick = { open = true }, modifier = Modifier.fillMaxWidth()) {
                Text(entry?.let { TimeFormat.shortDate(it.date) } ?: "—", textAlign = TextAlign.Center)
            }
            DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
                all.forEach { e ->
                    DropdownMenuItem(text = { Text(TimeFormat.date(e.date)) }, onClick = { open = false; onSelect(e.id) })
                }
            }
        }
        entry?.let {
            Spacer(Modifier.height(6.dp))
            Pill(stringResource(R.string.itch_score_n, it.itchScore), itchColor(it.itchScore))
        }
    }
}
