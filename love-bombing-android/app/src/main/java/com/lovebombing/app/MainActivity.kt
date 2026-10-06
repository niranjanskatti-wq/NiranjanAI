package com.lovebombing.app

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import com.lovebombing.app.notify.ReminderScheduler
import com.lovebombing.app.ui.AppViewModel
import com.lovebombing.app.ui.LoveBombingTheme
import com.lovebombing.app.ui.MainScreen
import com.lovebombing.app.ui.SuggestionRequest

class MainActivity : ComponentActivity() {
    private val vm: AppViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        if (savedInstanceState == null) handle(intent)
        setContent {
            LoveBombingTheme { MainScreen(vm) }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handle(intent)
    }

    private fun handle(intent: Intent?) {
        val category = intent?.getStringExtra(ReminderScheduler.EXTRA_CATEGORY) ?: return
        vm.requestSuggestion(SuggestionRequest(category, intent.getStringExtra(ReminderScheduler.EXTRA_FESTIVAL)))
    }
}
