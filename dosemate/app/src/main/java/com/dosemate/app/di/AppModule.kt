package com.dosemate.app.di

import android.content.Context
import androidx.room.Room
import com.dosemate.app.alarm.NotificationHelper
import com.dosemate.app.alarm.ReminderEngine
import com.dosemate.app.data.repo.LogRepository
import com.dosemate.app.data.repo.MedicineRepository
import com.dosemate.app.data.db.ActiveAlertDao
import com.dosemate.app.data.db.AppDatabase
import com.dosemate.app.data.db.DoseLogDao
import com.dosemate.app.data.db.JournalDao
import com.dosemate.app.data.db.MedicineDao
import com.dosemate.app.data.repo.SettingsRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import javax.inject.Qualifier
import javax.inject.Singleton

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class AppScope

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun database(@ApplicationContext context: Context): AppDatabase =
        Room.databaseBuilder(context, AppDatabase::class.java, "dosemate.db").build()

    @Provides fun medicineDao(db: AppDatabase): MedicineDao = db.medicineDao()
    @Provides fun logDao(db: AppDatabase): DoseLogDao = db.doseLogDao()
    @Provides fun alertDao(db: AppDatabase): ActiveAlertDao = db.activeAlertDao()
    @Provides fun journalDao(db: AppDatabase): JournalDao = db.journalDao()

    @Provides
    @Singleton
    @AppScope
    fun appScope(): CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
}

/** Access to singletons from receivers, services and widgets. */
@EntryPoint
@InstallIn(SingletonComponent::class)
interface AppEntryPoint {
    fun engine(): ReminderEngine
    fun settings(): SettingsRepository
    fun notifications(): NotificationHelper
    fun medicines(): MedicineRepository
    fun logs(): LogRepository
    @AppScope fun scope(): CoroutineScope
}

fun Context.entryPoint(): AppEntryPoint =
    EntryPointAccessors.fromApplication(applicationContext, AppEntryPoint::class.java)
