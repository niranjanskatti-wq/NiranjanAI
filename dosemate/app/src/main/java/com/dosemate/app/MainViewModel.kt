package com.dosemate.app

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dosemate.app.alarm.ReminderEngine
import com.dosemate.app.data.db.MedicineWithTimes
import com.dosemate.app.data.repo.AppSettings
import com.dosemate.app.data.repo.LogRepository
import com.dosemate.app.data.repo.MedicineRepository
import com.dosemate.app.data.repo.SettingsRepository
import com.dosemate.app.data.repo.engine
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.LocalDate
import javax.inject.Inject

@HiltViewModel
class MainViewModel @Inject constructor(
    private val settingsRepo: SettingsRepository,
    private val medicines: MedicineRepository,
    logs: LogRepository,
    private val engine: ReminderEngine,
) : ViewModel() {

    val settings: StateFlow<AppSettings> =
        settingsRepo.settings.stateIn(viewModelScope, SharingStarted.Eagerly, settingsRepo.current())

    private val _locked = MutableStateFlow(settingsRepo.current().appLock && settingsRepo.current().pinHash.isNotEmpty())
    val locked: StateFlow<Boolean> = _locked

    /** A finished course that has not been celebrated yet. */
    val celebration: StateFlow<MedicineWithTimes?> = combine(medicines.medicines, logs.observeAll()) { meds, allLogs ->
        val today = LocalDate.now()
        val logged = allLogs.map { Triple(it.medicineId, it.slotId, it.scheduledAt) }.toHashSet()
        meds.firstOrNull { med ->
            val m = med.medicine
            if (m.completedCelebrated || m.archived) return@firstOrNull false
            val engine = med.engine()
            val last = engine.lastDate ?: return@firstOrNull false
            val lastDose = engine.occurrencesOn(last).lastOrNull() ?: return@firstOrNull false
            today.isAfter(last) || Triple(m.id, lastDose.slotId, lastDose.dateTime) in logged
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    fun lockIfEnabled() {
        val s = settingsRepo.current()
        if (s.appLock && s.pinHash.isNotEmpty()) _locked.value = true
    }

    fun unlockWithPin(pin: String): Boolean {
        val ok = settingsRepo.checkPin(pin)
        if (ok) _locked.value = false
        return ok
    }

    fun unlockBiometric() {
        _locked.value = false
    }

    fun refresh() {
        viewModelScope.launch { engine.rescheduleAll() }
    }

    fun finishOnboarding() = settingsRepo.update { it.copy(onboardingDone = true) }

    fun finishCelebration(id: Long, archive: Boolean) {
        viewModelScope.launch {
            medicines.markCelebrated(id)
            if (archive) {
                medicines.setArchived(id, true)
                engine.rescheduleAll()
            }
        }
    }
}
