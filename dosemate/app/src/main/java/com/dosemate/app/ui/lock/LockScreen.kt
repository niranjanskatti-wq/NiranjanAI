package com.dosemate.app.ui.lock

import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.Backspace
import androidx.compose.material.icons.rounded.Fingerprint
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.dosemate.app.R
import com.dosemate.app.ui.components.GradientBackground

/** PIN pad with optional fingerprint / face unlock. */
@Composable
fun LockScreen(activity: FragmentActivity, biometric: Boolean, onPin: (String) -> Boolean, onBiometric: () -> Unit) {
    var pin by remember { mutableStateOf("") }
    var error by remember { mutableStateOf(false) }
    val haptics = LocalHapticFeedback.current
    val title = stringResource(R.string.unlock_title)
    val cancel = stringResource(R.string.use_pin)
    val canBiometric = remember {
        biometric && BiometricManager.from(activity).canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK) ==
            BiometricManager.BIOMETRIC_SUCCESS
    }
    fun prompt() {
        val p = BiometricPrompt(activity, ContextCompat.getMainExecutor(activity), object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) = onBiometric()
        })
        p.authenticate(
            BiometricPrompt.PromptInfo.Builder()
                .setTitle(title)
                .setNegativeButtonText(cancel)
                .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_WEAK)
                .build(),
        )
    }
    LaunchedEffect(Unit) { if (canBiometric) prompt() }

    GradientBackground {
        Column(Modifier.fillMaxSize().padding(32.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
            Icon(Icons.Rounded.Lock, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(48.dp))
            Spacer(Modifier.height(12.dp))
            Text(title, style = MaterialTheme.typography.headlineSmall)
            Spacer(Modifier.height(20.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                repeat(maxOf(4, pin.length)) { i ->
                    Box(
                        Modifier.size(14.dp).clip(CircleShape).background(
                            when {
                                error -> MaterialTheme.colorScheme.error
                                i < pin.length -> MaterialTheme.colorScheme.primary
                                else -> MaterialTheme.colorScheme.outlineVariant
                            },
                        ),
                    )
                }
            }
            if (error) {
                Spacer(Modifier.height(8.dp))
                Text(stringResource(R.string.wrong_pin), color = MaterialTheme.colorScheme.error)
            }
            Spacer(Modifier.height(28.dp))
            val keys = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "bio", "0", "del")
            keys.chunked(3).forEach { row ->
                Row(horizontalArrangement = Arrangement.spacedBy(20.dp), modifier = Modifier.padding(vertical = 8.dp)) {
                    row.forEach { key ->
                        Box(
                            Modifier.size(72.dp).clip(CircleShape)
                                .background(if (key.length == 1) MaterialTheme.colorScheme.surfaceVariant else MaterialTheme.colorScheme.background.copy(alpha = 0f))
                                .clickable(enabled = key != "bio" || canBiometric) {
                                    haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                    when (key) {
                                        "bio" -> prompt()
                                        "del" -> { pin = pin.dropLast(1); error = false }
                                        else -> {
                                            error = false
                                            pin += key
                                            if (pin.length >= 4 && onPin(pin)) pin = ""
                                            else if (pin.length >= 8) { error = true; pin = "" }
                                        }
                                    }
                                },
                            contentAlignment = Alignment.Center,
                        ) {
                            when (key) {
                                "bio" -> if (canBiometric) Icon(Icons.Rounded.Fingerprint, stringResource(R.string.use_biometric), tint = MaterialTheme.colorScheme.primary)
                                "del" -> Icon(Icons.AutoMirrored.Rounded.Backspace, null)
                                else -> Text(key, style = MaterialTheme.typography.headlineSmall)
                            }
                        }
                    }
                }
            }
        }
    }
}
