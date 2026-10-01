package com.essential.app.ui

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.window.OnBackInvokedCallback
import android.window.OnBackInvokedDispatcher
import com.essential.app.core.Days
import com.essential.app.core.Focus
import com.essential.app.core.Logging
import com.essential.app.data.Repo
import com.essential.app.notify.Alarms
import com.essential.app.notify.Notifier
import com.essential.app.ui.screens.*
import java.time.LocalDate

object App { var haptics = true }

/** Base for every screen. Screens rebuild their view on refresh (data is local and small). */
abstract class Screen(val a: MainActivity) {
    open val title: String? = null
    abstract fun content(): View
    open fun actions(): List<View> = emptyList()
    open fun onShow() {}
    open fun onHide() {}
    val repo: Repo get() = Repo.get(a)
    val today: LocalDate get() = Days.today(repo)

    fun build(): View {
        val t = title ?: return content()
        val box = a.vbox()
        val bar = a.hbox().apply { setPadding(a.dp(4), a.dp(6), a.dp(8), a.dp(6)); minimumHeight = a.dp(60) }
        bar.add(a.iconBtn("back", Th.text, desc = "Back") { a.back() }, a.dp(48), a.dp(48))
        bar.add(a.txt(t, 20f, Th.text, Fonts.semibold, maxLines = 1), 0, WRAP, 1f, start = 4)
        actions().forEach { bar.add(it, WRAP, WRAP) }
        box.add(bar)
        box.add(content(), MATCH, 0, 1f)
        return box
    }

    /** Standard padded, scrolling page. */
    fun page(build: LinearLayout.() -> Unit): View {
        val v = a.vbox().apply { setPadding(a.dp(16), a.dp(if (title == null) 12 else 0), a.dp(16), a.dp(32)) }
        v.build()
        return a.scroll(v)
    }
}

class MainActivity : Activity() {
    lateinit var root: FrameLayout
    private lateinit var column: LinearLayout
    private lateinit var content: FrameLayout
    private lateinit var nav: LinearLayout
    private val tabs = arrayOfNulls<Screen>(5)
    private var tab = 0
    private val stack = ArrayList<Screen>()
    private var current: Screen? = null
    private var backCb: Any? = null
    private val results = HashMap<Int, (Int, Intent?) -> Unit>()
    private val permResults = HashMap<Int, (Boolean) -> Unit>()
    private var nextRc = 100
    val repo: Repo get() = Repo.get(this)

    override fun onCreate(savedInstanceState: Bundle?) {
        Th.dark = repo.settings.darkTheme
        setTheme(if (Th.dark) com.essential.app.R.style.Theme_Essential else com.essential.app.R.style.Theme_Essential_Light)
        super.onCreate(savedInstanceState)
        Fonts.load(this)
        setupWindow()
        buildShell()
        if (!repo.settings.bool("onboarded")) showOnboarding() else { selectTab(0); handleRoute(intent) }
    }

    private fun setupWindow() {
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        window.decorView.setBackgroundColor(Th.bg)
        if (Build.VERSION.SDK_INT >= 30) {
            window.setDecorFitsSystemWindows(false)
            val light = if (Th.dark) 0 else (WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS)
            window.insetsController?.setSystemBarsAppearance(light, WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS)
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or (if (Th.dark) 0 else View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR or View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR)
        }
        if (Build.VERSION.SDK_INT >= 29) window.isNavigationBarContrastEnforced = false
    }

    private fun buildShell() {
        root = FrameLayout(this).apply { setBackgroundColor(Th.bg) }
        column = vbox()
        content = FrameLayout(this)
        column.add(content, MATCH, 0, 1f)
        nav = hbox().apply { setBackgroundColor(Th.surface); gravity = Gravity.CENTER }
        column.add(nav, MATCH, WRAP)
        root.add(column, MATCH, MATCH)
        setContentView(root)
        root.setOnApplyWindowInsetsListener { _, ins ->
            val top: Int; val bottom: Int; val left: Int; val right: Int; var ime = 0
            if (Build.VERSION.SDK_INT >= 30) {
                val s = ins.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
                top = s.top; bottom = s.bottom; left = s.left; right = s.right
                ime = ins.getInsets(WindowInsets.Type.ime()).bottom
            } else {
                @Suppress("DEPRECATION") run { top = ins.systemWindowInsetTop; bottom = ins.systemWindowInsetBottom; left = ins.systemWindowInsetLeft; right = ins.systemWindowInsetRight }
            }
            column.setPadding(left, top, right, 0)
            nav.setPadding(0, dp(6), 0, bottom + dp(6))
            val navH = if (nav.visibility == View.VISIBLE) nav.height else bottom
            content.setPadding(0, 0, 0, if (ime > 0) maxOf(0, ime - navH) else (if (nav.visibility == View.VISIBLE) 0 else bottom))
            ins
        }
        renderNav()
    }

    private val tabDefs = listOf("Now" to "now", "Log" to "log", "Insights" to "insights", "Tools" to "tools", "Settings" to "settings")

    private fun renderNav() {
        nav.removeAllViews()
        tabDefs.forEachIndexed { i, (label, icon) ->
            val sel = i == tab && stack.isEmpty()
            val item = vbox().apply { gravity = Gravity.CENTER; setPadding(0, dp(4), 0, dp(4)) }
            val pill = FrameLayout(this).apply { background = if (i == tab) rounded(Th.primaryContainer, dp(16).toFloat()) else null }
            pill.add(iconView(icon, if (i == tab) Th.onPrimaryContainer.takeIf { !Th.dark } ?: Th.primary else Th.dim, 22), WRAP, WRAP, gravity = Gravity.CENTER)
            item.add(pill, dp(60), dp(32), gravity = Gravity.CENTER_HORIZONTAL)
            item.add(txt(label, 12f, if (i == tab) Th.text else Th.dim, if (i == tab) Fonts.semibold else Fonts.medium, center = true), WRAP, WRAP, top = 4, gravity = Gravity.CENTER_HORIZONTAL)
            item.background = ripple(null, dp(20).toFloat())
            item.click(true) { if (sel) refresh() else { stack.clear(); selectTab(i) } }
            item.contentDescription = label
            nav.add(item, 0, WRAP, 1f)
        }
    }

    fun selectTab(i: Int) {
        tab = i
        val s = tabs[i] ?: when (i) {
            0 -> HomeScreen(this); 1 -> LogScreen(this); 2 -> InsightsScreen(this); 3 -> ToolsScreen(this); else -> SettingsScreen(this)
        }.also { tabs[i] = it }
        stack.clear()
        display(s)
        renderNav()
    }

    private fun display(s: Screen) {
        current?.onHide()
        current = s
        content.removeAllViews()
        val v = s.build()
        v.alpha = 0f
        content.add(v, MATCH, MATCH)
        v.animate().alpha(1f).setDuration(160).start()
        s.onShow()
        updateBack()
    }

    fun push(s: Screen) { stack.add(s); nav.visibility = View.VISIBLE; display(s); renderNav() }

    fun back() {
        if (stack.isNotEmpty()) {
            stack.removeAt(stack.size - 1)
            display(stack.lastOrNull() ?: tabs[tab]!!)
            renderNav()
        } else if (tab != 0 && current !is OnboardingScreen) selectTab(0)
        else finish()
    }

    /** Rebuild the visible screen, keeping its scroll position. */
    fun refresh() {
        val s = current ?: return
        val oldScroll = findScroll(content)?.scrollY ?: 0
        content.removeAllViews()
        val v = s.build()
        content.add(v, MATCH, MATCH)
        findScroll(v)?.post { findScroll(v)?.scrollTo(0, oldScroll) }
        s.onShow()
    }

    private fun findScroll(v: View): ScrollView? {
        if (v is ScrollView) return v
        if (v is ViewGroup) for (i in 0 until v.childCount) findScroll(v.getChildAt(i))?.let { return it }
        return null
    }

    fun showOnboarding() {
        nav.visibility = View.GONE
        display(OnboardingScreen(this))
    }

    fun finishOnboarding() {
        nav.visibility = View.VISIBLE
        root.requestApplyInsets()
        Alarms.schedule(this)
        selectTab(0)
    }

    private fun updateBack() {
        if (Build.VERSION.SDK_INT < 33) return
        val need = stack.isNotEmpty() || (tab != 0 && current !is OnboardingScreen)
        val d = onBackInvokedDispatcher
        if (need && backCb == null) {
            val cb = OnBackInvokedCallback { back() }
            d.registerOnBackInvokedCallback(OnBackInvokedDispatcher.PRIORITY_DEFAULT, cb); backCb = cb
        } else if (!need && backCb != null) {
            d.unregisterOnBackInvokedCallback(backCb as OnBackInvokedCallback); backCb = null
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        if (stack.isNotEmpty() || tab != 0) back() else @Suppress("DEPRECATION") super.onBackPressed()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (repo.settings.bool("onboarded")) handleRoute(intent)
    }

    override fun onResume() {
        super.onResume()
        repo.closeFinishedSprints(Days.today(repo))
        if (current != null && current !is OnboardingScreen) refresh()
    }

    /** Deep links from notifications, widgets, tiles and app shortcuts. */
    fun handleRoute(i: Intent?) {
        val route = i?.getStringExtra("route") ?: i?.action?.takeIf { it.startsWith("com.essential.app.shortcut.") }?.substringAfterLast('.') ?: return
        i?.removeExtra("route")
        when (route) {
            "log" -> {
                val d = i?.getStringExtra("date")?.let { LocalDate.parse(it) }
                val h = i?.getIntExtra("hour", -1) ?: -1
                selectTab(0)
                if (d != null && h >= 0) { Notifier.cancelCheckin(this, h); LogHourSheet.open(this, d, h) }
                else { val s = Logging.targetSlot(repo); LogHourSheet.open(this, s.date, s.hour) }
            }
            "log_hour" -> { selectTab(0); val s = Logging.targetSlot(repo); LogHourSheet.open(this, s.date, s.hour) }
            "missed" -> { selectTab(1); push(MissedHoursScreen(this)) }
            "focus" -> { selectTab(0); if (Focus.isActive(this)) startActivity(Intent(this, FocusActivity::class.java)) else FocusSheet.open(this) }
            "new_idea" -> { selectTab(3); push(OpportunityScreen(this)); OpportunityScreen.newIdea(this) }
            "review" -> { selectTab(0); ReviewSheet.open(this, Days.today(repo)) }
            "sleep" -> { selectTab(0); SleepSheet.open(this, Days.today(repo)) }
            "backup" -> { selectTab(4); push(BackupScreen(this)) }
            "obstacle" -> { selectTab(3); push(ObstacleScreen(this)) }
            "report" -> { selectTab(2); push(WeeklyReportScreen(this)) }
            "uncommit" -> { selectTab(3); push(UncommitScreen(this)) }
            "sprint" -> { selectTab(3); push(SprintScreen(this)) }
            "settings" -> selectTab(4)
            "distracted" -> { selectTab(0); HomeScreen.distracted(this) }
            else -> selectTab(0)
        }
    }

    // ------------------------------------------------------------ results & permissions
    fun startForResult(intent: Intent, cb: (Int, Intent?) -> Unit) {
        val rc = nextRc++
        results[rc] = cb
        try { @Suppress("DEPRECATION") startActivityForResult(intent, rc) } catch (e: Exception) { results.remove(rc); cb(RESULT_CANCELED, null) }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION") super.onActivityResult(requestCode, resultCode, data)
        results.remove(requestCode)?.invoke(resultCode, data)
    }

    fun requestPerm(perm: String, cb: (Boolean) -> Unit) {
        if (checkSelfPermission(perm) == PackageManager.PERMISSION_GRANTED) { cb(true); return }
        val rc = nextRc++
        permResults[rc] = cb
        requestPermissions(arrayOf(perm), rc)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        permResults.remove(requestCode)?.invoke(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
    }

    /** Brief bottom message with optional actions (e.g. distraction reasons). */
    fun snack(text: String, actions: List<Pair<String, () -> Unit>> = emptyList(), millis: Long = 4000) {
        root.findViewWithTag<View>("snack")?.let { root.removeView(it) }
        val box = vbox(14).apply { tag = "snack"; background = rounded(Th.surface3, dp(16).toFloat()); elevation = dp(6).toFloat() }
        box.add(txt(text, 14.5f, Th.text))
        if (actions.isNotEmpty()) {
            val f = Flow(this)
            actions.forEach { (l, f2) -> f.addView(chip(l, false) { f2(); root.removeView(box) }) }
            box.add(f, top = 10)
        }
        val lp = FrameLayout.LayoutParams(MATCH, WRAP, Gravity.BOTTOM)
        lp.setMargins(dp(12), 0, dp(12), nav.height + dp(16) + (if (nav.visibility == View.VISIBLE) 0 else dp(24)))
        root.addView(box, lp)
        box.translationY = dp(40).toFloat(); box.alpha = 0f
        box.animate().translationY(0f).alpha(1f).setDuration(180).start()
        box.postDelayed({ if (box.parent != null) box.animate().alpha(0f).setDuration(200).withEndAction { root.removeView(box) }.start() }, millis)
    }

    fun toast(text: String) = snack(text, emptyList(), 2500)

    fun shareUris(uris: List<android.net.Uri>, mime: String, subject: String) {
        val i = if (uris.size == 1) Intent(Intent.ACTION_SEND).putExtra(Intent.EXTRA_STREAM, uris[0])
        else Intent(Intent.ACTION_SEND_MULTIPLE).putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(uris))
        i.type = mime
        i.putExtra(Intent.EXTRA_SUBJECT, subject)
        i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        val clip = android.content.ClipData.newRawUri(subject, uris[0])
        uris.drop(1).forEach { clip.addItem(android.content.ClipData.Item(it)) }
        i.clipData = clip
        startActivity(Intent.createChooser(i, subject))
    }

    fun shareText(text: String, subject: String = "Essential") {
        val i = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text).putExtra(Intent.EXTRA_SUBJECT, subject)
        startActivity(Intent.createChooser(i, subject))
    }

    fun copy(text: String) {
        val cm = getSystemService(android.content.ClipboardManager::class.java)
        cm.setPrimaryClip(android.content.ClipData.newPlainText("Essential", text))
        if (Build.VERSION.SDK_INT < 33) toast("Copied")
    }

}
