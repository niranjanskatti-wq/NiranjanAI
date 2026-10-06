package com.lovebombing.app.ui

import android.app.Application
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.lovebombing.app.LoveBombingApp
import com.lovebombing.app.data.Message
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
