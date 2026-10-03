package com.dosemate.app.data.repo

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.Uri
import androidx.core.content.FileProvider
import androidx.room.withTransaction
import com.dosemate.app.data.db.ActiveAlertDao
import com.dosemate.app.data.db.AppDatabase
import com.dosemate.app.data.db.DoseLogDao
import com.dosemate.app.data.db.DoseLogEntity
import com.dosemate.app.data.db.DoseTimeEntity
import com.dosemate.app.data.db.JournalDao
import com.dosemate.app.data.db.JournalEntryEntity
import com.dosemate.app.data.db.MedicineDao
import com.dosemate.app.data.db.MedicineEntity
import com.dosemate.app.data.db.MedicineWithTimes
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MedicineRepository @Inject constructor(
    private val db: AppDatabase,
    private val dao: MedicineDao,
    private val alerts: ActiveAlertDao,
) {
    val medicines: Flow<List<MedicineWithTimes>> = dao.observeAll()

    fun observe(id: Long): Flow<MedicineWithTimes?> = dao.observe(id)

    suspend fun all(): List<MedicineWithTimes> = dao.getAll()

    suspend fun get(id: Long): MedicineWithTimes? = dao.get(id)

    /** Inserts or updates a medicine together with its dose times. Returns the medicine id. */
    suspend fun save(medicine: MedicineEntity, times: List<DoseTimeEntity>): Long = db.withTransaction {
        val id = if (medicine.id == 0L) dao.insert(medicine) else medicine.id.also { dao.update(medicine) }
        val existing = dao.timesFor(id)
        val keepIds = times.map { it.id }.filter { it != 0L }.toSet()
        existing.filter { it.id !in keepIds }.forEach { dao.deleteTime(it) }
        times.forEach { dao.upsertTime(it.copy(medicineId = id)) }
        id
    }

    suspend fun setPaused(id: Long, paused: Boolean) {
        dao.setPaused(id, paused, LocalDateTime.now())
        if (paused) alerts.deleteForMedicine(id)
    }

    suspend fun setArchived(id: Long, archived: Boolean) {
        dao.setArchived(id, archived)
        if (archived) alerts.deleteForMedicine(id)
    }

    suspend fun dismissBanner(id: Long) = dao.dismissBanner(id)
    suspend fun markCelebrated(id: Long) = dao.markCelebrated(id)
    suspend fun setStock(id: Long, count: Double, alerted: Boolean) = dao.setStock(id, count, alerted)
    suspend fun delete(id: Long) = dao.delete(id)
}

@Singleton
class LogRepository @Inject constructor(private val dao: DoseLogDao) {
    fun observeBetween(from: LocalDate, to: LocalDate): Flow<List<DoseLogEntity>> =
        dao.observeBetween(from.atStartOfDay(), to.atTime(LocalTime.MAX))

    suspend fun between(from: LocalDate, to: LocalDate): List<DoseLogEntity> =
        dao.between(from.atStartOfDay(), to.atTime(LocalTime.MAX))

    fun observeAll(): Flow<List<DoseLogEntity>> = dao.observeAll()
    suspend fun all(): List<DoseLogEntity> = dao.all()
    fun observeRecent(medicineId: Long, limit: Int = 30) = dao.observeRecent(medicineId, limit)
}

@Singleton
class JournalRepository @Inject constructor(
    private val dao: JournalDao,
    private val photos: PhotoStore,
) {
    val entries: Flow<List<JournalEntryEntity>> = dao.observeAll()
    suspend fun all() = dao.all()
    suspend fun get(id: Long) = dao.get(id)
    suspend fun save(entry: JournalEntryEntity): Long = dao.upsert(entry)

    suspend fun delete(entry: JournalEntryEntity) {
        entry.photoPath?.let { photos.delete(PhotoStore.JOURNAL, it) }
        dao.delete(entry.id)
    }
}

/**
 * Stores photos in the app's private files directory. These folders are never scanned by the
 * media store, so medicine and skin photos stay out of the gallery.
 */
@Singleton
class PhotoStore @Inject constructor(@ApplicationContext private val context: Context) {

    fun dir(folder: String): File = File(context.filesDir, folder).apply { mkdirs() }

    fun file(folder: String, name: String): File = File(dir(folder), name)

    /** Creates an empty file and a content Uri the camera app can write to. */
    fun newCaptureTarget(folder: String): Pair<String, Uri> {
        val name = "${UUID.randomUUID()}.jpg"
        val file = file(folder, name)
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.files", file)
        return name to uri
    }

    /** Copies an image into private storage, downscaled and rotated upright. Returns the file name. */
    suspend fun import(folder: String, uri: Uri): String? = withContext(Dispatchers.IO) {
        runCatching {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            context.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
            var sample = 1
            while (bounds.outWidth / sample > MAX_EDGE * 2 || bounds.outHeight / sample > MAX_EDGE * 2) sample *= 2
            val bitmap = context.contentResolver.openInputStream(uri)?.use {
                BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = sample })
            } ?: return@runCatching null
            val rotation = context.contentResolver.openInputStream(uri)?.use { exifRotation(it.readBytes()) } ?: 0
            val name = "${UUID.randomUUID()}.jpg"
            save(scaleAndRotate(bitmap, rotation), file(folder, name))
            name
        }.getOrNull()
    }

    /** Re-encodes a freshly captured camera photo in place (downscale + rotate). */
    suspend fun normalize(folder: String, name: String): Boolean = withContext(Dispatchers.IO) {
        val f = file(folder, name)
        if (!f.exists() || f.length() == 0L) return@withContext false
        import(folder, Uri.fromFile(f))?.let { newName ->
            file(folder, newName).renameTo(f)
        }
        true
    }

    fun delete(folder: String, name: String) {
        file(folder, name).delete()
    }

    private fun save(bitmap: Bitmap, file: File) {
        FileOutputStream(file).use { bitmap.compress(Bitmap.CompressFormat.JPEG, 88, it) }
    }

    private fun scaleAndRotate(src: Bitmap, rotation: Int): Bitmap {
        val scale = minOf(1f, MAX_EDGE.toFloat() / maxOf(src.width, src.height))
        val matrix = Matrix().apply {
            postScale(scale, scale)
            if (rotation != 0) postRotate(rotation.toFloat())
        }
        return Bitmap.createBitmap(src, 0, 0, src.width, src.height, matrix, true)
    }

    /** Minimal EXIF orientation reader so we do not need the exifinterface library. */
    private fun exifRotation(bytes: ByteArray): Int {
        return runCatching {
            val stream = java.io.ByteArrayInputStream(bytes)
            val exif = android.media.ExifInterface(stream)
            when (exif.getAttributeInt(android.media.ExifInterface.TAG_ORIENTATION, 1)) {
                android.media.ExifInterface.ORIENTATION_ROTATE_90 -> 90
                android.media.ExifInterface.ORIENTATION_ROTATE_180 -> 180
                android.media.ExifInterface.ORIENTATION_ROTATE_270 -> 270
                else -> 0
            }
        }.getOrDefault(0)
    }

    companion object {
        const val MEDICINE = "photos"
        const val JOURNAL = "journal"
        const val VOICE = "voice"
        const val TONES = "tones"
        private const val MAX_EDGE = 1600
    }
}
