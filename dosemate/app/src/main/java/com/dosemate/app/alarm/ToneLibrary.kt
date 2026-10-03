package com.dosemate.app.alarm

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import com.dosemate.app.R
import com.dosemate.app.data.db.ToneType
import com.dosemate.app.data.db.VibrationPattern
import com.dosemate.app.data.repo.PhotoStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.DataOutputStream
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.sin

/** A built-in tone, synthesised on first use so the APK carries no audio files. */
enum class BuiltInTone(val id: String, val label: Int) {
    CHIME("chime", R.string.tone_chime),
    SUNRISE("sunrise", R.string.tone_sunrise),
    PULSE("pulse", R.string.tone_pulse),
    BELLS("bells", R.string.tone_bells),
    DIGITAL("digital", R.string.tone_digital),
}

@Singleton
class ToneLibrary @Inject constructor(
    @ApplicationContext private val context: Context,
    private val photos: PhotoStore,
) {
    /** Resolves a medicine's tone to a playable Uri, or null to use the system default. */
    fun resolve(type: ToneType, value: String?, forAlarm: Boolean): Uri? = when (type) {
        ToneType.DEFAULT -> defaultUri(forAlarm)
        ToneType.BUILTIN -> BuiltInTone.entries.firstOrNull { it.id == value }?.let { Uri.fromFile(builtIn(it)) }
        ToneType.SYSTEM -> value?.let(Uri::parse)
        ToneType.FILE -> value?.let { photos.file(PhotoStore.TONES, it) }?.takeIf { it.exists() }?.let(Uri::fromFile)
        ToneType.VOICE -> value?.let { photos.file(PhotoStore.VOICE, it) }?.takeIf { it.exists() }?.let(Uri::fromFile)
    } ?: defaultUri(forAlarm)

    fun defaultUri(forAlarm: Boolean): Uri =
        (if (forAlarm) RingtoneManager.getActualDefaultRingtoneUri(context, RingtoneManager.TYPE_ALARM) else null)
            ?: RingtoneManager.getDefaultUri(if (forAlarm) RingtoneManager.TYPE_ALARM else RingtoneManager.TYPE_NOTIFICATION)
            ?: Uri.fromFile(builtIn(BuiltInTone.CHIME))

    fun fallbackUri(): Uri = Uri.fromFile(builtIn(BuiltInTone.CHIME))

    /** Copies a user-chosen audio file into private storage. Returns its stored name. */
    suspend fun importFile(uri: Uri): String? = withContext(Dispatchers.IO) {
        runCatching {
            val name = "${UUID.randomUUID()}.audio"
            context.contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(photos.file(PhotoStore.TONES, name)).use { input.copyTo(it) }
            } ?: return@runCatching null
            name
        }.getOrNull()
    }

    @Synchronized
    fun builtIn(tone: BuiltInTone): File {
        val file = photos.file(PhotoStore.TONES, "builtin_${tone.id}.wav")
        if (!file.exists() || file.length() < 1000) writeWav(file, synthesize(tone))
        return file
    }

    private fun synthesize(tone: BuiltInTone): ShortArray {
        val rate = SAMPLE_RATE
        // (frequency Hz, start s, length s)
        val notes: List<Triple<Double, Double, Double>> = when (tone) {
            BuiltInTone.CHIME -> listOf(Triple(880.0, 0.0, 1.2), Triple(1318.5, 0.35, 1.4))
            BuiltInTone.SUNRISE -> listOf(523.25, 659.25, 783.99, 1046.5).mapIndexed { i, f -> Triple(f, i * 0.22, 0.9) }
            BuiltInTone.PULSE -> (0 until 4).map { Triple(1000.0, it * 0.25, 0.14) }
            BuiltInTone.BELLS -> listOf(Triple(523.25, 0.0, 1.6), Triple(659.25, 0.5, 1.6), Triple(783.99, 1.0, 1.6))
            BuiltInTone.DIGITAL -> (0 until 6).map { Triple(if (it % 2 == 0) 1200.0 else 900.0, it * 0.16, 0.12) }
        }
        val total = 2.4
        val out = DoubleArray((rate * total).toInt())
        for ((freq, start, len) in notes) {
            val s0 = (start * rate).toInt()
            val n = (len * rate).toInt()
            for (i in 0 until n) {
                val idx = s0 + i
                if (idx >= out.size) break
                val t = i.toDouble() / rate
                val attack = (t / 0.01).coerceAtMost(1.0)
                val env = attack * exp(-3.2 * t / len)
                out[idx] += env * (sin(2 * PI * freq * t) + 0.35 * sin(4 * PI * freq * t))
            }
        }
        val peak = out.maxOf { kotlin.math.abs(it) }.coerceAtLeast(1e-6)
        return ShortArray(out.size) { (out[it] / peak * 0.85 * Short.MAX_VALUE).toInt().toShort() }
    }

    private fun writeWav(file: File, pcm: ShortArray) {
        DataOutputStream(FileOutputStream(file).buffered()).use { out ->
            fun intLE(v: Int) { out.write(v and 0xff); out.write(v shr 8 and 0xff); out.write(v shr 16 and 0xff); out.write(v shr 24 and 0xff) }
            fun shortLE(v: Int) { out.write(v and 0xff); out.write(v shr 8 and 0xff) }
            val dataSize = pcm.size * 2
            out.writeBytes("RIFF"); intLE(36 + dataSize); out.writeBytes("WAVE")
            out.writeBytes("fmt "); intLE(16); shortLE(1); shortLE(1); intLE(SAMPLE_RATE); intLE(SAMPLE_RATE * 2); shortLE(2); shortLE(16)
            out.writeBytes("data"); intLE(dataSize)
            pcm.forEach { shortLE(it.toInt()) }
        }
    }

    companion object {
        private const val SAMPLE_RATE = 22_050
    }
}

/** Plays a short sound + vibration once, for "notification + sound" doses with a custom tone. */
class OneShotPlayer(private val context: Context) {
    private var player: MediaPlayer? = null
    private val handler = Handler(Looper.getMainLooper())

    fun play(uri: Uri, vibration: VibrationPattern, maxMillis: Long = 8_000) {
        stop()
        runCatching {
            player = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_EVENT)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                setDataSource(context, uri)
                setOnCompletionListener { stop() }
                prepare()
                start()
            }
        }
        Vibration.once(context, vibration)
        handler.postDelayed({ stop() }, maxMillis)
    }

    fun stop() {
        handler.removeCallbacksAndMessages(null)
        runCatching { player?.stop() }
        runCatching { player?.release() }
        player = null
    }
}

object Vibration {
    fun vibrator(context: Context): Vibrator =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Vibrator::class.java)
        }

    fun once(context: Context, pattern: VibrationPattern) {
        if (pattern == VibrationPattern.NONE) return
        runCatching { vibrator(context).vibrate(VibrationEffect.createWaveform(pattern.timings, -1)) }
    }

    @Suppress("DEPRECATION")
    fun loop(context: Context, pattern: VibrationPattern) {
        if (pattern == VibrationPattern.NONE) return
        runCatching {
            val attrs = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build()
            vibrator(context).vibrate(VibrationEffect.createWaveform(pattern.timings, 0), attrs)
        }
    }

    fun cancel(context: Context) {
        runCatching { vibrator(context).cancel() }
    }
}

/** Records a short voice note to use as an alarm tone. */
class VoiceRecorder(private val context: Context, private val photos: PhotoStore) {
    private var recorder: MediaRecorder? = null
    var currentName: String? = null
        private set

    fun start(): Boolean = runCatching {
        val name = "${UUID.randomUUID()}.m4a"
        val file = photos.file(PhotoStore.VOICE, name)
        val r = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) MediaRecorder(context) else @Suppress("DEPRECATION") MediaRecorder()
        r.setAudioSource(MediaRecorder.AudioSource.MIC)
        r.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        r.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        r.setAudioSamplingRate(44_100)
        r.setAudioEncodingBitRate(96_000)
        r.setOutputFile(file.absolutePath)
        r.prepare()
        r.start()
        recorder = r
        currentName = name
        true
    }.getOrDefault(false)

    /** Stops recording and returns the stored file name. */
    fun stop(): String? {
        val r = recorder ?: return null
        recorder = null
        return runCatching {
            r.stop()
            r.release()
            currentName
        }.getOrElse {
            r.release()
            null
        }
    }
}
