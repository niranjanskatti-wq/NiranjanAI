package com.essential.app.ui.screens

import android.view.View
import com.essential.app.core.Classifier
import com.essential.app.core.Days
import com.essential.app.core.Hooks
import com.essential.app.core.Logging
import com.essential.app.core.TimeUtil
import com.essential.app.data.Cat
import com.essential.app.data.HourLog
import com.essential.app.data.Plan
import com.essential.app.data.Source
import com.essential.app.data.Type
import com.essential.app.notify.Notifier
import com.essential.app.ui.*
import java.time.LocalDate

/** The full log screen for one hour: 2–3 taps for a normal entry. */
object LogHourSheet {
    fun open(a: MainActivity, date: LocalDate, hour: Int, onSaved: (() -> Unit)? = null) {
        val repo = a.repo
        val day = Days.resolve(repo, date)
        val planned = day.plannedFor(hour)
        val existing = repo.logFor(date, hour)
        val rules = repo.rules()
        val ventures = repo.ventures()

        var activity = existing?.activity ?: ""
        var type: String? = existing?.type
        var focus = existing?.focus
        var energy = existing?.energy
        var followed = existing?.followedPlan
        var reason = existing?.offPlanReason
        var category = existing?.category ?: planned?.category
        var ventureId = existing?.ventureId ?: planned?.ventureId
        var catTouched = existing != null
        var source = existing?.source ?: Source.APP

        val sh = Sheet(a, TimeUtil.fmtHourRange(hour), TimeUtil.fmtDay(date) + (planned?.let { " · Planned: ${it.title}" } ?: ""))

        // Same as last hour
        val prev = repo.lastLogBefore(date, hour)
        if (existing == null && prev != null) {
            sh.add(a.btn("Same as last hour: ${prev.activity}", Btn.TONAL, "repeat") {
                Logging.sameAsLast(a, Logging.Slot(date, hour), Source.APP)
                Notifier.cancelCheckin(a, hour); it.haptic(); sh.dismiss(); a.toast("Logged: ${prev.activity}"); onSaved?.invoke(); a.refresh()
            })
        }

        // Activity
        sh.add(a.label("Activity"), top = 4, bottom = 8)
        val f = a.field("What did you do?", activity)
        val status = a.dimText("").apply { visibility = View.GONE }
        lateinit var catFlow: Flow
        lateinit var ventFlow: Flow
        lateinit var typeBox: android.widget.LinearLayout
        fun applyClassifier(text: String) {
            if (catTouched) return
            val m = Classifier.parse(text, rules) ?: return
            m.category?.let { category = it }
            m.ventureId?.let { ventureId = it }
            if (m.type != null && type == null) type = m.type
            renderCats(a, catFlow, ventFlow, { category }, { category = it; catTouched = true }, { ventureId }, { ventureId = it; catTouched = true }, ventures)
            renderType(a, typeBox, { type }, { type = it })
        }
        f.addTextChangedListener(Watch { activity = it; applyClassifier(it) })
        sh.add(f, bottom = 8)
        val suggestions = (listOfNotNull(planned?.title) + repo.recentActivities(6)).distinct().take(7)
        val sug = Flow(a)
        suggestions.forEach { s -> sug.addView(a.chip(s, false) { f.setText(s); f.setSelection(s.length) }) }
        sh.add(sug, bottom = 10)
        val voice = VoiceInput(a, { text, final ->
            f.setText(text); f.setSelection(text.length)
            if (final) { source = Source.VOICE; applyClassifier(text); status.text = "Heard you. Check and save."; status.visibility = View.VISIBLE }
        }) { msg -> if (msg == null) status.visibility = View.GONE else { status.text = msg; status.visibility = View.VISIBLE } }
        val vr = a.hbox()
        vr.add(VoiceInput.holdButton(a, voice, status), WRAP, WRAP)
        vr.add(a.txt(if (voice.lang().startsWith("kn")) "  ಕನ್ನಡ" else "  English", 13f, Th.faint), WRAP, WRAP)
        sh.add(vr, bottom = 4)
        sh.add(status, bottom = 12)
        sh.onDismiss { voice.destroy() }

        // Type
        sh.add(a.label("Type"), top = 6, bottom = 8)
        typeBox = a.vbox()
        renderType(a, typeBox, { type }, { type = it })
        sh.add(typeBox, bottom = 12)

        // Focus & energy
        sh.add(a.label("Focus"), bottom = 6)
        sh.add(a.rating(focus) { focus = it }, bottom = 10)
        sh.add(a.label("Energy"), bottom = 6)
        sh.add(a.rating(energy, color = Th.necessary) { energy = it }, bottom = 12)

        // Followed plan
        sh.add(a.label("Followed plan?"), bottom = 6)
        val reasonBox = a.vbox()
        fun renderReasons() {
            reasonBox.removeAllViews()
            if (followed == Plan.PARTLY || followed == Plan.NO) {
                reasonBox.add(a.dimText("What pulled you off plan?"), bottom = 6)
                reasonBox.add(a.choice(Plan.REASONS, reason, allowNone = true) { reason = it })
            }
        }
        sh.add(a.choice(Plan.ALL, followed, { Th.plan(it) }, allowNone = true) { followed = it; renderReasons() }, bottom = 8)
        renderReasons()
        sh.add(reasonBox, bottom = 12)

        // Category & venture
        sh.add(a.label("Category"), bottom = 6)
        catFlow = Flow(a); ventFlow = Flow(a)
        renderCats(a, catFlow, ventFlow, { category }, { category = it; catTouched = true }, { ventureId }, { ventureId = it; catTouched = true }, ventures)
        sh.add(catFlow, bottom = 10)
        sh.add(a.label("Venture"), bottom = 6)
        sh.add(ventFlow, bottom = 12)

        // Money (collapsed)
        val moneyBox = a.vbox().apply { visibility = if (existing?.money != null) View.VISIBLE else View.GONE }
        val amt = a.field("₹ amount", existing?.money?.let { if (it == Math.floor(it)) it.toLong().toString() else it.toString() }, numeric = true, decimal = true)
        val note = a.field("Deal note (optional)", existing?.moneyNote)
        moneyBox.add(amt, bottom = 8); moneyBox.add(note)
        val toggle = a.btn(if (moneyBox.visibility == View.VISIBLE) "₹ Money" else "+ ₹ amount / deal note", Btn.TEXT, color = Th.dim) { moneyBox.visibility = View.VISIBLE }
        sh.add(toggle, bottom = 4)
        sh.add(moneyBox, bottom = 8)

        fun save() {
            val act = f.value.ifBlank { planned?.title ?: "" }
            if (act.isBlank()) { status.text = "Add a few words about this hour."; status.visibility = View.VISIBLE; return }
            val t = type ?: Cat.defaultType(category)
            val log = HourLog(existing?.id ?: 0, date, hour, existing?.minutes ?: 60, act, category, ventureId, t, focus, energy, followed,
                if (followed == Plan.YES) null else reason, amt.value.toDoubleOrNull(), note.value.ifBlank { null }, source, TimeUtil.nowMillis())
            repo.saveLog(log)
            Notifier.cancelCheckin(a, hour)
            Hooks.afterChange(a)
            a.root.haptic()
            sh.dismiss()
            a.toast("Logged ${TimeUtil.fmtTime(hour * 60)} · $t")
            onSaved?.invoke()
            a.refresh()
        }

        if (existing != null) sh.actions("Save", "Delete", onSecondary = {
            repo.deleteLog(existing.id); Hooks.afterChange(a); sh.dismiss(); a.toast("Entry deleted"); onSaved?.invoke(); a.refresh()
        }) { save() } else sh.actions("Save") { save() }
        sh.show()
    }

    private fun renderType(a: MainActivity, box: android.widget.LinearLayout, get: () -> String?, set: (String) -> Unit) {
        box.removeAllViews()
        val desc = mapOf(Type.ESSENTIAL to "Moved my Essential Intent", Type.NECESSARY to "Had to be done", Type.TRIVIAL to "Could have been skipped")
        val row = a.hbox()
        Type.ALL.forEachIndexed { i, t ->
            val sel = get() == t
            val col = Th.type(t)
            val c = a.vbox().apply { setPadding(a.dp(10), a.dp(10), a.dp(10), a.dp(10)) }
            val r = a.dp(14).toFloat()
            c.background = ripple(if (sel) rounded(Th.alpha(col, 0.2f), r, a.dp(1), col) else rounded(0, r, a.dp(1), Th.outline), r)
            c.add(a.txt(t, 14.5f, if (sel) Th.text else Th.dim, Fonts.semibold))
            c.add(a.txt(desc[t]!!, 11.5f, Th.faint), top = 2)
            c.click(true) { set(t); renderType(a, box, get, set) }
            row.add(c, 0, MATCH, 1f, start = if (i == 0) 0 else 6)
        }
        box.add(row)
    }

    private fun renderCats(a: MainActivity, catFlow: Flow, ventFlow: Flow, getCat: () -> String?, setCat: (String) -> Unit,
                           getV: () -> Long?, setV: (Long?) -> Unit, ventures: List<com.essential.app.data.Venture>) {
        catFlow.removeAllViews()
        Cat.ALL.filter { it != Cat.SLEEP }.forEach { c ->
            catFlow.addView(a.chip(c, getCat() == c) { setCat(c); renderCats(a, catFlow, ventFlow, getCat, setCat, getV, setV, ventures) })
        }
        ventFlow.removeAllViews()
        ventures.forEach { v ->
            ventFlow.addView(a.chip(v.name, getV() == v.id, v.color) {
                setV(if (getV() == v.id) null else v.id); renderCats(a, catFlow, ventFlow, getCat, setCat, getV, setV, ventures)
            })
        }
    }
}
