package com.dosemate.app

import android.content.Context
import android.os.Bundle
import android.os.SystemClock
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.dosemate.app.data.repo.SettingsRepository
import com.dosemate.app.ui.navigation.DoseMateRoot
import com.dosemate.app.util.LocaleHelper
import dagger.hilt.android.AndroidEntryPoint

/** FragmentActivity (a ComponentActivity) so BiometricPrompt can be used for the app lock. */
@AndroidEntryPoint
class MainActivity : FragmentActivity() {

    private val viewModel: MainViewModel by viewModels()
    private var stoppedAt = 0L

    override fun attachBaseContext(newBase: Context) {
        super.attachBaseContext(LocaleHelper.wrap(newBase, SettingsRepository.read(newBase).language))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        lifecycle.addObserver(object : DefaultLifecycleObserver {
            override fun onStop(owner: LifecycleOwner) {
                stoppedAt = SystemClock.elapsedRealtime()
            }

            override fun onStart(owner: LifecycleOwner) {
                if (stoppedAt != 0L && SystemClock.elapsedRealtime() - stoppedAt > LOCK_AFTER_MS) viewModel.lockIfEnabled()
                viewModel.refresh()
            }
        })
        setContent { DoseMateRoot(viewModel, this) }
    }

    companion object {
        private const val LOCK_AFTER_MS = 30_000L
    }
}
