package com.dosemate.app.data.repo

import com.dosemate.app.data.db.DismissMethod
import com.dosemate.app.data.db.DoseTimeEntity
import com.dosemate.app.data.db.FoodRelation
import com.dosemate.app.data.db.MedIcon
import com.dosemate.app.data.db.MedicineEntity
import com.dosemate.app.data.db.MedicineType
import com.dosemate.core.AlertStyle
import com.dosemate.core.DurationType
import com.dosemate.core.ScheduleType
import java.time.LocalDate
import java.time.LocalDateTime
import javax.inject.Inject
import javax.inject.Singleton

/** Loads the prescribed treatment plan on first launch. Everything stays editable. */
@Singleton
class PlanSeeder @Inject constructor(
    private val medicines: MedicineRepository,
    private val settings: SettingsRepository,
) {
    suspend fun seedIfNeeded(start: LocalDate = LocalDate.now()) {
        if (settings.current().seeded) return
        seed(start)
        settings.update {
            it.copy(
                seeded = true,
                doctorName = "Dr. Vijendran Pragasam",
                prescribedDate = LocalDate.of(2026, 9, 30),
                dietNote = "Avoid groundnuts, brinjal, pickles, Ajinomoto, bakery products.",
            )
        }
    }

    suspend fun seed(start: LocalDate) {
        val now = LocalDateTime.now()
        fun time(h: Int, m: Int = 0, enabled: Boolean = true) =
            DoseTimeEntity(medicineId = 0, minuteOfDay = h * 60 + m, enabled = enabled)

        medicines.save(
            MedicineEntity(
                name = "HHzole Cream",
                type = MedicineType.CREAM,
                colorIndex = 0,
                icon = MedIcon.TUBE,
                doseAmount = 1.0,
                doseUnit = "application",
                instructions = "Apply on affected area, rub gently.",
                notes = "Wash hands before and after.",
                startDate = start,
                durationType = DurationType.DAYS,
                durationDays = 21,
                trackFrom = now,
                alertStyle = AlertStyle.SOUND,
            ),
            listOf(time(8)),
        )

        val pacromaId = medicines.save(
            MedicineEntity(
                name = "Pacroma 1% Cream",
                type = MedicineType.CREAM,
                colorIndex = 4,
                icon = MedIcon.MOON,
                doseAmount = 1.0,
                doseUnit = "thin layer",
                instructions = "Apply a thin layer on affected area.",
                notes = "Mild burning in first few days is common.",
                startDate = start,
                durationType = DurationType.DAYS,
                durationDays = 42,
                trackFrom = now,
                alertStyle = AlertStyle.SOUND,
            ),
            listOf(time(21, 30)),
        )

        medicines.save(
            MedicineEntity(
                name = "Cetaphil Moisturising Cream",
                type = MedicineType.CREAM,
                colorIndex = 2,
                icon = MedIcon.TUBE,
                doseAmount = 1.0,
                doseUnit = "application",
                instructions = "Apply on dry skin, 30 minutes after Pacroma.",
                scheduleType = ScheduleType.CUSTOM_TIMES,
                startDate = start,
                durationType = DurationType.END_DATE,
                endDate = start.plusMonths(1).minusDays(1),
                linkedMedicineId = pacromaId,
                linkedGapMinutes = 30,
                trackFrom = now,
                alertStyle = AlertStyle.SOUND,
            ),
            listOf(time(13, enabled = false), time(18, enabled = false), time(22)),
        )

        medicines.save(
            MedicineEntity(
                name = "Teczine M Tablet",
                type = MedicineType.TABLET,
                colorIndex = 1,
                icon = MedIcon.PILL,
                doseAmount = 1.0,
                doseUnit = "tablet",
                food = FoodRelation.AFTER,
                instructions = "1 tablet after food.",
                warning = "Avoid alcohol. May cause drowsiness; be careful while driving.",
                startDate = start,
                durationType = DurationType.DAYS,
                durationDays = 10,
                trackFrom = now,
                alertStyle = AlertStyle.ALARM,
                dismissMethod = DismissMethod.SLIDE,
                stockEnabled = true,
                stockCount = 10.0,
                refillThreshold = 2.0,
            ),
            listOf(time(21)),
        )

        medicines.save(
            MedicineEntity(
                name = "Forcan-150 Tablet",
                type = MedicineType.TABLET,
                colorIndex = 3,
                icon = MedIcon.CAPSULE,
                doseAmount = 1.0,
                doseUnit = "tablet",
                food = FoodRelation.AFTER,
                instructions = "1 tablet after food, once a week.",
                banner = "Confirm weekly dosing with your doctor/pharmacist.",
                scheduleType = ScheduleType.WEEKLY,
                startDate = start,
                durationType = DurationType.DOSES,
                durationDoses = 4,
                trackFrom = now,
                alertStyle = AlertStyle.ALARM,
                dismissMethod = DismissMethod.SLIDE,
                stockEnabled = true,
                stockCount = 4.0,
                refillThreshold = 1.0,
            ),
            listOf(time(9)),
        )
    }
}
