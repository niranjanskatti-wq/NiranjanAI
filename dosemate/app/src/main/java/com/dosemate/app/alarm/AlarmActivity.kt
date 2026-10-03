package com.dosemate.app.alarm

import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.Restaurant
import androidx.compose.material.icons.rounded.Snooze
import androidx.compose.material.icons.rounded.WarningAmber
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringArrayResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.lifecycleScope
import com.dosemate.app.R
import com.dosemate.app.data.db.DismissMethod
import com.dosemate.app.data.db.FoodRelation
import com.dosemate.app.data.db.MedicineWithTimes
import com.dosemate.app.data.repo.MedicineRepository
import com.dosemate.app.data.repo.PhotoStore
import com.dosemate.app.data.repo.SettingsRepository
import com.dosemate.app.ui.components.SlideToConfirm
import com.dosemate.app.ui.components.medIcon
import com.dosemate.app.ui.components.rememberPhoto
import com.dosemate.app.ui.theme.DoseMateTheme
import com.dosemate.app.ui.theme.medicineColor
import com.dosemate.app.util.LocaleHelper
import com.dosemate.app.util.TimeFormat
import com.dosemate.app.util.doseLine
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.launch
import java.time.LocalTime
import javax.inject.Inject
import kotlin.random.Random

/** Full-screen alarm shown over the lock screen while [AlarmService] rings. */
@AndroidEntryPoint
class AlarmActivity : ComponentActivity() {

    @Inject lateinit var engine: ReminderEngine
    @Inject lateinit var medicines: MedicineRepository
    @Inject lateinit var settingsRepo: SettingsRepository
    @Inject lateinit var photos: PhotoStore

    override fun attachBaseContext(newBase: Context) {
        super.attachBaseContext(LocaleHelper.wrap(newBase, SettingsRepository.read(newBase).language))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        enableEdgeToEdge()

        val locked = getSystemService(KeyguardManager::class.java).isKeyguardLocked
        setContent {
            val settings by settingsRepo.settings.collectAsState(settingsRepo.current())
            val ringing by RingingAlarms.ringing.collectAsState()
            val key = ringing.lastOrNull()
            LaunchedEffect(ringing.isEmpty()) {
                if (ringing.isEmpty()) {
                    delay(300)
                    if (RingingAlarms.ringing.value.isEmpty()) finish()
                }
            }
            val med by remember(key?.medicineId) {
                key?.let { medicines.observe(it.medicineId) } ?: flowOf(null)
            }.collectAsState(null)

            BackHandler { /* An alarm must be answered. */ }

            DoseMateTheme(settings) {
                if (key != null) {
                    AlarmScreen(
                        med = med,
                        key = key,
                        others = ringing.size - 1,
                        use24h = settings.use24h,
                        hideDetails = settings.hideNames && locked,
                        snoozeOptions = settings.snoozeOptions,
                        photoDir = photos.dir(PhotoStore.MEDICINE),
                        onTaken = { act { engine.markTaken(key) } },
                        onSnooze = { minutes -> act { engine.snooze(key, minutes) } },
                        onAfterFood = { minutes -> act { engine.snooze(key, minutes, afterFood = true) } },
                        onSkip = { reason -> act { engine.markSkipped(key, reason) } },
                    )
                }
            }
        }
    }

    private fun act(block: suspend () -> Unit) {
        lifecycleScope.launch { block() }
    }
}

@Composable
private fun AlarmScreen(
    med: MedicineWithTimes?,
    key: DoseKey,
    others: Int,
    use24h: Boolean,
    hideDetails: Boolean,
    snoozeOptions: List<Int>,
    photoDir: java.io.File,
    onTaken: () -> Unit,
    onSnooze: (Int) -> Unit,
    onAfterFood: (Int) -> Unit,
    onSkip: (String?) -> Unit,
) {
    val m = med?.medicine
    val color = m?.let { medicineColor(it.colorIndex) } ?: MaterialTheme.colorScheme.primary
    val haptics = LocalHapticFeedback.current
    var reveal by remember { mutableStateOf(!hideDetails) }
    var showSnooze by remember { mutableStateOf(false) }
    var showSkip by remember { mutableStateOf(false) }
    var showMath by remember { mutableStateOf<(() -> Unit)?>(null) }
    var now by remember { mutableStateOf(LocalTime.now()) }
    LaunchedEffect(Unit) {
        while (true) {
            now = LocalTime.now()
            delay(1000)
        }
    }
    val pulse = rememberInfiniteTransition(label = "pulse")
    val scale by pulse.animateFloat(1f, 1.08f, infiniteRepeatable(tween(900), RepeatMode.Reverse), label = "scale")
    val dismiss = m?.dismissMethod ?: DismissMethod.BUTTONS

    /** Runs [action] after the configured challenge (math) when needed. */
    fun guarded(action: () -> Unit) {
        if (dismiss == DismissMethod.MATH && !key.test) showMath = action else action()
    }

    Box(
        Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(color.copy(alpha = 0.95f), Color(0xFF0B1116))))
            .statusBarsPadding()
            .navigationBarsPadding(),
    ) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                TimeFormat.time(now, use24h),
                color = Color.White,
                fontSize = 56.sp,
                fontWeight = FontWeight.Light,
            )
            Text(
                if (key.test) stringResource(R.string.alarm_test_label) else stringResource(R.string.alarm_time_for_dose),
                color = Color.White.copy(alpha = 0.8f),
                style = MaterialTheme.typography.titleMedium,
            )
            Spacer(Modifier.height(28.dp))

            val photo = rememberPhoto(m?.photoPath?.let { java.io.File(photoDir, it) }, 600)
            Box(
                Modifier.size(150.dp).scale(scale).clip(CircleShape).background(Color.White.copy(alpha = 0.18f)),
                contentAlignment = Alignment.Center,
            ) {
                if (photo != null && reveal) {
                    Image(photo.asImageBitmap(), null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                } else {
                    Icon(m?.let { medIcon(it.icon) } ?: Icons.Rounded.Check, null, tint = Color.White, modifier = Modifier.size(72.dp))
                }
            }
            Spacer(Modifier.height(24.dp))
            if (reveal && m != null) {
                Text(m.name, color = Color.White, style = MaterialTheme.typography.headlineLarge, textAlign = TextAlign.Center)
                Spacer(Modifier.height(8.dp))
                val context = androidx.compose.ui.platform.LocalContext.current
                Text(context.doseLine(m), color = Color.White.copy(alpha = 0.92f), style = MaterialTheme.typography.titleLarge, textAlign = TextAlign.Center)
                if (m.instructions.isNotBlank()) {
                    Spacer(Modifier.height(6.dp))
                    Text(m.instructions, color = Color.White.copy(alpha = 0.8f), style = MaterialTheme.typography.bodyLarge, textAlign = TextAlign.Center)
                }
                if (m.warning.isNotBlank()) {
                    Spacer(Modifier.height(12.dp))
                    Row(
                        Modifier.clip(RoundedCornerShape(14.dp)).background(Color.Black.copy(alpha = 0.25f)).padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Rounded.WarningAmber, null, tint = Color(0xFFFFD27A))
                        Spacer(Modifier.size(8.dp))
                        Text(m.warning, color = Color.White, style = MaterialTheme.typography.bodyMedium)
                    }
                }
            } else {
                Text(stringResource(R.string.notif_private_title), color = Color.White, style = MaterialTheme.typography.headlineMedium)
                TextButton(onClick = { reveal = true }) { Text(stringResource(R.string.alarm_show_details), color = Color.White) }
            }
            Text(
                TimeFormat.time(key.scheduledAt.toLocalTime(), use24h) +
                    if (others > 0) "  ·  " + stringResource(R.string.alarm_more, others) else "",
                color = Color.White.copy(alpha = 0.7f),
                modifier = Modifier.padding(top = 12.dp),
            )

            Spacer(Modifier.height(32.dp))

            val takenLabel = stringResource(R.string.action_taken)
            if (dismiss == DismissMethod.SLIDE && !key.test) {
                SlideToConfirm(stringResource(R.string.alarm_slide_taken), Color(0xFF2FA866)) {
                    haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                    onTaken()
                }
            } else {
                Button(
                    onClick = {
                        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                        guarded(onTaken)
                    },
                    modifier = Modifier.fillMaxWidth().height(72.dp),
                    shape = RoundedCornerShape(36.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2FA866), contentColor = Color.White),
                ) {
                    Icon(Icons.Rounded.Check, null, modifier = Modifier.size(30.dp))
                    Spacer(Modifier.size(10.dp))
                    Text(takenLabel, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                }
            }
            Spacer(Modifier.height(14.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(
                    onClick = { showSnooze = !showSnooze },
                    modifier = Modifier.weight(1f).height(56.dp),
                    shape = RoundedCornerShape(28.dp),
                ) {
                    Icon(Icons.Rounded.Snooze, null, tint = Color.White)
                    Spacer(Modifier.size(6.dp))
                    Text(stringResource(R.string.action_snooze), color = Color.White)
                }
                OutlinedButton(
                    onClick = { guarded { showSkip = true } },
                    modifier = Modifier.weight(1f).height(56.dp),
                    shape = RoundedCornerShape(28.dp),
                ) {
                    Text(stringResource(R.string.action_skip), color = Color.White)
                }
            }
            AnimatedVisibility(showSnooze) {
                FlowRow(Modifier.fillMaxWidth().padding(top = 12.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    snoozeOptions.forEach { minutes ->
                        FilterChip(
                            selected = false,
                            onClick = { onSnooze(minutes) },
                            label = { Text(stringResource(R.string.minutes_short, minutes), color = Color.White) },
                        )
                    }
                }
            }
            if (m?.food == FoodRelation.AFTER) {
                Spacer(Modifier.height(16.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Rounded.Restaurant, null, tint = Color.White.copy(alpha = 0.85f))
                    Spacer(Modifier.size(8.dp))
                    Text(stringResource(R.string.alarm_after_eat), color = Color.White.copy(alpha = 0.85f))
                }
                Row(Modifier.padding(top = 6.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf(15, 30, 45).forEach { minutes ->
                        FilterChip(
                            selected = false,
                            onClick = { onAfterFood(minutes) },
                            label = { Text(stringResource(R.string.minutes_short, minutes), color = Color.White) },
                        )
                    }
                }
            }
        }
    }

    if (showSkip) {
        SkipReasonDialog(onDismiss = { showSkip = false }, onConfirm = { reason ->
            showSkip = false
            onSkip(reason)
        })
    }
    showMath?.let { action ->
        MathChallengeDialog(onDismiss = { showMath = null }, onSolved = {
            showMath = null
            action()
        })
    }
}

@Composable
fun SkipReasonDialog(onDismiss: () -> Unit, onConfirm: (String?) -> Unit) {
    val reasons = stringArrayResource(R.array.skip_reasons)
    var reason by remember { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.skip_title)) },
        text = {
            Column {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    reasons.forEach { r ->
                        FilterChip(selected = reason == r, onClick = { reason = r }, label = { Text(r) })
                    }
                }
                Spacer(Modifier.height(8.dp))
                OutlinedTextField(
                    value = reason, onValueChange = { reason = it },
                    label = { Text(stringResource(R.string.skip_reason_hint)) },
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
        confirmButton = { TextButton(onClick = { onConfirm(reason.ifBlank { null }) }) { Text(stringResource(R.string.action_skip)) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.cancel)) } },
    )
}

@Composable
private fun MathChallengeDialog(onDismiss: () -> Unit, onSolved: () -> Unit) {
    val a = remember { Random.nextInt(12, 60) }
    val b = remember { Random.nextInt(3, 40) }
    var answer by remember { mutableStateOf("") }
    var wrong by remember { mutableStateOf(false) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.math_title)) },
        text = {
            Column {
                Text("$a + $b = ?", style = MaterialTheme.typography.headlineMedium)
                Spacer(Modifier.height(12.dp))
                OutlinedTextField(
                    value = answer,
                    onValueChange = { answer = it.filter(Char::isDigit).take(4); wrong = false },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    isError = wrong,
                    singleLine = true,
                )
                if (wrong) Text(stringResource(R.string.math_wrong), color = MaterialTheme.colorScheme.error)
            }
        },
        confirmButton = {
            TextButton(onClick = { if (answer.toIntOrNull() == a + b) onSolved() else wrong = true }) {
                Text(stringResource(R.string.ok))
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.cancel)) } },
    )
}
