package com.dosemate.app.ui.report

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Share
import androidx.compose.material3.Button
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.core.content.FileProvider
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.dosemate.app.R
import com.dosemate.app.data.db.ActiveAlertDao
import com.dosemate.app.data.db.JournalEntryEntity
import com.dosemate.app.data.repo.DoseQueries
import com.dosemate.app.data.repo.JournalRepository
import com.dosemate.app.data.repo.LogRepository
import com.dosemate.app.data.repo.MedicineRepository
import com.dosemate.app.data.repo.PhotoStore
import com.dosemate.app.data.repo.SettingsRepository
import com.dosemate.app.report.PdfReportGenerator
import com.dosemate.app.report.ReportData
import com.dosemate.app.ui.components.AppCard
import com.dosemate.app.ui.components.ChoiceChips
import com.dosemate.app.ui.components.PhotoBox
import com.dosemate.app.ui.components.SectionHeader
import com.dosemate.app.ui.components.SwitchRow
import com.dosemate.app.util.LocaleHelper
import com.dosemate.app.util.TimeFormat
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.time.LocalDate
import java.time.LocalDateTime
import javax.inject.Inject

@HiltViewModel
class ReportViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val medicines: MedicineRepository,
    private val logs: LogRepository,
    private val alerts: ActiveAlertDao,
    private val journal: JournalRepository,
    private val settingsRepo: SettingsRepository,
    private val photos: PhotoStore,
    private val prescriptionRepo: com.dosemate.app.data.repo.PrescriptionRepository,
) : ViewModel() {
    var rangeDays by mutableStateOf(30)
    var includeMedicines by mutableStateOf(true)
    var includeAdherence by mutableStateOf(true)
    var includeItch by mutableStateOf(true)
    var selectedPhotos by mutableStateOf(setOf<Long>())
    var busy by mutableStateOf(false)
        private set

    val entries: StateFlow<List<JournalEntryEntity>> = journal.entries.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())
    val photoDir: File = photos.dir(PhotoStore.JOURNAL)

    fun toggle(id: Long) {
        selectedPhotos = if (id in selectedPhotos) selectedPhotos - id else selectedPhotos + id
    }

    fun generate(onReady: (File) -> Unit) = viewModelScope.launch {
        busy = true
        val file = withContext(Dispatchers.IO) {
            val settings = settingsRepo.current()
            val now = LocalDateTime.now()
            val meds = medicines.all()
            val to = now.toLocalDate()
            val earliest = meds.minOfOrNull { it.medicine.startDate } ?: to
            val from = if (rangeDays <= 0) earliest else maxOf(to.minusDays(rangeDays - 1L), minOf(earliest, to))
            val logList = logs.between(from.minusDays(1), to.plusDays(1))
            val active = alerts.all()
            val byDay = mutableMapOf<LocalDate, List<com.dosemate.app.data.repo.DoseItem>>()
            var d = from
            while (!d.isAfter(to)) {
                byDay[d] = DoseQueries.dosesOn(d, meds, logList, active, now, settings)
                d = d.plusDays(1)
            }
            val allEntries = journal.all()
            val localized = LocaleHelper.wrap(context, settings.language)
            val dir = File(context.cacheDir, "reports").apply { mkdirs() }
            dir.listFiles()?.forEach { it.delete() }
            val out = File(dir, "DoseMate-report-${TimeFormat.dayMonthYear(to)}.pdf")
            PdfReportGenerator(localized, photos).generate(
                ReportData(
                    from = from, to = to, settings = settings,
                    prescriptions = prescriptionRepo.all(),
                    medicines = meds.filter { m -> !m.medicine.archived || byDay.values.any { list -> list.any { it.med.medicine.id == m.medicine.id } } },
                    dosesByDay = byDay,
                    journal = allEntries,
                    photos = allEntries.filter { it.id in selectedPhotos && it.photoPath != null },
                    includeMedicines = includeMedicines,
                    includeAdherence = includeAdherence,
                    includeItch = includeItch,
                ),
                out,
            )
        }
        busy = false
        onReady(file)
    }
}

private fun share(context: Context, file: File) {
    val uri = FileProvider.getUriForFile(context, "${context.packageName}.files", file)
    val send = Intent(Intent.ACTION_SEND)
        .setType("application/pdf")
        .putExtra(Intent.EXTRA_STREAM, uri)
        .putExtra(Intent.EXTRA_SUBJECT, context.getString(R.string.report_title))
        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    context.startActivity(Intent.createChooser(send, context.getString(R.string.share_report)))
}

@Composable
fun ReportScreen(onBack: () -> Unit, viewModel: ReportViewModel = hiltViewModel()) {
    val context = LocalContext.current
    val entries by viewModel.entries.collectAsStateWithLifecycle()
    var last by androidx.compose.runtime.remember { mutableStateOf<File?>(null) }
    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text(stringResource(R.string.doctor_report)) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, stringResource(R.string.back)) } },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = MaterialTheme.colorScheme.background),
            )
        },
    ) { padding ->
        LazyColumn(contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = padding.calculateTopPadding(), bottom = 40.dp)) {
            item {
                Text(stringResource(R.string.report_intro), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                SectionHeader(stringResource(R.string.report_range))
                ChoiceChips(listOf(14, 30, 90, 0), viewModel.rangeDays, {
                    if (it == 0) stringResource(R.string.whole_course) else stringResource(R.string.last_n_days, it)
                }, { viewModel.rangeDays = it })
                SectionHeader(stringResource(R.string.report_include))
                AppCard {
                    SwitchRow(stringResource(R.string.report_medicines), viewModel.includeMedicines, { viewModel.includeMedicines = it })
                    SwitchRow(stringResource(R.string.report_adherence), viewModel.includeAdherence, { viewModel.includeAdherence = it })
                    SwitchRow(stringResource(R.string.report_itch), viewModel.includeItch, { viewModel.includeItch = it })
                }
                val withPhotos = entries.filter { it.photoPath != null }
                if (withPhotos.isNotEmpty()) SectionHeader(stringResource(R.string.report_select_photos))
            }
            items(entries.filter { it.photoPath != null }, key = { it.id }) { e ->
                Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                    Checkbox(checked = e.id in viewModel.selectedPhotos, onCheckedChange = { viewModel.toggle(e.id) })
                    PhotoBox(File(viewModel.photoDir, e.photoPath!!), Modifier.size(56.dp))
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text(TimeFormat.date(e.date), style = MaterialTheme.typography.bodyLarge)
                        Text(stringResource(R.string.itch_score_n, e.itchScore), style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
            item {
                Spacer(Modifier.height(20.dp))
                Button(
                    onClick = { viewModel.generate { file -> last = file; share(context, file) } },
                    enabled = !viewModel.busy,
                    modifier = Modifier.fillMaxWidth().height(56.dp),
                ) {
                    if (viewModel.busy) {
                        CircularProgressIndicator(Modifier.size(22.dp), strokeWidth = 2.dp)
                    } else {
                        Icon(Icons.Rounded.Share, null)
                        Spacer(Modifier.width(8.dp))
                        Text(stringResource(R.string.generate_share))
                    }
                }
                last?.let { file ->
                    Row(Modifier.fillMaxWidth().padding(top = 8.dp), horizontalArrangement = Arrangement.Center) {
                        androidx.compose.material3.TextButton(onClick = { share(context, file) }) { Text(stringResource(R.string.share_again)) }
                    }
                }
            }
        }
    }
}
