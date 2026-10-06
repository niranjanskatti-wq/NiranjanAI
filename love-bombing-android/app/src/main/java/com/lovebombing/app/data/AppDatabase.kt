package com.lovebombing.app.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

@Database(
    entities = [
        Settings::class, SentMessage::class, Favorite::class, Plan::class, WishlistItem::class,
        AutoPlanSetting::class, PlanStatusRow::class,
    ],
    version = 2,
    exportSchema = false,
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun dao(): AppDao

    companion object {
        /** v2 adds automatic routines and plan statuses; existing data is kept. */
        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "CREATE TABLE IF NOT EXISTS `auto_plans` (`templateId` TEXT NOT NULL, `enabled` INTEGER NOT NULL, " +
                        "`minuteOfDay` INTEGER, `dayOfWeek` INTEGER, PRIMARY KEY(`templateId`))",
                )
                db.execSQL(
                    "CREATE TABLE IF NOT EXISTS `plan_status` (`key` TEXT NOT NULL, `status` TEXT NOT NULL, " +
                        "`epochDay` INTEGER, `minuteOfDay` INTEGER, `updatedAt` INTEGER NOT NULL, PRIMARY KEY(`key`))",
                )
            }
        }

        @Volatile private var instance: AppDatabase? = null

        fun get(context: Context): AppDatabase = instance ?: synchronized(this) {
            instance ?: Room.databaseBuilder(context.applicationContext, AppDatabase::class.java, "love_bombing.db")
                .addMigrations(MIGRATION_1_2)
                .build()
                .also { instance = it }
        }
    }
}
