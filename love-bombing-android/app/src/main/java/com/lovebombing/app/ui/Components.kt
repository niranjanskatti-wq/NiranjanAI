package com.lovebombing.app.ui

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.lovebombing.app.R
import java.time.LocalDate
import java.time.format.DateTimeFormatter

val dayFormat: DateTimeFormatter = DateTimeFormatter.ofPattern("EEE, d MMM yyyy")
val shortDayFormat: DateTimeFormatter = DateTimeFormatter.ofPattern("d MMM")
val longDayFormat: DateTimeFormatter = DateTimeFormatter.ofPattern("EEEE, d MMMM")
val timeFormat: DateTimeFormatter = DateTimeFormatter.ofPattern("h:mm a")

@Composable
fun SectionCard(
    modifier: Modifier = Modifier,
    container: Color = MaterialTheme.colorScheme.surface,
    content: @Composable ColumnScope.() -> Unit,
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.large,
        colors = CardDefaults.cardColors(containerColor = container),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
    ) {
        Column(Modifier.padding(20.dp), content = content)
    }
}

@Composable
fun Eyebrow(text: String, color: Color = Rose) {
    Text(text.uppercase(), style = MaterialTheme.typography.labelMedium, color = color, fontWeight = FontWeight.Bold)
}

@Composable
fun Pill(text: String, container: Color, content: Color) {
    Box(
        Modifier.clip(RoundedCornerShape(50)).background(container).padding(horizontal = 10.dp, vertical = 4.dp),
    ) {
        Text(text, style = MaterialTheme.typography.labelSmall, color = content)
    }
}

@Composable
fun Dot(color: Color, size: Int = 6) {
    Box(Modifier.size(size.dp).clip(CircleShape).background(color))
}

/** Horizontally scrolling single-select chips. */
@Composable
fun <T> ChipRow(
    items: List<T>,
    selected: T?,
    label: (T) -> String,
    onSelect: (T) -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        items.forEach { item ->
            FilterChip(
                selected = item == selected,
                onClick = { onSelect(item) },
                label = { Text(label(item), style = MaterialTheme.typography.labelLarge) },
                shape = RoundedCornerShape(50),
                colors = FilterChipDefaults.filterChipColors(
                    selectedContainerColor = Plum,
                    selectedLabelColor = Color.White,
                ),
            )
        }
    }
}

/**
 * A message with its actions. [onWhatsApp] opens WhatsApp, [onCopy] copies,
 * [onFavorite] toggles the heart. [extra] lets callers add e.g. a "Next" button.
 */
@Composable
fun MessageCard(
    text: String,
    category: String?,
    isFavorite: Boolean,
    isSent: Boolean,
    onWhatsApp: () -> Unit,
    onCopy: () -> Unit,
    onFavorite: (() -> Unit)?,
    modifier: Modifier = Modifier,
    extra: (@Composable () -> Unit)? = null,
) {
    SectionCard(modifier) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (category != null) Pill(category, MaterialTheme.colorScheme.primaryContainer, Plum)
            if (isSent) {
                Spacer(Modifier.width(8.dp))
                Icon(Icons.Filled.CheckCircle, contentDescription = "Already sent", tint = SentGreen, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(4.dp))
                Text("Sent", style = MaterialTheme.typography.labelSmall, color = SentGreen)
            }
            Spacer(Modifier.weight(1f))
            if (onFavorite != null) {
                IconButton(onClick = onFavorite) {
                    Icon(
                        if (isFavorite) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                        contentDescription = if (isFavorite) "Remove from favourites" else "Add to favourites",
                        tint = Rose,
                    )
                }
            }
        }
        Spacer(Modifier.height(8.dp))
        Text(text, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurface)
        Spacer(Modifier.height(16.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
            Button(
                onClick = onWhatsApp,
                colors = ButtonDefaults.buttonColors(containerColor = Rose),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 10.dp),
            ) {
                Icon(painterResource(R.drawable.ic_chat), contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text("WhatsApp")
            }
            OutlinedButton(onClick = onCopy, contentPadding = PaddingValues(horizontal = 14.dp, vertical = 10.dp)) {
                Icon(painterResource(R.drawable.ic_copy), contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text("Copy")
            }
            extra?.invoke()
        }
    }
}

fun pickDate(context: Context, initial: LocalDate?, onPicked: (LocalDate) -> Unit) {
    val d = initial ?: LocalDate.now()
    DatePickerDialog(context, { _, y, m, day -> onPicked(LocalDate.of(y, m + 1, day)) }, d.year, d.monthValue - 1, d.dayOfMonth).show()
}

fun pickTime(context: Context, minutes: Int, onPicked: (Int) -> Unit) {
    TimePickerDialog(context, { _, h, m -> onPicked(h * 60 + m) }, minutes / 60, minutes % 60, false).show()
}
