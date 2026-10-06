package com.lovebombing.app.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.lovebombing.app.R
import com.lovebombing.app.data.Message
import com.lovebombing.app.data.Suggest

private const val ALL = "All"
private const val FAVORITES = "Favourites ♥"

@Composable
fun MessagesScreen(vm: AppViewModel) {
    val sender = LocalSender.current
    val sent by vm.sent.collectAsState()
    val favorites by vm.favorites.collectAsState()
    val content = vm.content
    var query by rememberSaveable { mutableStateOf("") }
    var filter by rememberSaveable { mutableStateOf(ALL) }
    var randomId by rememberSaveable { mutableStateOf<Int?>(null) }
    val sentIds = remember(sent) { sent.mapNotNull { it.messageId }.toSet() }
    val chips = remember {
        listOf(ALL, FAVORITES, com.lovebombing.app.data.Content.LONG_CATEGORY) +
            content.categories.filter { it != com.lovebombing.app.data.Content.LONG_CATEGORY }
    }

    val shown = remember(query, filter, favorites) {
        val q = query.trim()
        content.messages.filter { m ->
            (filter == ALL || (filter == FAVORITES && m.id in favorites) || m.category == filter) &&
                (q.isEmpty() || m.text.contains(q, ignoreCase = true) || m.category.contains(q, ignoreCase = true))
        }
    }
    val listState = rememberLazyListState()
    LaunchedEffect(filter, query) { listState.scrollToItem(0) }

    Column(Modifier.fillMaxSize()) {
        Row(Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp), verticalAlignment = Alignment.CenterVertically) {
            Text("Messages", style = MaterialTheme.typography.headlineMedium, color = Plum, modifier = Modifier.weight(1f))
            FilledTonalButton(onClick = {
                val recent = Suggest.recentIds(sent)
                val pool = shown.filter { it.id !in recent }.ifEmpty { shown }
                randomId = pool.randomOrNull()?.id
            }) {
                Icon(painterResource(R.drawable.ic_shuffle), contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text("Random")
            }
        }
        OutlinedTextField(
            value = query,
            onValueChange = { query = it },
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
            placeholder = { Text("Search ${content.messages.size} messages") },
            leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
            trailingIcon = {
                if (query.isNotEmpty()) IconButton(onClick = { query = "" }) { Icon(Icons.Filled.Clear, contentDescription = "Clear search") }
            },
            singleLine = true,
            shape = RoundedCornerShape(50),
            colors = OutlinedTextFieldDefaults.colors(focusedContainerColor = Color.White, unfocusedContainerColor = Color.White),
        )
        ChipRow(chips, filter, { it }, { filter = it })
        Text(
            "${shown.size} message${if (shown.size == 1) "" else "s"}",
            style = MaterialTheme.typography.bodySmall, color = Muted,
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp),
        )
        LazyColumn(
            state = listState,
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            val random = content.message(randomId)
            if (random != null) {
                item(key = "random") {
                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Eyebrow("Random pick", color = Marigold)
                            Spacer(Modifier.weight(1f))
                            TextButton(onClick = { randomId = null }) { Text("Hide") }
                        }
                        MessageRow(random, favorites, sentIds, vm, sender)
                    }
                }
            }
            if (shown.isEmpty()) {
                item {
                    Text(
                        if (filter == FAVORITES) "Tap the heart on any message to save it here." else "No messages match that search.",
                        style = MaterialTheme.typography.bodyLarge, color = Muted, modifier = Modifier.padding(vertical = 32.dp),
                    )
                }
            }
            items(shown, key = { it.id }) { m -> MessageRow(m, favorites, sentIds, vm, sender) }
        }
    }
}

@Composable
private fun MessageRow(m: Message, favorites: Set<Int>, sentIds: Set<Int>, vm: AppViewModel, sender: Sender) {
    MessageCard(
        text = sender.textOf(m),
        category = m.category,
        isFavorite = m.id in favorites,
        isSent = m.id in sentIds,
        onWhatsApp = { sender.whatsApp(m) },
        onCopy = { sender.copy(m) },
        onFavorite = { vm.toggleFavorite(m.id) },
    )
}
