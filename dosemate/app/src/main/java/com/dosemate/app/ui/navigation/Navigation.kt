package com.dosemate.app.ui.navigation

import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AutoStories
import androidx.compose.material.icons.rounded.CalendarMonth
import androidx.compose.material.icons.rounded.Insights
import androidx.compose.material.icons.rounded.Medication
import androidx.compose.material.icons.rounded.Today
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.dosemate.app.MainViewModel
import com.dosemate.app.R
import com.dosemate.app.ui.celebrate.CelebrationScreen
import com.dosemate.app.ui.history.HistoryScreen
import com.dosemate.app.ui.insights.InsightsScreen
import com.dosemate.app.ui.journal.CompareScreen
import com.dosemate.app.ui.journal.JournalScreen
import com.dosemate.app.ui.lock.LockScreen
import com.dosemate.app.ui.medicines.EditMedicineScreen
import com.dosemate.app.ui.medicines.MedicineDetailScreen
import com.dosemate.app.ui.medicines.MedicinesScreen
import com.dosemate.app.ui.report.ReportScreen
import com.dosemate.app.ui.settings.SettingsScreen
import com.dosemate.app.ui.setup.SetupWizard
import com.dosemate.app.ui.theme.DoseMateTheme
import com.dosemate.app.ui.today.TodayScreen

private data class Tab(val route: String, val label: Int, val icon: ImageVector)

private val tabs = listOf(
    Tab("today", R.string.tab_today, Icons.Rounded.Today),
    Tab("medicines", R.string.tab_medicines, Icons.Rounded.Medication),
    Tab("history", R.string.tab_history, Icons.Rounded.CalendarMonth),
    Tab("insights", R.string.tab_insights, Icons.Rounded.Insights),
    Tab("journal", R.string.tab_journal, Icons.Rounded.AutoStories),
)

@Composable
fun DoseMateRoot(viewModel: MainViewModel, activity: FragmentActivity) {
    val settings by viewModel.settings.collectAsStateWithLifecycle()
    val locked by viewModel.locked.collectAsStateWithLifecycle()
    DoseMateTheme(settings) {
        when {
            locked -> LockScreen(activity, settings.biometric, onPin = viewModel::unlockWithPin, onBiometric = viewModel::unlockBiometric)
            !settings.onboardingDone -> SetupWizard(onDone = viewModel::finishOnboarding)
            else -> MainScaffold(viewModel)
        }
    }
}

@Composable
private fun MainScaffold(viewModel: MainViewModel) {
    val nav = rememberNavController()
    val backStack by nav.currentBackStackEntryAsState()
    val route = backStack?.destination?.route
    val celebration by viewModel.celebration.collectAsStateWithLifecycle()

    celebration?.let { med ->
        CelebrationScreen(
            med = med,
            onArchive = { viewModel.finishCelebration(med.medicine.id, archive = true) },
            onKeep = { viewModel.finishCelebration(med.medicine.id, archive = false) },
        )
        return
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        bottomBar = {
            if (tabs.any { it.route == route }) {
                NavigationBar(containerColor = MaterialTheme.colorScheme.surface) {
                    tabs.forEach { tab ->
                        NavigationBarItem(
                            selected = route == tab.route,
                            onClick = { nav.navigateTab(tab.route) },
                            icon = { Icon(tab.icon, null) },
                            label = { Text(stringResource(tab.label), maxLines = 1) },
                        )
                    }
                }
            }
        },
    ) { padding ->
        NavHost(
            navController = nav,
            startDestination = "today",
            modifier = Modifier.padding(bottom = padding.calculateBottomPadding()).consumeWindowInsets(padding),
            enterTransition = { fadeIn() + slideInHorizontally { it / 12 } },
            exitTransition = { fadeOut() },
            popEnterTransition = { fadeIn() },
            popExitTransition = { fadeOut() + slideOutHorizontally { it / 12 } },
        ) {
            composable("today") {
                TodayScreen(
                    onOpenSettings = { nav.navigate("settings") },
                    onOpenMedicine = { nav.navigate("medicine/$it") },
                    onAddMedicine = { nav.navigate("edit/0") },
                )
            }
            composable("medicines") {
                MedicinesScreen(
                    onOpen = { nav.navigate("medicine/$it") },
                    onAdd = { nav.navigate("edit/0") },
                    onOpenSettings = { nav.navigate("settings") },
                )
            }
            composable("history") { HistoryScreen(onOpenSettings = { nav.navigate("settings") }) }
            composable("insights") {
                InsightsScreen(onOpenReport = { nav.navigate("report") }, onOpenSettings = { nav.navigate("settings") })
            }
            composable("journal") { JournalScreen(onCompare = { nav.navigate("compare") }, onOpenSettings = { nav.navigate("settings") }) }
            composable("compare") { CompareScreen(onBack = { nav.popBackStack() }) }
            composable("report") { ReportScreen(onBack = { nav.popBackStack() }) }
            composable("settings") {
                SettingsScreen(
                    onBack = { nav.popBackStack() },
                    onOpenSetup = { nav.navigate("setup") },
                    onOpenReport = { nav.navigate("report") },
                )
            }
            composable("setup") { SetupWizard(onDone = { nav.popBackStack() }) }
            composable("medicine/{id}", arguments = listOf(navArgument("id") { type = NavType.LongType })) {
                MedicineDetailScreen(
                    onBack = { nav.popBackStack() },
                    onEdit = { id -> nav.navigate("edit/$id") },
                )
            }
            composable("edit/{id}", arguments = listOf(navArgument("id") { type = NavType.LongType })) {
                EditMedicineScreen(onBack = { nav.popBackStack() })
            }
        }
    }
}

private fun NavHostController.navigateTab(route: String) {
    navigate(route) {
        popUpTo(graph.findStartDestination().id) { saveState = true }
        launchSingleTop = true
        restoreState = true
    }
}
