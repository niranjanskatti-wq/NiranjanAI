package com.dosemate.app.ui.celebrate

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.dosemate.app.R
import com.dosemate.app.data.db.MedicineWithTimes
import com.dosemate.app.data.repo.engine
import com.dosemate.app.ui.components.Confetti
import com.dosemate.app.ui.theme.medicineColor

/** Shown once when a full course has been completed. */
@Composable
fun CelebrationScreen(med: MedicineWithTimes, onArchive: () -> Unit, onKeep: () -> Unit) {
    val color = medicineColor(med.medicine.colorIndex)
    val scale = remember { Animatable(0.3f) }
    val haptics = LocalHapticFeedback.current
    LaunchedEffect(med.medicine.id) {
        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
        scale.animateTo(1f, spring(Spring.DampingRatioMediumBouncy, Spring.StiffnessLow))
    }
    val total = med.engine().totalDoses
    Box(
        Modifier.fillMaxSize().background(
            Brush.verticalGradient(listOf(color.copy(alpha = 0.35f), MaterialTheme.colorScheme.background)),
        ),
    ) {
        Confetti()
        Column(
            Modifier.fillMaxSize().padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = androidx.compose.foundation.layout.Arrangement.Center,
        ) {
            Box(
                Modifier.size(140.dp).scale(scale.value).clip(CircleShape).background(color),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Rounded.EmojiEvents, null, tint = Color.White, modifier = Modifier.size(80.dp))
            }
            Spacer(Modifier.height(28.dp))
            Text(stringResource(R.string.celebrate_title), style = MaterialTheme.typography.headlineLarge, textAlign = TextAlign.Center)
            Spacer(Modifier.height(10.dp))
            Text(
                stringResource(R.string.celebrate_text, med.medicine.name) +
                    (total?.let { "\n" + stringResource(R.string.total_doses, it) } ?: ""),
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(36.dp))
            Button(onClick = onArchive, modifier = Modifier.fillMaxWidth().height(56.dp)) { Text(stringResource(R.string.celebrate_archive)) }
            TextButton(onClick = onKeep) { Text(stringResource(R.string.celebrate_keep)) }
        }
    }
}
