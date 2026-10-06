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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.lovebombing.app.data.Budget
import com.lovebombing.app.data.Gift
import com.lovebombing.app.data.Occasion
import com.lovebombing.app.data.PlanType
import com.lovebombing.app.data.WishlistItem

@Composable
fun GiftsScreen(vm: AppViewModel) {
    var wishlistMode by rememberSaveable { mutableStateOf(false) }
    var planDraft by remember { mutableStateOf<PlanDraft?>(null) }

    Column(Modifier.fillMaxSize()) {
        Text("Gifts & surprises", style = MaterialTheme.typography.headlineMedium, color = Plum,
            modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 8.dp))
        ChipRow(listOf(false, true), wishlistMode, { if (it) "Her wishlist" else "150 ideas" }, { wishlistMode = it })
        Spacer(Modifier.height(8.dp))
        if (wishlistMode) WishlistView(vm, onPlan = { planDraft = it }) else IdeasView(vm, onPlan = { planDraft = it })
    }
    planDraft?.let { AddPlanDialog(vm, it, onDismiss = { planDraft = null }) }
}

@Composable
private fun IdeasView(vm: AppViewModel, onPlan: (PlanDraft) -> Unit) {
    var budget by rememberSaveable { mutableStateOf<Budget?>(null) }
    var occasion by rememberSaveable { mutableStateOf<Occasion?>(null) }
    val shown = remember(budget, occasion) {
        vm.content.gifts.filter { (budget == null || it.budget == budget) && (occasion == null || occasion in it.occasions) }
    }
    ChipRow(listOf<Budget?>(null) + Budget.entries, budget, { it?.label ?: "Any budget" }, { budget = it })
    Spacer(Modifier.height(6.dp))
    ChipRow(listOf<Occasion?>(null) + Occasion.entries, occasion, { it?.label ?: "Any occasion" }, { occasion = it })
    LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item { Text("${shown.size} ideas", style = MaterialTheme.typography.bodySmall, color = Muted) }
        if (shown.isEmpty()) {
            item { Text("No ideas for that combination. Try another filter.", color = Muted, style = MaterialTheme.typography.bodyLarge) }
        }
        items(shown, key = { it.id }) { g -> GiftCard(g, onPlan = { onPlan(draftFor(g)) }) }
    }
}

private fun draftFor(g: Gift) = PlanDraft(
    type = when {
        g.kind == "experience" && (g.title.contains("trip", true) || g.title.contains("getaway", true) ||
            g.title.contains("holiday", true) || g.title.contains("weekend", true)) -> PlanType.TRIP
        g.kind == "experience" && (g.title.contains("dinner", true) || g.title.contains("date", true) ||
            g.title.contains("brunch", true) || g.title.contains("movie", true)) -> PlanType.DATE_NIGHT
        g.kind == "experience" -> PlanType.SURPRISE
        else -> PlanType.GIFT
    },
    title = g.title,
    note = g.desc,
)

@Composable
private fun GiftCard(g: Gift, onPlan: () -> Unit) {
    SectionCard {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Pill(g.budget.label, MarigoldSoft, MaterialTheme.colorScheme.onTertiaryContainer)
            Spacer(Modifier.width(6.dp))
            Pill(
                when (g.kind) { "experience" -> "Experience"; "gesture" -> "Small gesture"; else -> "Gift" },
                RoseSoft, MaterialTheme.colorScheme.onSecondaryContainer,
            )
        }
        Spacer(Modifier.height(10.dp))
        Text(g.title, style = MaterialTheme.typography.titleLarge, color = Plum)
        Spacer(Modifier.height(4.dp))
        Text(g.desc, style = MaterialTheme.typography.bodyMedium)
        Spacer(Modifier.height(4.dp))
        Text(g.occasions.joinToString(" · ") { it.label }, style = MaterialTheme.typography.bodySmall, color = Muted)
        Spacer(Modifier.height(12.dp))
        Button(onClick = onPlan, colors = ButtonDefaults.buttonColors(containerColor = Rose)) { Text("Plan it") }
    }
}

@Composable
private fun WishlistView(vm: AppViewModel, onPlan: (PlanDraft) -> Unit) {
    val items by vm.wishlist.collectAsState()
    var text by rememberSaveable { mutableStateOf("") }
    var note by rememberSaveable { mutableStateOf("") }

    LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item {
            SectionCard(container = MaterialTheme.colorScheme.secondaryContainer) {
                Text("Things she mentioned wanting", style = MaterialTheme.typography.titleMedium, color = Plum)
                Text("Note it the moment she says it. Future you will be a hero.", style = MaterialTheme.typography.bodySmall, color = Muted)
                Spacer(Modifier.height(12.dp))
                OutlinedTextField(text, { text = it }, label = { Text("What she wants") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                Spacer(Modifier.height(8.dp))
                OutlinedTextField(note, { note = it }, label = { Text("Details: size, colour, shop (optional)") }, modifier = Modifier.fillMaxWidth())
                Spacer(Modifier.height(12.dp))
                FilledTonalButton(
                    onClick = {
                        vm.saveWish(WishlistItem(text = text.trim(), note = note.trim()))
                        text = ""; note = ""
                    },
                    enabled = text.isNotBlank(),
                ) {
                    Icon(Icons.Filled.Add, contentDescription = null)
                    Spacer(Modifier.width(4.dp))
                    Text("Add to wishlist")
                }
            }
        }
        if (items.isEmpty()) {
            item { Text("Nothing here yet.", color = Muted, style = MaterialTheme.typography.bodyLarge) }
        }
        items(items, key = { it.id }) { w ->
            SectionCard {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Checkbox(
                        checked = w.done, onCheckedChange = { vm.saveWish(w.copy(done = it)) },
                        colors = CheckboxDefaults.colors(checkedColor = SentGreen),
                    )
                    Column(Modifier.weight(1f)) {
                        Text(
                            w.text, style = MaterialTheme.typography.titleMedium,
                            textDecoration = if (w.done) TextDecoration.LineThrough else null,
                            color = if (w.done) Muted else MaterialTheme.colorScheme.onSurface,
                        )
                        if (w.note.isNotBlank()) Text(w.note, style = MaterialTheme.typography.bodySmall, color = Muted)
                    }
                    IconButton(onClick = { vm.deleteWish(w) }) { Icon(Icons.Filled.Delete, contentDescription = "Delete", tint = Muted) }
                }
                if (!w.done) {
                    TextButton(onClick = { onPlan(PlanDraft(type = PlanType.GIFT, title = "Gift: ${w.text}", note = w.note)) }) {
                        Text("Plan it")
                    }
                }
            }
        }
    }
}
