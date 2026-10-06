package com.lovebombing.app.ui

import android.app.Application
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import android.content.Context
import com.lovebombing.app.LoveBombingApp
import com.lovebombing.app.data.AutoPlanSetting
import com.lovebombing.app.data.Message
import com.lovebombing.app.data.PlanItem
import com.lovebombing.app.data.PlanStatus
import com.lovebombing.app.data.PlanStatusRow
import java.time.LocalDate
import com.lovebombing.app.data.Plan
import com.lovebombing.app.data.SentMessage
import com.lovebombing.app.data.Settings
import com.lovebombing.app.data.WishlistItem
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

sealed interface SettingsState {
    data object Loading : SettingsState
    data class Ready(val settings: Settings) : SettingsState
}

/** A message suggestion opened from a notification tap. */
data class SuggestionRequest(val category: String, val festivalKey: String?)

class AppViewModel(app: Application) : AndroidViewModel(app) {
    private val repo = (app as LoveBombingApp).repository
    val content = repo.content

    val settings: StateFlow<SettingsState> = repo.dao.settingsFlow()
        .map { SettingsState.Ready(it ?: Settings()) }
        .stateIn(viewModelScope, SharingStarted.Eagerly, SettingsState.Loading)

    val sent: StateFlow<List<SentMessage>> = repo.dao.sentFlow()
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    val favorites: StateFlow<Set<Int>> = repo.dao.favoritesFlow()
        .map { list -> list.map { it.messageId }.toSet() }
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptySet())

    val plans: StateFlow<List<Plan>> = repo.dao.plansFlow()
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    val wishlist: StateFlow<List<WishlistItem>> = repo.dao.wishlistFlow()
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    val autoPlans: StateFlow<Map<String, AutoPlanSetting>> = repo.dao.autoPlansFlow()
        .map { list -> list.associateBy { it.templateId } }
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyMap())

    val statuses: StateFlow<Map<String, PlanStatusRow>> = repo.dao.statusFlow()
        .map { list -> list.associateBy { it.key } }
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyMap())

    private val uiPrefs = app.getSharedPreferences("ui_state", Context.MODE_PRIVATE)

    /** Home shows long, heartfelt messages instead of short texts when true. */
    val preferLong = MutableStateFlow(uiPrefs.getBoolean("prefer_long", false))

    fun setPreferLong(value: Boolean) {
        preferLong.value = value
        homeOffset.value = 0
        uiPrefs.edit().putBoolean("prefer_long", value).apply()
    }

    fun setStatus(item: PlanItem, status: PlanStatus) = viewModelScope.launch { repo.setStatus(item, status) }

    fun moveItem(item: PlanItem, date: LocalDate, minuteOfDay: Int) = viewModelScope.launch { repo.moveItem(item, date, minuteOfDay) }

    fun saveAutoPlan(setting: AutoPlanSetting) = viewModelScope.launch { repo.saveAutoPlan(setting) }

    fun setAllAutoPlans(enabled: Boolean) = viewModelScope.launch { repo.setAllAutoPlans(enabled) }

    private val _suggestion = MutableStateFlow<SuggestionRequest?>(null)
    val suggestion = _suggestion.asStateFlow()

    /** How many times "Next" was pressed on Home today. */
    val homeOffset = MutableStateFlow(0)

    fun requestSuggestion(request: SuggestionRequest?) { _suggestion.value = request }

    fun saveSettings(settings: Settings) = viewModelScope.launch { repo.saveSettings(settings) }

    fun logSent(message: Message?, category: String, text: String) =
        viewModelScope.launch { repo.logSent(message, category, text) }

    fun deleteSent(item: SentMessage) = viewModelScope.launch { repo.dao.deleteSent(item) }

    fun toggleFavorite(id: Int) = viewModelScope.launch { repo.toggleFavorite(id, id in favorites.value) }

    fun savePlan(plan: Plan) = viewModelScope.launch { repo.savePlan(plan) }

    fun deletePlan(plan: Plan) = viewModelScope.launch { repo.deletePlan(plan) }

    fun saveWish(item: WishlistItem) = viewModelScope.launch { repo.dao.saveWish(item) }

    fun deleteWish(item: WishlistItem) = viewModelScope.launch { repo.dao.deleteWish(item) }

    fun export(uri: Uri, done: (Throwable?) -> Unit) = viewModelScope.launch {
        done(runCatching { repo.exportTo(uri) }.exceptionOrNull())
    }

    fun import(uri: Uri, done: (Throwable?) -> Unit) = viewModelScope.launch {
        done(runCatching { repo.importFrom(uri) }.exceptionOrNull())
    }
}
