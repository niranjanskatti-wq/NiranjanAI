package com.dosemate.app.data.db

import androidx.room.Dao
import androidx.room.Database
import androidx.room.Delete
import androidx.room.Embedded
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Relation
import androidx.room.RoomDatabase
import androidx.room.Transaction
import androidx.room.TypeConverter
import androidx.room.TypeConverters
import androidx.room.Update
import androidx.room.Upsert
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneOffset

class Converters {
    @TypeConverter
    fun dateToLong(date: LocalDate?): Long? = date?.toEpochDay()

    @TypeConverter
    fun longToDate(value: Long?): LocalDate? = value?.let(LocalDate::ofEpochDay)

    /** Wall-clock times are stored as seconds since 1970 in "local" time so they survive time zone changes. */
    @TypeConverter
    fun dateTimeToLong(time: LocalDateTime?): Long? = time?.toEpochSecond(ZoneOffset.UTC)

    @TypeConverter
    fun longToDateTime(value: Long?): LocalDateTime? = value?.let { LocalDateTime.ofEpochSecond(it, 0, ZoneOffset.UTC) }
}

data class MedicineWithTimes(
    @Embedded val medicine: MedicineEntity,
    @Relation(parentColumn = "id", entityColumn = "medicineId")
    val times: List<DoseTimeEntity>,
)

@Dao
interface MedicineDao {
    @Transaction
    @Query("SELECT * FROM medicines ORDER BY archived, name COLLATE NOCASE")
    fun observeAll(): Flow<List<MedicineWithTimes>>

    @Transaction
    @Query("SELECT * FROM medicines ORDER BY name COLLATE NOCASE")
    suspend fun getAll(): List<MedicineWithTimes>

    @Transaction
    @Query("SELECT * FROM medicines WHERE id = :id")
    fun observe(id: Long): Flow<MedicineWithTimes?>

    @Transaction
    @Query("SELECT * FROM medicines WHERE id = :id")
    suspend fun get(id: Long): MedicineWithTimes?

    @Insert
    suspend fun insert(medicine: MedicineEntity): Long

    @Update
    suspend fun update(medicine: MedicineEntity)

    @Query("DELETE FROM medicines WHERE id = :id")
    suspend fun delete(id: Long)

    @Query("SELECT * FROM dose_times WHERE medicineId = :medicineId")
    suspend fun timesFor(medicineId: Long): List<DoseTimeEntity>

    @Upsert
    suspend fun upsertTime(time: DoseTimeEntity): Long

    @Delete
    suspend fun deleteTime(time: DoseTimeEntity)

    @Query("UPDATE medicines SET paused = :paused, trackFrom = :trackFrom WHERE id = :id")
    suspend fun setPaused(id: Long, paused: Boolean, trackFrom: LocalDateTime)

    @Query("UPDATE medicines SET prescriptionId = :prescriptionId WHERE prescriptionId IS NULL")
    suspend fun assignUnlinkedTo(prescriptionId: Long)

    @Query("UPDATE medicines SET archived = :archived WHERE id = :id")
    suspend fun setArchived(id: Long, archived: Boolean)

    @Query("UPDATE medicines SET bannerDismissed = 1 WHERE id = :id")
    suspend fun dismissBanner(id: Long)

    @Query("UPDATE medicines SET completedCelebrated = 1 WHERE id = :id")
    suspend fun markCelebrated(id: Long)

    @Query("UPDATE medicines SET stockCount = :count, refillAlerted = :alerted WHERE id = :id")
    suspend fun setStock(id: Long, count: Double, alerted: Boolean)

    @Query("DELETE FROM medicines")
    suspend fun deleteAll()

    @Query("SELECT * FROM dose_times")
    suspend fun allTimes(): List<DoseTimeEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAllRaw(medicines: List<MedicineEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAllTimes(times: List<DoseTimeEntity>)
}

@Dao
interface DoseLogDao {
    @Query("SELECT * FROM dose_logs WHERE scheduledAt BETWEEN :from AND :to ORDER BY scheduledAt")
    fun observeBetween(from: LocalDateTime, to: LocalDateTime): Flow<List<DoseLogEntity>>

    @Query("SELECT * FROM dose_logs WHERE scheduledAt BETWEEN :from AND :to ORDER BY scheduledAt")
    suspend fun between(from: LocalDateTime, to: LocalDateTime): List<DoseLogEntity>

    @Query("SELECT * FROM dose_logs ORDER BY scheduledAt")
    fun observeAll(): Flow<List<DoseLogEntity>>

    @Query("SELECT * FROM dose_logs ORDER BY scheduledAt")
    suspend fun all(): List<DoseLogEntity>

    @Query("SELECT * FROM dose_logs WHERE medicineId = :medicineId ORDER BY scheduledAt DESC LIMIT :limit")
    fun observeRecent(medicineId: Long, limit: Int): Flow<List<DoseLogEntity>>

    @Query("SELECT * FROM dose_logs WHERE medicineId = :medicineId AND slotId = :slotId AND scheduledAt = :scheduledAt")
    suspend fun find(medicineId: Long, slotId: Long, scheduledAt: LocalDateTime): DoseLogEntity?

    @Query("SELECT * FROM dose_logs WHERE status = 'MISSED' AND actionAt > :since ORDER BY scheduledAt")
    suspend fun missedSince(since: LocalDateTime): List<DoseLogEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(log: DoseLogEntity): Long

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertIfAbsent(log: DoseLogEntity): Long

    @Query("DELETE FROM dose_logs WHERE medicineId = :medicineId AND slotId = :slotId AND scheduledAt = :scheduledAt")
    suspend fun delete(medicineId: Long, slotId: Long, scheduledAt: LocalDateTime)

    @Query("DELETE FROM dose_logs")
    suspend fun deleteAll()

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(logs: List<DoseLogEntity>)
}

@Dao
interface ActiveAlertDao {
    @Query("SELECT * FROM active_alerts")
    suspend fun all(): List<ActiveAlertEntity>

    @Query("SELECT * FROM active_alerts")
    fun observeAll(): Flow<List<ActiveAlertEntity>>

    @Query("SELECT * FROM active_alerts WHERE medicineId = :medicineId AND slotId = :slotId AND scheduledAt = :scheduledAt")
    suspend fun find(medicineId: Long, slotId: Long, scheduledAt: LocalDateTime): ActiveAlertEntity?

    @Query("SELECT * FROM active_alerts WHERE slotId = :slotId")
    suspend fun forSlot(slotId: Long): List<ActiveAlertEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(alert: ActiveAlertEntity): Long

    @Query("DELETE FROM active_alerts WHERE medicineId = :medicineId AND slotId = :slotId AND scheduledAt = :scheduledAt")
    suspend fun delete(medicineId: Long, slotId: Long, scheduledAt: LocalDateTime)

    @Query("DELETE FROM active_alerts WHERE medicineId = :medicineId")
    suspend fun deleteForMedicine(medicineId: Long)

    @Query("DELETE FROM active_alerts")
    suspend fun deleteAll()
}

@Dao
interface PrescriptionDao {
    @Query("SELECT * FROM prescriptions ORDER BY date DESC, createdAt DESC")
    fun observeAll(): Flow<List<PrescriptionEntity>>

    @Query("SELECT * FROM prescriptions ORDER BY date DESC, createdAt DESC")
    suspend fun all(): List<PrescriptionEntity>

    @Upsert
    suspend fun upsert(prescription: PrescriptionEntity): Long

    /** Unlinks medicines first so they are kept when a prescription is deleted. */
    @Transaction
    suspend fun deleteKeepingMedicines(id: Long) {
        unlinkMedicines(id)
        delete(id)
    }

    @Query("UPDATE medicines SET prescriptionId = NULL WHERE prescriptionId = :id")
    suspend fun unlinkMedicines(id: Long)

    @Query("DELETE FROM prescriptions WHERE id = :id")
    suspend fun delete(id: Long)

    @Query("DELETE FROM prescriptions")
    suspend fun deleteAll()

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(items: List<PrescriptionEntity>)
}

@Dao
interface JournalDao {
    @Query("SELECT * FROM journal_entries ORDER BY date DESC, createdAt DESC")
    fun observeAll(): Flow<List<JournalEntryEntity>>

    @Query("SELECT * FROM journal_entries ORDER BY date DESC, createdAt DESC")
    suspend fun all(): List<JournalEntryEntity>

    @Query("SELECT * FROM journal_entries WHERE id = :id")
    suspend fun get(id: Long): JournalEntryEntity?

    @Upsert
    suspend fun upsert(entry: JournalEntryEntity): Long

    @Query("DELETE FROM journal_entries WHERE id = :id")
    suspend fun delete(id: Long)

    @Query("DELETE FROM journal_entries")
    suspend fun deleteAll()

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(entries: List<JournalEntryEntity>)
}

@Database(
    entities = [
        MedicineEntity::class,
        DoseTimeEntity::class,
        DoseLogEntity::class,
        ActiveAlertEntity::class,
        JournalEntryEntity::class,
        PrescriptionEntity::class,
    ],
    version = 2,
    exportSchema = true,
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun medicineDao(): MedicineDao
    abstract fun doseLogDao(): DoseLogDao
    abstract fun activeAlertDao(): ActiveAlertDao
    abstract fun journalDao(): JournalDao
    abstract fun prescriptionDao(): PrescriptionDao

    companion object {
        /** v2: multiple prescriptions. The old single doctor from settings is moved over by [PrescriptionMigrator]. */
        val MIGRATION_1_2 = object : androidx.room.migration.Migration(1, 2) {
            override fun migrate(db: androidx.sqlite.db.SupportSQLiteDatabase) {
                db.execSQL(
                    "CREATE TABLE IF NOT EXISTS `prescriptions` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, " +
                        "`doctorName` TEXT NOT NULL, `date` INTEGER, `notes` TEXT NOT NULL, `createdAt` INTEGER NOT NULL)",
                )
                db.execSQL("ALTER TABLE `medicines` ADD COLUMN `prescriptionId` INTEGER")
            }
        }
    }
}
