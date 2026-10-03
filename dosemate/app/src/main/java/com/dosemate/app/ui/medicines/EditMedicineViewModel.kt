package com.dosemate.app.ui.medicines

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dosemate.app.alarm.OneShotPlayer
import com.dosemate.app.alarm.ReminderEngine
import com.dosemate.app.alarm.ToneLibrary
import com.dosemate.app.alarm.VoiceRecorder
import com.dosemate.app.data.db.DoseTimeEntity
import com.dosemate.app.data.db.MedIcon
import com.dosemate.app.data.db.MedicineEntity
import com.dosemate.app.data.db.MedicineType
import com.dosemate.app.data.db.MedicineWithTimes
import com.dosemate.app.data.db.ToneType
import com.dosemate.app.data.repo.MedicineRepository
import com.dosemate.app.data.repo.PhotoStore
import com.dosemate.app.data.repo.SettingsRepository
import com.dosemate.core.AlertStyle
import com.dosemate.core.DurationType
import com.dosemate.core.ScheduleType
import com.dosemate.core.SlotTimes
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.io.File
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import javax.inject.Inject
import kotlin.random.Random

/** A dose time row in the editor. */
data class TimeRow(val id: Long, val time: LocalTime, val enabled: Boolean = true, val style: AlertStyle? = null)

@HiltViewModel
class EditMedicineViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    savedState: SavedStateHandle,
    private val repo: MedicineRepository,
    private val settingsRepo: SettingsRepository,
    private val engine: ReminderEngine,
    private val photos: PhotoStore,
    private val tones: ToneLibrary,
) : ViewModel() {

    val id: Long = savedState.get<Long>("id") ?: 0L
    val isNew = id == 0L

    var draft by mutableStateOf(newDraft())
        private set
    var times by mutableStateOf(listOf(TimeRow(0, LocalTime.of(8, 0))))
        private set
    var loaded by mutableStateOf(isNew)
        private set
    var error by mutableStateOf<Int?>(null)
        private set
    var recording by mutableStateOf(false)
        private set

    val photoDir: File = photos.dir(PhotoStore.MEDICINE)
    private val player = OneShotPlayer(context)
    private val recorder = VoiceRecorder(context, photos)

    /** Other medicines that this one can be linked to. */
    val others: StateFlow<List<MedicineWithTimes>> = repo.medicines
        .map { list -> list.filter { it.medicine.id != id && !it.medicine.archived } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    init {
        if (!isNew) {
            viewModelScope.launch {
                repo.get(id)?.let { med ->
                    draft = med.medicine
                    times = med.times.sortedBy { it.minuteOfDay }
                        .map { TimeRow(it.id, LocalTime.of(it.minuteOfDay / 60, it.minuteOfDay % 60), it.enabled, it.alertStyle) }
                }
                loaded = true
            }
        }
    }

    private fun newDraft(): MedicineEntity {
        val s = settingsRepo.current()
        return MedicineEntity(
            name = "",
            colorIndex = Random.nextInt(10),
            startDate = LocalDate.now(),
            trackFrom = LocalDateTime.now(),
            alertStyle = s.defaultTabletStyle,
            repeatIntervalMinutes = s.repeatInterval,
            repeatMax = s.repeatMax,
            durationType = DurationType.DAYS,
            durationDays = 7,
        )
    }

    fun update(transform: (MedicineEntity) -> MedicineEntity) {
        draft = transform(draft)
        error = null
    }

    /** Changing the type of a new medicine also picks sensible defaults. */
    fun setType(type: MedicineType) {
        val s = settingsRepo.current()
        update {
            if (!isNew) it.copy(type = type) else it.copy(
                type = type,
                icon = when (type) {
                    MedicineType.TABLET -> MedIcon.PILL
                    MedicineType.CAPSULE -> MedIcon.CAPSULE
                    MedicineType.CREAM, MedicineType.OINTMENT -> MedIcon.TUBE
                    MedicineType.DROPS -> MedIcon.DROPPER
                    MedicineType.SYRUP -> MedIcon.BOTTLE
                    MedicineType.INJECTION -> MedIcon.SYRINGE
                    MedicineType.OTHER -> MedIcon.HEART
                },
                doseUnit = when (type) {
                    MedicineType.TABLET -> "tablet"
                    MedicineType.CAPSULE -> "capsule"
                    MedicineType.CREAM, MedicineType.OINTMENT -> "application"
                    MedicineType.DROPS -> "drops"
                    MedicineType.SYRUP -> "ml"
                    MedicineType.INJECTION -> "injection"
                    MedicineType.OTHER -> "dose"
                },
                alertStyle = if (type == MedicineType.TABLET || type == MedicineType.CAPSULE) s.defaultTabletStyle else s.defaultOtherStyle,
            )
        }
    }

    fun setScheduleType(type: ScheduleType) {
        update { it.copy(scheduleType = type) }
        if (type == ScheduleType.TIMES_PER_DAY) regenerateTimes()
    }

    fun regenerateTimes() {
        val d = draft
        val generated = SlotTimes.evenlySpaced(
            d.timesPerDay.coerceIn(1, 12),
            LocalTime.of(d.windowStartMinute / 60, d.windowStartMinute % 60),
            LocalTime.of(d.windowEndMinute / 60, d.windowEndMinute % 60),
        )
        times = generated.mapIndexed { i, t -> TimeRow(times.getOrNull(i)?.id ?: 0, t, true, times.getOrNull(i)?.style) }
    }

    fun addTime() {
        val last = times.maxByOrNull { it.time }?.time ?: LocalTime.of(8, 0)
        times = times + TimeRow(0, last.plusHours(4).withMinute(0))
    }

    fun setTime(index: Int, row: TimeRow) {
        times = times.toMutableList().also { it[index] = row }
        error = null
    }

    fun removeTime(index: Int) {
        if (times.size > 1) times = times.toMutableList().also { it.removeAt(index) }
    }

    fun importPhoto(uri: Uri) = viewModelScope.launch {
        photos.import(PhotoStore.MEDICINE, uri)?.let { name -> update { it.copy(photoPath = name) } }
    }

    fun newCaptureTarget(): Pair<String, Uri> = photos.newCaptureTarget(PhotoStore.MEDICINE)

    fun capturedPhoto(name: String, success: Boolean) = viewModelScope.launch {
        if (success && photos.normalize(PhotoStore.MEDICINE, name)) update { it.copy(photoPath = name) }
        else photos.delete(PhotoStore.MEDICINE, name)
    }

    fun removePhoto() = update { it.copy(photoPath = null) }

    fun importTone(uri: Uri) = viewModelScope.launch {
        tones.importFile(uri)?.let { name ->
            val label = runCatching {
                context.contentResolver.query(uri, arrayOf(android.provider.OpenableColumns.DISPLAY_NAME), null, null, null)
                    ?.use { c -> if (c.moveToFirst()) c.getString(0) else null }
            }.getOrNull()
            update { it.copy(toneType = ToneType.FILE, toneUri = name, toneName = label ?: name) }
        }
    }

    fun setSystemTone(uri: Uri?, title: String?) =
        update { it.copy(toneType = if (uri == null) ToneType.DEFAULT else ToneType.SYSTEM, toneUri = uri?.toString(), toneName = title) }

    fun startRecording(): Boolean {
        recording = recorder.start()
        return recording
    }

    fun stopRecording(label: String) {
        recording = false
        recorder.stop()?.let { name -> update { it.copy(toneType = ToneType.VOICE, toneUri = name, toneName = label) } }
    }

    fun previewTone() {
        val d = draft
        player.play(tones.resolve(d.toneType, d.toneUri, forAlarm = true), d.vibration)
    }

    fun save(onSaved: () -> Unit) {
        val d = draft
        when {
            d.name.isBlank() -> error = com.dosemate.app.R.string.error_name
            times.none { it.enabled } -> error = com.dosemate.app.R.string.error_times
            d.durationType == DurationType.END_DATE && d.endDate == null -> error = com.dosemate.app.R.string.error_end_date
            else -> viewModelScope.launch {
                val cleaned = d.copy(
                    name = d.name.trim(),
                    // Keep the start-date weekday for weekly doses unless one was chosen.
                    weekdays = if (d.scheduleType == ScheduleType.WEEKLY && d.weekdays == 0) {
                        1 shl (d.startDate.dayOfWeek.value - 1)
                    } else d.weekdays,
                    linkedMedicineId = d.linkedMedicineId?.takeIf { it != id },
                    refillAlerted = d.stockEnabled && d.stockCount <= d.refillThreshold && d.refillAlerted,
                )
                repo.save(
                    cleaned,
                    times.distinctBy { it.time }.map {
                        DoseTimeEntity(id = it.id, medicineId = id, minuteOfDay = it.time.hour * 60 + it.time.minute, enabled = it.enabled, alertStyle = it.style)
                    },
                )
                engine.rescheduleAll()
                onSaved()
            }
        }
    }

    override fun onCleared() {
        player.stop()
        recorder.stop()
        super.onCleared()
    }
}
