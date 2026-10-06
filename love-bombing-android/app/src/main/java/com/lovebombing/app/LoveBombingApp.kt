package com.lovebombing.app

import android.app.Application
import com.lovebombing.app.data.Repository
import com.lovebombing.app.notify.ReminderScheduler

class LoveBombingApp : Application() {
    val repository by lazy { Repository(this) }

    override fun onCreate() {
        super.onCreate()
        ReminderScheduler.createChannels(this)
    }
}
