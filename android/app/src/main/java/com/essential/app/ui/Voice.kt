package com.essential.app.ui

import android.Manifest
import android.annotation.SuppressLint
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.MotionEvent
import android.view.View
import android.widget.TextView

/**
 * Hold-to-speak using Android's speech recognizer, preferring on-device/offline recognition.
 * Kannada works when the phone's offline language pack is installed; otherwise we explain and fall back to typing.
 */
class VoiceInput(private val a: MainActivity, private val onText: (String, Boolean) -> Unit, private val onState: (String?) -> Unit) {
    private var rec: SpeechRecognizer? = null
    private var triedFallback = false
    private var lang = "en-IN"
    private var finalDelivered = false

    fun lang(): String = a.repo.settings.str("voice_lang")

    fun start() {
        if (!Perms.mic(a)) {
            a.requestPerm(Manifest.permission.RECORD_AUDIO) { ok ->
                if (!ok) onState("Microphone permission is needed for voice. You can type instead.") else onState("Permission granted — hold the mic again to speak.")
            }
            return
        }
        if (!SpeechRecognizer.isRecognitionAvailable(a)) { onState("Voice recognition isn't available on this phone. Type instead."); return }
        lang = lang(); triedFallback = false; finalDelivered = false
        begin(onDevice = Build.VERSION.SDK_INT >= 31 && SpeechRecognizer.isOnDeviceRecognitionAvailable(a))
    }

    private fun begin(onDevice: Boolean) {
        destroy()
        val r = if (onDevice && Build.VERSION.SDK_INT >= 31) SpeechRecognizer.createOnDeviceSpeechRecognizer(a) else SpeechRecognizer.createSpeechRecognizer(a)
        rec = r
        r.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) { onState("Listening…") }
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() { onState("Processing…") }
            override fun onError(error: Int) {
                val langErr = error == 12 || error == 13 // ERROR_LANGUAGE_NOT_SUPPORTED / UNAVAILABLE (API 31+)
                if (onDevice && !triedFallback && (langErr || error == SpeechRecognizer.ERROR_CLIENT)) { triedFallback = true; begin(false); return }
                val kn = lang.startsWith("kn")
                onState(when {
                    kn && (langErr || error == SpeechRecognizer.ERROR_NETWORK || error == SpeechRecognizer.ERROR_SERVER || error == SpeechRecognizer.ERROR_NETWORK_TIMEOUT) ->
                        "Kannada offline voice isn't installed on this phone. Please type — or add the Kannada offline speech pack in your phone's language/voice settings."
                    error == SpeechRecognizer.ERROR_NETWORK || error == SpeechRecognizer.ERROR_SERVER || error == SpeechRecognizer.ERROR_NETWORK_TIMEOUT ->
                        "Offline voice pack for this language isn't installed. Type instead."
                    error == SpeechRecognizer.ERROR_NO_MATCH || error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "Didn't catch that. Hold the mic and speak again."
                    error == SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Microphone permission is needed."
                    else -> "Voice didn't work this time (code $error). Type instead."
                })
            }
            override fun onResults(results: Bundle?) {
                val t = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                if (!t.isNullOrBlank()) { finalDelivered = true; onText(t, true); onState(null) } else onState("Didn't catch that. Try again.")
            }
            override fun onPartialResults(partialResults: Bundle?) {
                partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()?.let { if (it.isNotBlank()) onText(it, false) }
            }
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
        start2()
    }

    private fun start2() {
        val i = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
            .putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            .putExtra(RecognizerIntent.EXTRA_LANGUAGE, lang)
            .putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, lang)
            .putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            .putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            .putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        try { rec?.startListening(i) } catch (e: Exception) { onState("Voice couldn't start. Type instead.") }
    }

    fun stop() { try { rec?.stopListening() } catch (_: Exception) { } }

    fun destroy() { try { rec?.destroy() } catch (_: Exception) { }; rec = null }

    companion object {
        /** A round mic button: hold to speak, release to finish. */
        @SuppressLint("ClickableViewAccessibility")
        fun holdButton(a: MainActivity, voice: VoiceInput, status: TextView): View {
            val b = a.txt("Hold to speak", 14.5f, Th.onPrimary, Fonts.medium, center = true)
            val d = Icon("mic", Th.onPrimary, a.dp(20)); d.setBounds(0, 0, a.dp(20), a.dp(20))
            b.setCompoundDrawables(d, null, null, null); b.compoundDrawablePadding = a.dp(8)
            b.setPadding(a.dp(18), a.dp(12), a.dp(18), a.dp(12)); b.minHeight = a.dp(48)
            b.background = rounded(Th.primary, a.dp(24).toFloat())
            b.contentDescription = "Hold to speak"
            b.setOnTouchListener { v, e ->
                when (e.actionMasked) {
                    MotionEvent.ACTION_DOWN -> { v.haptic(); v.alpha = 0.7f; status.text = "Listening…"; status.visibility = View.VISIBLE; voice.start() }
                    MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> { v.alpha = 1f; voice.stop() }
                }
                true
            }
            return b
        }
    }
}
