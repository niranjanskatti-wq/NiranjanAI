package com.essential.app

import android.app.Application
import com.essential.app.core.Hooks
import com.essential.app.core.TimeUtil
import com.essential.app.data.Repo
import com.essential.app.notify.Alarms
import com.essential.app.notify.Notifier
import com.essential.app.ui.App
import com.essential.app.ui.Fonts
import com.essential.app.ui.Th
import com.essential.app.widget.Widgets
import java.time.ZoneId

/**
 * Application entry. Wires the refresh hooks and time zone.
 *
 * Future online features (sync, login, AI voice, AI coach) plug in behind interfaces:
 * [com.essential.app.sync.SyncProvider], [com.essential.app.core.Coach], [com.essential.app.core.ActivityParser].
 * The default implementations are local-only, so the app always works fully offline.
 */
class EssentialApp : Application() {
    override fun onCreate() {
        super.onCreate()
        val s = Repo.get(this).settings
        TimeUtil.zone = if (s.bool("use_ist")) TimeUtil.IST else ZoneId.systemDefault()
        Th.dark = s.darkTheme
        App.haptics = s.bool("haptics")
        Fonts.load(this)
        Notifier.ensureChannels(this)
        Hooks.onChange = { ctx -> Widgets.updateAll(ctx) }
        Hooks.onScheduleChange = { ctx -> Alarms.schedule(ctx) }
    }
}
