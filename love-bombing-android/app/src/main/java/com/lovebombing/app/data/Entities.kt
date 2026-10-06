package com.lovebombing.app.data

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/** Single-row table (id = 1) holding the profile and reminder preferences. */
@Entity(tableName = "settings")
data class Settings(
    @PrimaryKey val id: Int = 1,
    val onboarded: Boolean = false,
    val wifeName: String = "Shanta",
    /** Epoch day of her birthday (year is used only for display). */
    val birthday: Long? = null,
    val anniversary: Long? = null,
    val morningMinutes: Int = 8 * 60,
    val nightMinutes: Int = 22 * 60 + 30,
    val middayMinutes: Int = 13 * 60 + 30,
    val morningOn: Boolean = true,
    val nightOn: Boolean = true,
    val middayOn: Boolean = true,
    val birthdayOn: Boolean = true,
    val anniversaryOn: Boolean = true,
    val festivalsOn: Boolean = true,
    val plansOn: Boolean = true,
)

/** Every message shared from the app. */
@Entity(tableName = "sent_messages", indices = [Index("sentAt"), Index("messageId")])
data class SentMessage(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val messageId: Int?,
    val category: String,
    val text: String,
    val sentAt: Long,
)

@Entity(tableName = "favorites")
data class Favorite(
    @PrimaryKey val messageId: Int,
    val addedAt: Long,
)

@Entity(tableName = "plans", indices = [Index("dateEpochDay")])
data class Plan(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val type: String,
    val title: String,
    val dateEpochDay: Long,
    val minuteOfDay: Int,
    val note: String = "",
    val messageId: Int? = null,
    val messageText: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "wishlist")
data class WishlistItem(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val text: String,
    val note: String = "",
    val createdAt: Long = System.currentTimeMillis(),
    val done: Boolean = false,
)

enum class PlanType(val label: String) {
    MESSAGE("Send a message"),
    DATE_NIGHT("Date night"),
    SURPRISE("Surprise"),
    GIFT("Gift"),
    TRIP("Trip"),
    CUSTOM("Custom");

    companion object {
        fun of(name: String): PlanType = entries.firstOrNull { it.name == name } ?: CUSTOM
    }
}
