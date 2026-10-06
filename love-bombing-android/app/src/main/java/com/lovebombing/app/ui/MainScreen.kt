package com.lovebombing.app.ui

import android.Manifest
import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.core.content.ContextCompat
import com.lovebombing.app.R
import com.lovebombing.app.data.Message
import com.lovebombing.app.data.Settings
import com.lovebombing.app.data.personalize
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

enum class Tab(val label: String) { HOME("Home"), MESSAGES("Messages"), CALENDAR("Calendar"), GIFTS("Gifts"), SETTINGS("Settings") }

/** Shares/copies messages and shows feedback. Every share is logged to the calendar. */
class Sender(
    private val context: Context,
    private val vm: AppViewModel,
    private val snackbar: SnackbarHostState,
    private val scope: CoroutineScope,
    private val name: () -> String,
) {
    fun textOf(message: Message) = personalize(message.text, name())

    fun whatsApp(message: Message) {
        val text = textOf(message)
        shareToWhatsApp(context, text)
        vm.logSent(message, message.category, text)
    }

    fun copy(message: Message) {
        val text = textOf(message)
        copyToClipboard(context, text)
        scope.launch {
            val result = snackbar.showSnackbar("Copied. Paste it in her chat.", actionLabel = "Mark sent", duration = SnackbarDuration.Short)
            if (result == SnackbarResult.ActionPerformed) vm.logSent(message, message.category, text)
        }
    }

    fun toast(text: String) {
        scope.launch { snackbar.showSnackbar(text, duration = SnackbarDuration.Short) }
    }
}

val LocalSender = staticCompositionLocalOf<Sender> { error("Sender not provided") }

@Composable
fun MainScreen(vm: AppViewModel) {
    val state by vm.settings.collectAsState()
    val ready = state as? SettingsState.Ready ?: return
    val settings = ready.settings
    val context = LocalContext.current
    val snackbar = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val sender = remember(vm) { Sender(context, vm, snackbar, scope) { vm.settings.value.let { (it as? SettingsState.Ready)?.settings?.wifeName.orEmpty() } } }

    CompositionLocalProvider(LocalSender provides sender) {
        if (!settings.onboarded) {
            OnboardingScreen(onDone = { vm.saveSettings(it.copy(onboarded = true)) })
        } else {
            AppScaffold(vm, settings, snackbar)
        }
    }
}

@Composable
private fun AppScaffold(vm: AppViewModel, settings: Settings, snackbar: SnackbarHostState) {
    var tab by rememberSaveable { mutableStateOf(Tab.HOME) }
    val suggestion by vm.suggestion.collectAsState()
    PermissionPrompts()

    Scaffold(
        snackbarHost = { SnackbarHost(snackbar) },
        containerColor = MaterialTheme.colorScheme.background,
        bottomBar = {
            NavigationBar(containerColor = Color.White) {
                Tab.entries.forEach { t ->
                    NavigationBarItem(
                        selected = t == tab,
                        onClick = { tab = t },
                        icon = { TabIcon(t) },
                        label = { Text(t.label, style = MaterialTheme.typography.labelSmall) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = Plum,
                            selectedTextColor = Plum,
                            indicatorColor = RoseSoft,
                            unselectedIconColor = Muted,
                            unselectedTextColor = Muted,
                        ),
                    )
                }
            }
        },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            when (tab) {
                Tab.HOME -> HomeScreen(vm, settings, onOpenTab = { tab = it })
                Tab.MESSAGES -> MessagesScreen(vm)
                Tab.CALENDAR -> CalendarScreen(vm, settings)
                Tab.GIFTS -> GiftsScreen(vm)
                Tab.SETTINGS -> SettingsScreen(vm, settings)
            }
        }
    }

    suggestion?.let { req -> SuggestionDialog(vm, req, onDismiss = { vm.requestSuggestion(null) }) }
}

@Composable
private fun TabIcon(tab: Tab) {
    val vector: ImageVector? = when (tab) {
        Tab.HOME -> Icons.Filled.Home
        Tab.CALENDAR -> Icons.Filled.DateRange
        Tab.SETTINGS -> Icons.Filled.Settings
        else -> null
    }
    if (vector != null) Icon(vector, contentDescription = null)
    else Icon(painterResource(if (tab == Tab.GIFTS) R.drawable.ic_gift else R.drawable.ic_chat), contentDescription = null)
}

/** Notification permission on first launch (Android 13+), then exact alarms (Android 12+). */
@Composable
private fun PermissionPrompts() {
    val context = LocalContext.current
    val prefs = remember { context.getSharedPreferences("ui_state", Context.MODE_PRIVATE) }
    var askExact by remember { mutableStateOf(false) }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {
        askExact = needsExactAlarm(context) && !prefs.getBoolean("asked_exact", false)
    }
    LaunchedEffect(Unit) {
        val needsNotif = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        if (needsNotif && !prefs.getBoolean("asked_notif", false)) {
            prefs.edit().putBoolean("asked_notif", true).apply()
            launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            askExact = needsExactAlarm(context) && !prefs.getBoolean("asked_exact", false)
        }
    }
    if (askExact) {
        AlertDialog(
            onDismissRequest = { askExact = false; prefs.edit().putBoolean("asked_exact", true).apply() },
            title = { Text("On-time reminders") },
            text = { Text("Allow Love Bombing to set exact alarms so good-morning, good-night and plan reminders arrive right on time.") },
            confirmButton = {
                TextButton(onClick = {
                    askExact = false
                    prefs.edit().putBoolean("asked_exact", true).apply()
                    openExactAlarmSettings(context)
                }) { Text("Allow") }
            },
            dismissButton = {
                TextButton(onClick = { askExact = false; prefs.edit().putBoolean("asked_exact", true).apply() }) { Text("Not now") }
            },
        )
    }
}

fun needsExactAlarm(context: Context): Boolean =
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
        !context.getSystemService(AlarmManager::class.java).canScheduleExactAlarms()

fun openExactAlarmSettings(context: Context) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        runCatching {
            context.startActivity(
                Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:${context.packageName}")),
            )
        }
    }
}

fun notificationsAllowed(context: Context): Boolean =
    Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
        ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
