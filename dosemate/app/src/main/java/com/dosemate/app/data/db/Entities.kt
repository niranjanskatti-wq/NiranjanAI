package com.dosemate.app.data.db

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.dosemate.core.AlertStyle
import com.dosemate.core.DurationType
import com.dosemate.core.LogStatus
import com.dosemate.core.ScheduleType
import java.time.LocalDate
import java.time.LocalDateTime

enum class MedicineType { TABLET, CAPSULE, CREAM, OINTMENT, DROPS, SYRUP, INJECTION, OTHER }

enum class MedIcon { PILL, CAPSULE, TUBE, DROPPER, BOTTLE, SYRINGE, LEAF, HEART, SUN, MOON }

enum class FoodRelation { NONE, BEFORE, AFTER, WITH }

/** Where the alarm tone comes from. */
enum class ToneType { DEFAULT, BUILTIN, SYSTEM, FILE, VOICE }

enum class VibrationPattern(val timings: LongArray) {
    NONE(longArrayOf()),
    GENTLE(longArrayOf(0, 300, 1200)),
    STANDARD(longArrayOf(0, 600, 600)),
    HEARTBEAT(longArrayOf(0, 120, 120, 260, 900)),
    URGENT(longArrayOf(0, 250, 120, 250, 120, 800, 400)),
}

/** What it takes to silence an alarm. */
enum class DismissMethod { BUTTONS, SLIDE, MATH }

@Entity(tableName = "medicines")
data class MedicineEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val name: String,
    val type: MedicineType = MedicineType.TABLET,
    val colorIndex: Int = 0,
    val icon: MedIcon = MedIcon.PILL,
    val photoPath: String? = null,
    val doseAmount: Double = 1.0,
    val doseUnit: String = "tablet",
    val instructions: String = "",
    val food: FoodRelation = FoodRelation.NONE,
    val notes: String = "",
    val warning: String = "",
    /** One-time banner shown on Today until dismissed. */
    val banner: String = "",
    val bannerDismissed: Boolean = false,

    val scheduleType: ScheduleType = ScheduleType.DAILY,
    /** Bit mask, bit 0 = Monday … bit 6 = Sunday. */
    val weekdays: Int = 0,
    val intervalDays: Int = 1,
    val timesPerDay: Int = 1,
    val windowStartMinute: Int = 8 * 60,
    val windowEndMinute: Int = 22 * 60,
    val startDate: LocalDate,
    val durationType: DurationType = DurationType.ONGOING,
    val endDate: LocalDate? = null,
    val durationDays: Int? = null,
    val durationDoses: Int? = null,

    val linkedMedicineId: Long? = null,
    val linkedGapMinutes: Int = 30,
    /** The prescription this medicine belongs to (null = none). */
    val prescriptionId: Long? = null,

    val paused: Boolean = false,
    val archived: Boolean = false,
    /** Doses before this moment are never auto-marked as missed (set on create and resume). */
    val trackFrom: LocalDateTime,

    val stockEnabled: Boolean = false,
    val stockCount: Double = 0.0,
    val stockPerDose: Double = 1.0,
    val refillThreshold: Double = 5.0,
    val refillAlerted: Boolean = false,

    val alertStyle: AlertStyle = AlertStyle.ALARM,
    val toneType: ToneType = ToneType.DEFAULT,
    val toneUri: String? = null,
    val toneName: String? = null,
    val vibration: VibrationPattern = VibrationPattern.STANDARD,
    val flashlight: Boolean = false,
    val dismissMethod: DismissMethod = DismissMethod.BUTTONS,
    val repeatIntervalMinutes: Int = 5,
    val repeatMax: Int = 3,
    val preAlarmMinutes: Int = 0,

    val completedCelebrated: Boolean = false,
    val createdAt: Long = System.currentTimeMillis(),
)

@Entity(
    tableName = "dose_times",
    foreignKeys = [
        ForeignKey(
            entity = MedicineEntity::class,
            parentColumns = ["id"],
            childColumns = ["medicineId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("medicineId")],
)
data class DoseTimeEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val medicineId: Long,
    val minuteOfDay: Int,
    val enabled: Boolean = true,
    /** Null = use the medicine's alert style. */
    val alertStyle: AlertStyle? = null,
)

@Entity(
    tableName = "dose_logs",
    foreignKeys = [
        ForeignKey(
            entity = MedicineEntity::class,
            parentColumns = ["id"],
            childColumns = ["medicineId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index(value = ["medicineId", "slotId", "scheduledAt"], unique = true), Index("scheduledAt")],
)
data class DoseLogEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val medicineId: Long,
    val slotId: Long,
    /** Wall-clock time the dose was due. */
    val scheduledAt: LocalDateTime,
    val status: LogStatus,
    /** Wall-clock time of the action. */
    val actionAt: LocalDateTime,
    val skipReason: String? = null,
)

@Entity(
    tableName = "active_alerts",
    foreignKeys = [
        ForeignKey(
            entity = MedicineEntity::class,
            parentColumns = ["id"],
            childColumns = ["medicineId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index(value = ["medicineId", "slotId", "scheduledAt"], unique = true)],
)
data class ActiveAlertEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val medicineId: Long,
    val slotId: Long,
    val scheduledAt: LocalDateTime,
    val nextFireAt: LocalDateTime,
    val repeatCount: Int = 0,
    /** Set when the user asked to be reminded after eating. */
    val waitingForFood: Boolean = false,
    /** Set by snooze: the next ring starts a fresh repeat cycle. */
    val snoozed: Boolean = false,
)

@Entity(tableName = "journal_entries", indices = [Index("date")])
data class JournalEntryEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val date: LocalDate,
    /** File name inside the app's private journal folder. */
    val photoPath: String? = null,
    val itchScore: Int = 0,
    val notes: String = "",
    val createdAt: Long = System.currentTimeMillis(),
)

/** A prescription from one doctor. Medicines point to it through [MedicineEntity.prescriptionId]. */
@Entity(tableName = "prescriptions")
data class PrescriptionEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val doctorName: String,
    val date: LocalDate? = null,
    /** Diet advice and other notes from this doctor. */
    val notes: String = "",
    val createdAt: Long = System.currentTimeMillis(),
)
