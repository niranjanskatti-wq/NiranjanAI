package com.lovebombing.app.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Upsert
import kotlinx.coroutines.flow.Flow

@Dao
abstract class AppDao {
    @Query("SELECT * FROM settings WHERE id = 1")
    abstract fun settingsFlow(): Flow<Settings?>

    @Query("SELECT * FROM settings WHERE id = 1")
    abstract suspend fun settings(): Settings?

    @Upsert
    abstract suspend fun saveSettings(settings: Settings)

    @Insert
    abstract suspend fun insertSent(sent: SentMessage): Long

    @Query("SELECT * FROM sent_messages ORDER BY sentAt DESC")
    abstract fun sentFlow(): Flow<List<SentMessage>>

    @Query("SELECT * FROM sent_messages")
    abstract suspend fun allSent(): List<SentMessage>

    @Delete
    abstract suspend fun deleteSent(sent: SentMessage)

    @Query("SELECT * FROM favorites")
    abstract fun favoritesFlow(): Flow<List<Favorite>>

    @Query("SELECT * FROM favorites")
    abstract suspend fun allFavorites(): List<Favorite>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract suspend fun addFavorite(favorite: Favorite)

    @Query("DELETE FROM favorites WHERE messageId = :messageId")
    abstract suspend fun removeFavorite(messageId: Int)

    @Query("SELECT * FROM plans ORDER BY dateEpochDay, minuteOfDay")
    abstract fun plansFlow(): Flow<List<Plan>>

    @Query("SELECT * FROM plans ORDER BY dateEpochDay, minuteOfDay")
    abstract suspend fun allPlans(): List<Plan>

    @Upsert
    abstract suspend fun savePlan(plan: Plan): Long

    @Delete
    abstract suspend fun deletePlan(plan: Plan)

    @Query("SELECT * FROM wishlist ORDER BY done, createdAt DESC")
    abstract fun wishlistFlow(): Flow<List<WishlistItem>>

    @Query("SELECT * FROM wishlist")
    abstract suspend fun allWishlist(): List<WishlistItem>

    @Upsert
    abstract suspend fun saveWish(item: WishlistItem)

    @Delete
    abstract suspend fun deleteWish(item: WishlistItem)

    @Query("SELECT * FROM auto_plans")
    abstract fun autoPlansFlow(): Flow<List<AutoPlanSetting>>

    @Query("SELECT * FROM auto_plans")
    abstract suspend fun allAutoPlans(): List<AutoPlanSetting>

    @Upsert
    abstract suspend fun saveAutoPlan(setting: AutoPlanSetting)

    @Query("SELECT * FROM plan_status")
    abstract fun statusFlow(): Flow<List<PlanStatusRow>>

    @Query("SELECT * FROM plan_status")
    abstract suspend fun allStatuses(): List<PlanStatusRow>

    @Query("SELECT * FROM plan_status WHERE `key` = :key")
    abstract suspend fun status(key: String): PlanStatusRow?

    @Upsert
    abstract suspend fun saveStatus(row: PlanStatusRow)

    @Query("DELETE FROM plan_status WHERE `key` = :key")
    abstract suspend fun deleteStatus(key: String)

    @Query("DELETE FROM auto_plans")
    abstract suspend fun clearAutoPlans()

    @Query("DELETE FROM plan_status")
    abstract suspend fun clearStatuses()

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract suspend fun insertAllAutoPlans(items: List<AutoPlanSetting>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract suspend fun insertAllStatuses(items: List<PlanStatusRow>)

    @Query("DELETE FROM settings")
    abstract suspend fun clearSettings()

    @Query("DELETE FROM sent_messages")
    abstract suspend fun clearSent()

    @Query("DELETE FROM favorites")
    abstract suspend fun clearFavorites()

    @Query("DELETE FROM plans")
    abstract suspend fun clearPlans()

    @Query("DELETE FROM wishlist")
    abstract suspend fun clearWishlist()

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract suspend fun insertAllSent(items: List<SentMessage>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract suspend fun insertAllFavorites(items: List<Favorite>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract suspend fun insertAllPlans(items: List<Plan>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract suspend fun insertAllWishlist(items: List<WishlistItem>)

    /** Replaces every user table in one transaction (used by backup import). */
    @Transaction
    open suspend fun replaceAll(
        settings: Settings?,
        sent: List<SentMessage>,
        favorites: List<Favorite>,
        plans: List<Plan>,
        wishlist: List<WishlistItem>,
        autoPlans: List<AutoPlanSetting>,
        statuses: List<PlanStatusRow>,
    ) {
        clearSettings(); clearSent(); clearFavorites(); clearPlans(); clearWishlist(); clearAutoPlans(); clearStatuses()
        if (settings != null) saveSettings(settings)
        insertAllSent(sent)
        insertAllFavorites(favorites)
        insertAllPlans(plans)
        insertAllWishlist(wishlist)
        insertAllAutoPlans(autoPlans)
        insertAllStatuses(statuses)
    }
}
