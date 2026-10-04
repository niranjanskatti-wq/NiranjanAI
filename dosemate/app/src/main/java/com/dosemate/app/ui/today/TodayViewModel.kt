package com.dosemate.app.ui.today

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dosemate.app.alarm.ReminderEngine
import com.dosemate.app.data.db.ActiveAlertDao
import com.dosemate.app.data.db.MedicineEntity
import com.dosemate.app.data.repo.AppSettings
import com.dosemate.app.data.repo.DoseItem
import com.dosemate.app.data.repo.DoseQueries
import com.dosemate.app.data.repo.LogRepository
import com.dosemate.app.data.repo.MedicineRepository
import com.dosemate.app.data.repo.PhotoStore
import com.dosemate.app.data.repo.SettingsRepository
import com.dosemate.core.DoseStatus
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.io.File
import java.time.LocalDate
import java.time.LocalDateTime
import javax.inject.Inject

data class TodayState(
    val date: LocalDate = LocalDate.now(),
    val items: List<DoseItem> = emptyList(),
    val next: DoseItem? = null,
    val banners: List<MedicineEntity> = emptyList(),
    /** Doctor name to diet/advice notes, one per prescription that has notes. */
    val dietNotes: List<Pair<String, String>> = emptyList(),
    val recentlyMissed: List<DoseItem> = emptyList(),
    val hasMedicines: Boolean = true,
    val loaded: Boolean = false,
)

@HiltViewModel
class TodayViewModel @Inject constructor(
    @ApplicationContext context: Context,
    private val medicines: MedicineRepository,
    logs: LogRepository,
    alerts: ActiveAlertDao,
    private val settingsRepo: SettingsRepository,
    private val engine: ReminderEngine,
    photos: PhotoStore,
    prescriptionRepo: com.dosemate.app.data.repo.PrescriptionRepository,
) : ViewModel() {
    private val rxFlow = prescriptionRepo.prescriptions

    val photoDir: File = photos.dir(PhotoStore.MEDICINE)
    private val uiPrefs = context.getSharedPreferences("ui", Context.MODE_PRIVATE)
    private val missedSeen = MutableStateFlow(uiPrefs.getLong("missedSeen", 0L))

    /** Re-evaluates statuses (due → missed, countdown target) every 30 seconds. */
    private val ticker = flow {
        while (true) {
            emit(LocalDateTime.now())
            delay(30_000)
        }
    }

    private val today = LocalDate.now()

    val state: StateFlow<TodayState> = combine(
        medicines.medicines,
        logs.observeBetween(today.minusDays(2), today.plusDays(8)),
        alerts.observeAll(),
        combine(settingsRepo.settings, rxFlow) { s, rx -> s to rx },
        combine(ticker, missedSeen) { now, seen -> now to seen },
    ) { meds, logList, active, (settings, prescriptions), (now, seen) ->
        val date = now.toLocalDate()
        val items = DoseQueries.dosesOn(date, meds, logList, active, now, settings)
        val yesterday = DoseQueries.dosesOn(date.minusDays(1), meds, logList, active, now, settings)
        val seenAt = com.dosemate.app.alarm.AlarmContract.decode(seen)
        val missed = (yesterday + items).filter {
            it.status == DoseStatus.MISSED && it.log != null && it.log.actionAt.isAfter(seenAt)
        }
        TodayState(
            date = date,
            items = items,
            next = DoseQueries.nextDose(meds, logList, active, now, settings),
            banners = meds.map { it.medicine }.filter { it.banner.isNotBlank() && !it.bannerDismissed && !it.archived },
            dietNotes = prescriptions.filter { it.notes.isNotBlank() }.map { it.doctorName to it.notes },
            recentlyMissed = missed,
            hasMedicines = meds.any { !it.medicine.archived },
            loaded = true,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), TodayState())

    val settings: StateFlow<AppSettings> =
        settingsRepo.settings.stateIn(viewModelScope, SharingStarted.Eagerly, settingsRepo.current())

    fun markTaken(item: DoseItem) = viewModelScope.launch { engine.markTaken(item.key) }
    fun skip(item: DoseItem, reason: String?) = viewModelScope.launch { engine.markSkipped(item.key, reason) }
    fun snooze(item: DoseItem, minutes: Int) = viewModelScope.launch { engine.snooze(item.key, minutes) }
    fun undo(item: DoseItem) = viewModelScope.launch { engine.clear(item.key) }

    fun takenLate(item: DoseItem) = viewModelScope.launch { engine.markTaken(item.key) }

    fun dismissBanner(id: Long) = viewModelScope.launch { medicines.dismissBanner(id) }

    fun dismissMissed() {
        val now = com.dosemate.app.alarm.AlarmContract.encode(LocalDateTime.now())
        uiPrefs.edit().putLong("missedSeen", now).apply()
        missedSeen.value = now
    }
}
