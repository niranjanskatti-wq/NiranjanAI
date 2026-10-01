package com.essential.app

import android.app.AlarmManager
import android.app.Application
import android.app.NotificationManager
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import com.essential.app.core.Days
import com.essential.app.core.TimeUtil
import com.essential.app.data.Db
import com.essential.app.data.Repo
import org.junit.After
import org.junit.Before
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowAlarmManager
import org.robolectric.shadows.ShadowLooper
import java.time.ZonedDateTime

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
abstract class AppTestBase {
    lateinit var app: Application
    val repo: Repo get() = Repo.get(app)

    @Before fun baseSetUp() {
        Db.resetForTests()
        TimeUtil.zone = TimeUtil.IST
        at(2026, 10, 5, 9, 59) // Monday
        app = RuntimeEnvironment.getApplication()
        ShadowAlarmManager.setCanScheduleExactAlarms(true)
        shadowOf(app).grantPermissions(android.Manifest.permission.POST_NOTIFICATIONS)
    }

    @After fun baseTearDown() { Db.resetForTests(); TimeUtil.clock = { System.currentTimeMillis() } }

    fun at(y: Int, mo: Int, d: Int, h: Int, mi: Int) {
        val ms = ZonedDateTime.of(y, mo, d, h, mi, 0, 0, TimeUtil.IST).toInstant().toEpochMilli()
        TimeUtil.clock = { ms }
    }

    fun onboard(sample: Boolean = false) {
        val today = Days.today(repo)
        repo.addGoal("Close 3 JV real estate deals by 31 Dec", "intent", today, today.plusDays(90))
        repo.settings.set("onboarded", true)
        repo.settings.set("last_alarm_handled", TimeUtil.nowMillis())
        if (sample) com.essential.app.core.SampleData.load(app)
    }

    val alarms: ShadowAlarmManager get() = shadowOf(app.getSystemService(AlarmManager::class.java))
    val notifications get() = shadowOf(app.getSystemService(NotificationManager::class.java))

    fun idle() = ShadowLooper.idleMainLooper()

    fun View.findText(t: String, contains: Boolean = false): TextView? {
        if (this is TextView && (if (contains) text.toString().contains(t) else text.toString() == t)) return this
        if (this is ViewGroup) for (i in 0 until childCount) getChildAt(i).findText(t, contains)?.let { return it }
        return null
    }

    fun View.allText(): String {
        val sb = StringBuilder()
        fun walk(v: View) { if (v is TextView) sb.append(v.text).append('\n'); if (v is ViewGroup) for (i in 0 until v.childCount) walk(v.getChildAt(i)) }
        walk(this)
        return sb.toString()
    }
}
