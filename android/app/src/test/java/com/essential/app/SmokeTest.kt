package com.essential.app

import com.essential.app.ui.MainActivity
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class SmokeTest {
    @Test fun launches() {
        val a = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        assertNotNull(a)
    }
}
