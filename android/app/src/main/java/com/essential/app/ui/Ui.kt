package com.essential.app.ui

import android.animation.ValueAnimator
import android.app.Activity
import android.app.Dialog
import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.os.Build
import android.text.InputType
import android.util.TypedValue
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.SeekBar
import android.widget.Switch
import android.widget.TextView

const val MATCH = ViewGroup.LayoutParams.MATCH_PARENT
const val WRAP = ViewGroup.LayoutParams.WRAP_CONTENT

fun Context.dp(v: Number): Int = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics).toInt()
fun View.dp(v: Number): Int = context.dp(v)

fun rounded(color: Int, radius: Float, stroke: Int = 0, strokeColor: Int = 0): GradientDrawable = GradientDrawable().apply {
    setColor(color); cornerRadius = radius; if (stroke > 0) setStroke(stroke, strokeColor)
}

fun ripple(bg: Drawable?, radius: Float, rippleColor: Int = Th.alpha(Th.text, 0.12f)): RippleDrawable {
    val mask = rounded(Color.WHITE, radius)
    return RippleDrawable(ColorStateList.valueOf(rippleColor), bg, mask)
}

fun View.haptic() {
    if (!App.haptics) return
    performHapticFeedback(if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.CONFIRM else HapticFeedbackConstants.VIRTUAL_KEY)
}

fun View.click(haptic: Boolean = false, f: (View) -> Unit) { setOnClickListener { if (haptic) it.haptic(); f(it) } }

fun <T : View> ViewGroup.add(v: T, w: Int = MATCH, h: Int = WRAP, weight: Float = 0f, top: Int = 0, bottom: Int = 0, start: Int = 0, end: Int = 0, gravity: Int = -1): T {
    val lp = if (this is LinearLayout) LinearLayout.LayoutParams(w, h, weight).also { if (gravity >= 0) it.gravity = gravity }
    else if (this is FrameLayout) FrameLayout.LayoutParams(w, h).also { if (gravity >= 0) it.gravity = gravity }
    else ViewGroup.MarginLayoutParams(w, h)
    lp.setMargins(dp(start), dp(top), dp(end), dp(bottom))
    addView(v, lp)
    return v
}

fun Context.txt(s: CharSequence?, size: Float = 15f, color: Int = Th.text, font: Typeface = Fonts.regular, maxLines: Int = 0, center: Boolean = false): TextView =
    TextView(this).apply {
        text = s ?: ""; textSize = size; setTextColor(color); typeface = font
        setLineSpacing(0f, 1.15f)
        if (maxLines > 0) { this.maxLines = maxLines; ellipsize = android.text.TextUtils.TruncateAt.END }
        if (center) gravity = Gravity.CENTER
    }

fun Context.h1(s: String) = txt(s, 26f, Th.text, Fonts.semibold)
fun Context.h2(s: String) = txt(s, 19f, Th.text, Fonts.semibold)
fun Context.h3(s: String) = txt(s, 16f, Th.text, Fonts.medium)
fun Context.body(s: CharSequence?) = txt(s, 15f, Th.text)
fun Context.dimText(s: CharSequence?, size: Float = 13.5f) = txt(s, size, Th.dim)
fun Context.label(s: String) = txt(s.uppercase(), 11.5f, Th.faint, Fonts.medium).apply { letterSpacing = 0.08f }

fun Context.vbox(pad: Int = 0): LinearLayout = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; val p = dp(pad); setPadding(p, p, p, p) }
fun Context.hbox(center: Boolean = true): LinearLayout = LinearLayout(this).apply {
    orientation = LinearLayout.HORIZONTAL; if (center) gravity = Gravity.CENTER_VERTICAL
}
fun Context.space(h: Int = 8): View = View(this).apply { minimumHeight = dp(h) }
fun Context.flexSpace(): View = View(this)
fun LinearLayout.grow(): View = add(View(context), 0, 1, 1f)

fun Context.card(pad: Int = 18, color: Int = Th.surface, radius: Int = 22, onClick: ((View) -> Unit)? = null): LinearLayout = vbox(pad).apply {
    val r = dp(radius).toFloat()
    background = if (onClick != null) ripple(rounded(color, r), r) else rounded(color, r)
    if (onClick != null) click(true, onClick)
}

enum class Btn { FILLED, TONAL, OUTLINED, TEXT }

fun Context.btn(label: String, style: Btn = Btn.FILLED, icon: String? = null, color: Int = Th.primary, onClick: (View) -> Unit): TextView {
    val t = TextView(this)
    t.text = label; t.textSize = 15f; t.typeface = Fonts.medium; t.gravity = Gravity.CENTER
    t.minHeight = dp(48); t.setPadding(dp(20), dp(10), dp(20), dp(10))
    val r = dp(24).toFloat()
    val (bg, fg) = when (style) {
        Btn.FILLED -> rounded(color, r) to (if (color == Th.primary) Th.onPrimary else Th.bg)
        Btn.TONAL -> rounded(Th.alpha(color, 0.16f), r) to (if (Th.dark) color else Th.onPrimaryContainer.takeIf { color == Th.primary } ?: color)
        Btn.OUTLINED -> rounded(Color.TRANSPARENT, r, dp(1), Th.outline) to color
        Btn.TEXT -> rounded(Color.TRANSPARENT, r) to color
    }
    t.setTextColor(fg)
    t.background = ripple(bg, r)
    if (icon != null) {
        val d = Icon(icon, fg, dp(18)); d.setBounds(0, 0, dp(18), dp(18))
        t.setCompoundDrawables(d, null, null, null); t.compoundDrawablePadding = dp(8)
    }
    t.click(true, onClick)
    return t
}

fun Context.iconBtn(name: String, color: Int = Th.dim, size: Int = 44, desc: String = name, onClick: (View) -> Unit): ImageView =
    ImageView(this).apply {
        setImageDrawable(Icon(name, color, dp(22)))
        scaleType = ImageView.ScaleType.CENTER
        contentDescription = desc
        background = ripple(null, dp(size / 2).toFloat())
        minimumWidth = dp(size); minimumHeight = dp(size)
        click(true, onClick)
    }

fun Context.iconView(name: String, color: Int = Th.dim, size: Int = 20): ImageView =
    ImageView(this).apply { setImageDrawable(Icon(name, color, dp(size))); scaleType = ImageView.ScaleType.CENTER }

fun Context.chip(label: String, selected: Boolean, color: Int = Th.primary, onClick: (View) -> Unit): TextView = TextView(this).apply {
    text = label; textSize = 14f; typeface = Fonts.medium; gravity = Gravity.CENTER
    minHeight = dp(40); setPadding(dp(14), dp(8), dp(14), dp(8))
    val r = dp(12).toFloat()
    background = ripple(if (selected) rounded(Th.alpha(color, 0.22f), r, dp(1), Th.alpha(color, 0.6f)) else rounded(Color.TRANSPARENT, r, dp(1), Th.outline), r)
    setTextColor(if (selected) (if (Th.dark) color else Th.text) else Th.dim)
    click(true, onClick)
}

/** Wrapping row of children (chips). */
class Flow(ctx: Context, private val hGap: Int = ctx.dp(8), private val vGap: Int = ctx.dp(8)) : ViewGroup(ctx) {
    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val maxW = MeasureSpec.getSize(widthMeasureSpec) - paddingLeft - paddingRight
        var x = 0; var y = 0; var rowH = 0
        for (i in 0 until childCount) {
            val c = getChildAt(i)
            if (c.visibility == GONE) continue
            c.measure(MeasureSpec.makeMeasureSpec(maxW, MeasureSpec.AT_MOST), MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED))
            if (x > 0 && x + c.measuredWidth > maxW) { x = 0; y += rowH + vGap; rowH = 0 }
            x += c.measuredWidth + hGap; rowH = maxOf(rowH, c.measuredHeight)
        }
        setMeasuredDimension(MeasureSpec.getSize(widthMeasureSpec), y + rowH + paddingTop + paddingBottom)
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        val maxW = r - l - paddingLeft - paddingRight
        var x = 0; var y = 0; var rowH = 0
        for (i in 0 until childCount) {
            val c = getChildAt(i)
            if (c.visibility == GONE) continue
            if (x > 0 && x + c.measuredWidth > maxW) { x = 0; y += rowH + vGap; rowH = 0 }
            c.layout(paddingLeft + x, paddingTop + y, paddingLeft + x + c.measuredWidth, paddingTop + y + c.measuredHeight)
            x += c.measuredWidth + hGap; rowH = maxOf(rowH, c.measuredHeight)
        }
    }
}

/** Single-select chip group. */
fun Context.choice(options: List<String>, selected: String?, color: (String) -> Int = { Th.primary }, allowNone: Boolean = false, onSelect: (String?) -> Unit): Flow {
    val f = Flow(this)
    var sel = selected
    fun render() {
        f.removeAllViews()
        options.forEach { o -> f.addView(chip(o, o == sel, color(o)) {
            sel = if (allowNone && sel == o) null else o; render(); onSelect(sel)
        }) }
    }
    render()
    return f
}

fun Context.multiChoice(options: List<String>, selected: Set<String>, onChange: (Set<String>) -> Unit): Flow {
    val f = Flow(this)
    val sel = selected.toMutableSet()
    fun render() {
        f.removeAllViews()
        options.forEach { o -> f.addView(chip(o, o in sel) { if (!sel.remove(o)) sel.add(o); render(); onChange(sel.toSet()) }) }
    }
    render()
    return f
}

fun Context.field(hint: String, value: String? = "", multiline: Boolean = false, numeric: Boolean = false, decimal: Boolean = false): EditText =
    EditText(this).apply {
        setText(value ?: ""); this.hint = hint; textSize = 16f; typeface = Fonts.regular
        setTextColor(Th.text); setHintTextColor(Th.faint)
        setPadding(dp(16), dp(14), dp(16), dp(14))
        background = rounded(Th.surface2, dp(14).toFloat(), dp(1), Th.outline)
        inputType = when {
            numeric && decimal -> InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_FLAG_DECIMAL or InputType.TYPE_NUMBER_FLAG_SIGNED
            numeric -> InputType.TYPE_CLASS_NUMBER
            multiline -> InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
            else -> InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
        }
        if (multiline) { minLines = 2; gravity = Gravity.TOP or Gravity.START }
        if (Build.VERSION.SDK_INT >= 29) { textCursorDrawable = rounded(Th.primary, 2f).apply { setSize(dp(2), dp(20)) } }
    }

val EditText.value: String get() = text.toString().trim()

class ProgressView(ctx: Context, var fraction: Float, var color: Int, private val track: Int = Th.surface3) : View(ctx) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private var shown = 0f
    private val rect = RectF()
    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        ValueAnimator.ofFloat(0f, fraction.coerceIn(0f, 1f)).apply {
            duration = 600; interpolator = DecelerateInterpolator(); addUpdateListener { shown = it.animatedValue as Float; invalidate() }; start()
        }
    }
    override fun onDraw(c: Canvas) {
        val r = height / 2f
        paint.color = track; rect.set(0f, 0f, width.toFloat(), height.toFloat()); c.drawRoundRect(rect, r, r, paint)
        if (shown > 0) { paint.color = color; rect.set(0f, 0f, maxOf(height.toFloat(), width * shown), height.toFloat()); c.drawRoundRect(rect, r, r, paint) }
    }
}

fun Context.progress(fraction: Double, color: Int = Th.primary, height: Int = 8): View =
    ProgressView(this, fraction.toFloat(), color).also { it.minimumHeight = dp(height) }

fun LinearLayout.addProgress(fraction: Double, color: Int = Th.primary, height: Int = 8, top: Int = 0) =
    add(context.progress(fraction, color, height), MATCH, dp(height), top = top)

fun Context.divider(): View = View(this).apply { setBackgroundColor(Th.outline); minimumHeight = 1 }

fun Context.switchRow(title: String, desc: String?, checked: Boolean, onChange: (Boolean) -> Unit): View {
    val row = hbox().apply { setPadding(0, dp(10), 0, dp(10)) }
    val tv = vbox()
    tv.add(txt(title, 15.5f))
    if (!desc.isNullOrEmpty()) tv.add(dimText(desc), top = 2)
    row.add(tv, 0, WRAP, 1f)
    val sw = Switch(this)
    sw.isChecked = checked
    val states = arrayOf(intArrayOf(android.R.attr.state_checked), intArrayOf())
    sw.thumbTintList = ColorStateList(states, intArrayOf(Th.onPrimary, Th.dim))
    sw.trackTintList = ColorStateList(states, intArrayOf(Th.primary, Th.surface3))
    sw.setOnCheckedChangeListener { v, b -> v.haptic(); onChange(b) }
    row.add(sw, WRAP, WRAP, start = 12)
    row.click { sw.toggle() }
    return row
}

fun Context.listRow(title: String, subtitle: String? = null, icon: String? = null, iconColor: Int = Th.dim, trailing: View? = null, onClick: ((View) -> Unit)? = null): LinearLayout {
    val row = hbox().apply { setPadding(dp(4), dp(12), dp(4), dp(12)); minimumHeight = dp(56) }
    if (icon != null) row.add(iconView(icon, iconColor, 22), dp(28), dp(28), end = 14)
    val tv = vbox()
    tv.add(txt(title, 15.5f))
    if (!subtitle.isNullOrEmpty()) tv.add(dimText(subtitle), top = 2)
    row.add(tv, 0, WRAP, 1f)
    if (trailing != null) row.add(trailing, WRAP, WRAP, start = 8)
    else if (onClick != null) row.add(iconView("right", Th.faint, 18), WRAP, WRAP, start = 8)
    if (onClick != null) { row.background = ripple(null, dp(12).toFloat()); row.click(true, onClick) }
    return row
}

/** 1–5 (or 1–10) tap selector. */
fun Context.rating(value: Int?, max: Int = 5, color: Int = Th.primary, onChange: (Int) -> Unit): LinearLayout {
    val row = hbox()
    var v = value
    fun render() {
        row.removeAllViews()
        for (i in 1..max) {
            val sel = v != null && i <= v!!
            val t = txt("$i", 15f, if (sel) Th.onPrimary else Th.dim, Fonts.medium, center = true)
            val r = dp(22).toFloat()
            t.background = ripple(if (sel) rounded(color, r) else rounded(Color.TRANSPARENT, r, dp(1), Th.outline), r)
            t.click(true) { v = i; render(); onChange(i) }
            row.add(t, 0, dp(44), 1f, start = if (i == 1) 0 else (if (max > 5) 3 else 8))
        }
    }
    render()
    return row
}

fun Context.slider(value: Int, max: Int = 100, onChange: (Int) -> Unit): SeekBar = SeekBar(this).apply {
    this.max = max; progress = value
    progressTintList = ColorStateList.valueOf(Th.primary); thumbTintList = ColorStateList.valueOf(Th.primary)
    progressBackgroundTintList = ColorStateList.valueOf(Th.surface3)
    minimumHeight = dp(40)
    setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
        override fun onProgressChanged(s: SeekBar?, p: Int, fromUser: Boolean) { if (fromUser) onChange(p) }
        override fun onStartTrackingTouch(s: SeekBar?) {}
        override fun onStopTrackingTouch(s: SeekBar?) {}
    })
}

fun Context.scroll(content: View): ScrollView = ScrollView(this).apply {
    isFillViewport = true; isVerticalScrollBarEnabled = false; overScrollMode = View.OVER_SCROLL_IF_CONTENT_SCROLLS
    addView(content, FrameLayout.LayoutParams(MATCH, WRAP))
}

fun Context.badge(text: String, color: Int, icon: String? = null): TextView = TextView(this).apply {
    this.text = text; textSize = 12.5f; typeface = Fonts.medium; setTextColor(color)
    setPadding(dp(10), dp(4), dp(10), dp(4)); background = rounded(Th.alpha(color, 0.16f), dp(10).toFloat())
    if (icon != null) { val d = Icon(icon, color, dp(14)); d.setBounds(0, 0, dp(14), dp(14)); setCompoundDrawables(d, null, null, null); compoundDrawablePadding = dp(5) }
}

fun Context.dot(color: Int, size: Int = 10): View = View(this).apply { background = rounded(color, dp(size).toFloat()); minimumWidth = dp(size); minimumHeight = dp(size) }

/** Bottom sheet built on a plain Dialog (no support libraries). */
class Sheet(val act: Activity, title: String? = null, subtitle: String? = null) {
    val dialog = Dialog(act, android.R.style.Theme_DeviceDefault_Dialog_NoActionBar)
    val body: LinearLayout = act.vbox()
    private val root: LinearLayout = act.vbox()
    private var imeInset = 0

    init {
        root.background = GradientDrawable().apply {
            setColor(Th.surface); val r = act.dp(28).toFloat(); cornerRadii = floatArrayOf(r, r, r, r, 0f, 0f, 0f, 0f)
        }
        root.setPadding(act.dp(20), act.dp(10), act.dp(20), act.dp(20))
        val handle = View(act).apply { background = rounded(Th.surface3, act.dp(3).toFloat()) }
        root.add(handle, act.dp(36), act.dp(4), gravity = Gravity.CENTER_HORIZONTAL, bottom = 14)
        if (title != null) root.add(act.h2(title), bottom = if (subtitle == null) 14 else 4)
        if (subtitle != null) root.add(act.dimText(subtitle), bottom = 14)
        val sc = object : ScrollView(act) {
            override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
                val maxH = act.resources.displayMetrics.heightPixels - act.dp(150) - imeInset
                super.onMeasure(widthMeasureSpec, View.MeasureSpec.makeMeasureSpec(maxOf(act.dp(160), maxH), View.MeasureSpec.AT_MOST))
            }
        }.apply { isVerticalScrollBarEnabled = false; isFillViewport = true; addView(body, FrameLayout.LayoutParams(MATCH, WRAP)) }
        root.add(sc)
        dialog.setContentView(root)
        dialog.window?.let { w ->
            w.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
            w.setLayout(MATCH, WRAP)
            w.setGravity(Gravity.BOTTOM)
            w.decorView.setPadding(0, 0, 0, 0)
            w.setWindowAnimations(android.R.style.Animation_InputMethod)
            w.setDimAmount(0.55f)
            w.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
            if (Build.VERSION.SDK_INT >= 30) {
                w.setDecorFitsSystemWindows(false)
                root.setOnApplyWindowInsetsListener { v, ins ->
                    val ime = ins.getInsets(WindowInsets.Type.ime()).bottom
                    val nav = ins.getInsets(WindowInsets.Type.navigationBars()).bottom
                    imeInset = ime
                    v.setPadding(v.paddingLeft, v.paddingTop, v.paddingRight, act.dp(20) + maxOf(nav, ime))
                    sc.requestLayout()
                    ins
                }
            }
        }
    }

    fun add(v: View, top: Int = 0, bottom: Int = 12): Sheet { body.add(v, top = top, bottom = bottom); return this }
    fun show(): Sheet { dialog.show(); return this }
    fun dismiss() = dialog.dismiss()
    fun onDismiss(f: () -> Unit): Sheet { dialog.setOnDismissListener { f() }; return this }

    /** Standard action row: secondary on the left, primary filling. */
    fun actions(primary: String, secondary: String? = "Cancel", onSecondary: () -> Unit = { dismiss() }, onPrimary: () -> Unit): Sheet {
        val row = act.hbox()
        if (secondary != null) row.add(act.btn(secondary, Btn.TEXT, color = Th.dim) { onSecondary() }, WRAP, WRAP, end = 8)
        row.add(act.btn(primary) { onPrimary() }, 0, WRAP, 1f)
        body.add(row, top = 8)
        return this
    }
}

fun Activity.confirm(title: String, message: String, yes: String = "Yes", no: String = "Cancel", danger: Boolean = false, onYes: () -> Unit) {
    val s = Sheet(this, title)
    s.add(body(message))
    val row = hbox()
    row.add(btn(no, Btn.TEXT, color = Th.dim) { s.dismiss() }, WRAP, WRAP, end = 8)
    row.add(btn(yes, color = if (danger) Th.red else Th.primary) { s.dismiss(); onYes() }, 0, WRAP, 1f)
    s.body.add(row, top = 8)
    s.show()
}

fun Activity.info(title: String, message: String, ok: String = "OK") {
    val s = Sheet(this, title)
    s.add(body(message))
    s.body.add(btn(ok) { s.dismiss() }, top = 8)
    s.show()
}

/** Pick a time with a calm list-free picker (hours / minutes chips). */
fun Activity.pickTime(title: String, initial: Int, onPick: (Int) -> Unit) {
    android.app.TimePickerDialog(this, if (Th.dark) android.R.style.Theme_DeviceDefault_Dialog_Alert else android.R.style.Theme_DeviceDefault_Light_Dialog_Alert,
        { _, h, m -> onPick(h * 60 + m) }, (initial / 60) % 24, initial % 60, false).apply { setTitle(title) }.show()
}

fun Activity.pickDate(initial: java.time.LocalDate, onPick: (java.time.LocalDate) -> Unit) {
    android.app.DatePickerDialog(this, if (Th.dark) android.R.style.Theme_DeviceDefault_Dialog_Alert else android.R.style.Theme_DeviceDefault_Light_Dialog_Alert,
        { _, y, m, d -> onPick(java.time.LocalDate.of(y, m + 1, d)) }, initial.year, initial.monthValue - 1, initial.dayOfMonth).show()
}
