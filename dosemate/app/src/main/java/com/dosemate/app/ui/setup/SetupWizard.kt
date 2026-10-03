package com.dosemate.app.ui.setup

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Alarm
import androidx.compose.material.icons.rounded.BatteryChargingFull
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.ExpandLess
import androidx.compose.material.icons.rounded.ExpandMore
import androidx.compose.material.icons.rounded.Fullscreen
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.Notifications
import androidx.compose.material.icons.rounded.PhoneAndroid
import androidx.compose.material.icons.rounded.RadioButtonUnchecked
import androidx.compose.material.icons.rounded.Verified
import androidx.compose.material3.Button
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringArrayResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.LifecycleEventEffect
import androidx.lifecycle.viewModelScope
import com.dosemate.app.R
import com.dosemate.app.alarm.ReminderEngine
import com.dosemate.app.data.repo.MedicineRepository
import com.dosemate.app.ui.components.AppCard
import com.dosemate.app.ui.components.GradientBackground
import com.dosemate.app.ui.theme.StatusColors
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SetupViewModel @Inject constructor(
    private val engine: ReminderEngine,
    private val medicines: MedicineRepository,
) : ViewModel() {
    fun testAlarm() = viewModelScope.launch {
        medicines.all().firstOrNull { !it.medicine.archived }?.let { engine.testAlarm(it.medicine.id) }
    }

    fun refresh() = viewModelScope.launch { engine.rescheduleAll() }
}

private data class Step(val icon: ImageVector, val title: Int, val text: Int)

private val steps = listOf(
    Step(Icons.Rounded.Verified, R.string.setup_welcome_title, R.string.setup_welcome_text),
    Step(Icons.Rounded.Notifications, R.string.setup_notif_title, R.string.setup_notif_text),
    Step(Icons.Rounded.Alarm, R.string.setup_exact_title, R.string.setup_exact_text),
    Step(Icons.Rounded.Fullscreen, R.string.setup_fullscreen_title, R.string.setup_fullscreen_text),
    Step(Icons.Rounded.BatteryChargingFull, R.string.setup_battery_title, R.string.setup_battery_text),
    Step(Icons.Rounded.PhoneAndroid, R.string.setup_oem_title, R.string.setup_oem_text),
    Step(Icons.Rounded.CheckCircle, R.string.setup_test_title, R.string.setup_test_text),
)

@Composable
fun SetupWizard(onDone: () -> Unit, viewModel: SetupViewModel = hiltViewModel()) {
    val context = LocalContext.current
    var step by rememberSaveable { mutableIntStateOf(0) }
    var tick by remember { mutableIntStateOf(0) }
    LifecycleEventEffect(Lifecycle.Event.ON_RESUME) { tick++ }
    val notifLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { tick++ }

    // Re-checked whenever we come back from a system settings screen (tick changes on resume).
    val granted = remember(step, tick) {
        when (step) {
            1 -> Permissions.notificationsGranted(context)
            2 -> Permissions.exactAlarmsGranted(context)
            3 -> Permissions.fullScreenGranted(context)
            4 -> Permissions.batteryUnrestricted(context)
            else -> null
        }
    }

    GradientBackground {
        Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(24.dp)) {
            LinearProgressIndicator(progress = { (step + 1f) / steps.size }, modifier = Modifier.fillMaxWidth())
            Spacer(Modifier.height(24.dp))
            AnimatedContent(
                targetState = step,
                transitionSpec = { (fadeIn() + slideInHorizontally { it / 6 }) togetherWith fadeOut() },
                modifier = Modifier.weight(1f),
                label = "step",
            ) { index ->
                val s = steps[index]
                Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()), horizontalAlignment = Alignment.CenterHorizontally) {
                    Box(
                        Modifier.size(96.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primary.copy(alpha = 0.14f)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(s.icon, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(48.dp))
                    }
                    Spacer(Modifier.height(20.dp))
                    Text(stringResource(s.title), style = MaterialTheme.typography.headlineSmall, textAlign = TextAlign.Center)
                    Spacer(Modifier.height(10.dp))
                    Text(stringResource(s.text), style = MaterialTheme.typography.bodyLarge, textAlign = TextAlign.Center,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.height(20.dp))
                    when (index) {
                        0 -> PrivacyPoints()
                        1 -> PermissionAction(granted == true) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !Permissions.notificationsGranted(context)) {
                                notifLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                            } else {
                                Permissions.openNotificationSettings(context)
                            }
                        }
                        2 -> PermissionAction(granted == true) { Permissions.openExactAlarmSettings(context) }
                        3 -> PermissionAction(granted == true) { Permissions.openFullScreenSettings(context) }
                        4 -> PermissionAction(granted == true) { Permissions.requestBatteryExemption(context) }
                        5 -> OemGuides()
                        6 -> {
                            FilledTonalButton(onClick = viewModel::testAlarm, modifier = Modifier.fillMaxWidth()) {
                                Icon(Icons.Rounded.Alarm, null)
                                Spacer(Modifier.width(8.dp))
                                Text(stringResource(R.string.test_alarm))
                            }
                            Spacer(Modifier.height(16.dp))
                            ChecklistSummary(tick)
                        }
                    }
                }
            }
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                if (step > 0) TextButton(onClick = { step-- }) { Text(stringResource(R.string.back)) }
                Spacer(Modifier.weight(1f))
                if (step in 1..4 && granted != true) {
                    TextButton(onClick = { step++ }) { Text(stringResource(R.string.skip_for_now)) }
                }
                Button(onClick = {
                    if (step < steps.lastIndex) step++ else {
                        viewModel.refresh()
                        onDone()
                    }
                }) {
                    Text(stringResource(if (step < steps.lastIndex) R.string.next else R.string.finish))
                }
            }
        }
    }
}

@Composable
private fun PrivacyPoints() {
    AppCard {
        listOf(R.string.privacy_point_1, R.string.privacy_point_2, R.string.privacy_point_3).forEach {
            Row(Modifier.padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Rounded.Lock, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(10.dp))
                Text(stringResource(it), style = MaterialTheme.typography.bodyMedium)
            }
        }
    }
}

@Composable
private fun PermissionAction(granted: Boolean, onGrant: () -> Unit) {
    if (granted) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.CheckCircle, null, tint = StatusColors.Taken)
            Spacer(Modifier.width(8.dp))
            Text(stringResource(R.string.granted), color = StatusColors.Taken, style = MaterialTheme.typography.titleMedium)
        }
    } else {
        Button(onClick = onGrant, modifier = Modifier.fillMaxWidth().height(52.dp)) { Text(stringResource(R.string.grant)) }
    }
}

@Composable
private fun ChecklistSummary(tick: Int) {
    val context = LocalContext.current
    val items = remember(tick) {
        listOf(
            R.string.setup_notif_title to Permissions.notificationsGranted(context),
            R.string.setup_exact_title to Permissions.exactAlarmsGranted(context),
            R.string.setup_fullscreen_title to Permissions.fullScreenGranted(context),
            R.string.setup_battery_title to Permissions.batteryUnrestricted(context),
        )
    }
    AppCard {
        items.forEach { (label, ok) ->
            Row(Modifier.padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(if (ok) Icons.Rounded.CheckCircle else Icons.Rounded.RadioButtonUnchecked, null,
                    tint = if (ok) StatusColors.Taken else StatusColors.Missed)
                Spacer(Modifier.width(10.dp))
                Text(stringResource(label), style = MaterialTheme.typography.bodyMedium)
            }
        }
    }
}

/** Step-by-step guides for phones with aggressive battery managers. */
@Composable
fun OemGuides() {
    val context = LocalContext.current
    val detected = Oem.detect()
    val guides = listOf(
        Oem.SAMSUNG to (R.string.oem_samsung to R.array.oem_samsung_steps),
        Oem.XIAOMI to (R.string.oem_xiaomi to R.array.oem_xiaomi_steps),
        Oem.VIVO to (R.string.oem_vivo to R.array.oem_vivo_steps),
        Oem.OPPO to (R.string.oem_oppo to R.array.oem_oppo_steps),
        Oem.REALME to (R.string.oem_realme to R.array.oem_realme_steps),
        Oem.ONEPLUS to (R.string.oem_oneplus to R.array.oem_oneplus_steps),
    ).sortedByDescending { it.first == detected }
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        guides.forEach { (oem, res) ->
            var open by rememberSaveable(oem) { mutableStateOf(oem == detected) }
            AppCard {
                Row(Modifier.fillMaxWidth().clickable { open = !open }, verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        stringResource(res.first) + if (oem == detected) "  •  " + stringResource(R.string.your_phone) else "",
                        style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f),
                    )
                    Icon(if (open) Icons.Rounded.ExpandLess else Icons.Rounded.ExpandMore, null)
                }
                if (open) {
                    stringArrayResource(res.second).forEachIndexed { i, line ->
                        Text("${i + 1}. $line", style = MaterialTheme.typography.bodyMedium, modifier = Modifier.padding(top = 6.dp))
                    }
                    if (oem == detected) {
                        Spacer(Modifier.height(8.dp))
                        OutlinedButton(onClick = { Permissions.openOemSettings(context) }) { Text(stringResource(R.string.open_settings)) }
                    }
                }
            }
        }
        if (detected == Oem.OTHER) {
            OutlinedButton(onClick = { Permissions.openAppDetails(context) }, modifier = Modifier.fillMaxWidth()) {
                Text(stringResource(R.string.open_app_settings))
            }
        }
    }
}
