package com.essential.app.sync

import android.content.Context

/**
 * Extension point for a future, optional cloud sync. Every table carries `updated_at`
 * so a provider can push/pull changed rows. The shipped implementation does nothing:
 * the app never touches the network (it has no INTERNET permission).
 */
interface SyncProvider {
    val name: String
    fun isEnabled(ctx: Context): Boolean
    fun sync(ctx: Context, sinceMillis: Long)
}

object LocalOnly : SyncProvider {
    override val name = "On this phone only"
    override fun isEnabled(ctx: Context) = false
    override fun sync(ctx: Context, sinceMillis: Long) {}
}
