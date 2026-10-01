package com.essential.app.ui

import android.content.Context
import android.graphics.Canvas
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.view.View
import kotlin.math.ceil
import kotlin.math.max

/** Small bundled chart library: bars, stacked bars, lines, dual bars and a calendar heatmap. */
abstract class ChartView(ctx: Context, heightDp: Int) : View(ctx) {
    protected val fill = Paint(Paint.ANTI_ALIAS_FLAG)
    protected val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE; strokeCap = Paint.Cap.ROUND; strokeJoin = Paint.Join.ROUND }
    protected val label = Paint(Paint.ANTI_ALIAS_FLAG).apply { typeface = Fonts.regular; textSize = ctx.dp(10.5f).toFloat(); color = Th.faint }
    protected val padL get() = dp(30).toFloat()
    protected val padB get() = dp(20).toFloat()
    protected val padT get() = dp(8).toFloat()
    protected val padR get() = dp(6).toFloat()
    private val h = ctx.dp(heightDp)

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) =
        setMeasuredDimension(MeasureSpec.getSize(widthMeasureSpec), h)

    protected fun niceMax(v: Double): Double {
        if (v <= 0) return 1.0
        val steps = listOf(1.0, 2.0, 2.5, 5.0, 10.0)
        var mag = 1.0
        while (mag * 10 < v) mag *= 10
        return steps.map { it * mag }.first { it >= v }
    }

    protected fun yAxis(c: Canvas, maxV: Double, fmt: (Double) -> String) {
        val chartH = height - padB - padT
        stroke.color = Th.outline; stroke.strokeWidth = 1f; stroke.pathEffect = null
        for (i in 0..2) {
            val y = padT + chartH * (1 - i / 2f)
            c.drawLine(padL, y, width - padR, y, stroke)
            label.textAlign = Paint.Align.RIGHT
            c.drawText(fmt(maxV * i / 2), padL - dp(5), y + dp(3.5f), label)
        }
    }

    protected fun xLabels(c: Canvas, labels: List<String>, slotW: Float) {
        if (labels.isEmpty()) return
        label.textAlign = Paint.Align.CENTER
        val every = max(1, ceil(labels.size / (width / dp(34).toFloat())).toInt())
        labels.forEachIndexed { i, s -> if (i % every == 0 || i == labels.size - 1) c.drawText(s, padL + slotW * (i + 0.5f), height - dp(5).toFloat(), label) }
    }

    protected fun targetLine(c: Canvas, target: Double, maxV: Double) {
        val chartH = height - padB - padT
        val y = padT + chartH * (1 - (target / maxV)).toFloat()
        stroke.color = Th.alpha(Th.text, 0.5f); stroke.strokeWidth = dp(1.2f).toFloat()
        stroke.pathEffect = DashPathEffect(floatArrayOf(dp(4).toFloat(), dp(4).toFloat()), 0f)
        c.drawLine(padL, y, width - padR, y, stroke)
        stroke.pathEffect = null
    }
}

class BarChart(ctx: Context, val values: List<Double>, val labels: List<String>, val colors: List<Int>? = null,
               val target: Double? = null, heightDp: Int = 150, val fmt: (Double) -> String = { com.essential.app.core.TimeUtil.fmtHours(it) }) : ChartView(ctx, heightDp) {
    override fun onDraw(c: Canvas) {
        if (values.isEmpty()) return
        val maxV = niceMax(max(values.maxOrNull() ?: 0.0, target ?: 0.0) * 1.05)
        yAxis(c, maxV, fmt)
        val chartH = height - padB - padT
        val slotW = (width - padL - padR) / values.size
        val bw = (slotW * 0.62f).coerceAtMost(dp(26).toFloat())
        values.forEachIndexed { i, v ->
            val x = padL + slotW * (i + 0.5f)
            val top = padT + chartH * (1 - (v / maxV)).toFloat()
            fill.color = colors?.getOrNull(i) ?: Th.primary
            if (v > 0) c.drawRoundRect(RectF(x - bw / 2, top, x + bw / 2, padT + chartH), dp(4).toFloat(), dp(4).toFloat(), fill)
        }
        target?.let { targetLine(c, it, maxV) }
        xLabels(c, labels, slotW)
    }
}

class StackedBarChart(ctx: Context, val stacks: List<List<Pair<Double, Int>>>, val labels: List<String>, heightDp: Int = 150) : ChartView(ctx, heightDp) {
    override fun onDraw(c: Canvas) {
        if (stacks.isEmpty()) return
        val maxV = niceMax((stacks.maxOfOrNull { s -> s.sumOf { it.first } } ?: 0.0) * 1.05)
        yAxis(c, maxV) { com.essential.app.core.TimeUtil.fmtHours(it) }
        val chartH = height - padB - padT
        val slotW = (width - padL - padR) / stacks.size
        val bw = (slotW * 0.62f).coerceAtMost(dp(26).toFloat())
        stacks.forEachIndexed { i, s ->
            val x = padL + slotW * (i + 0.5f)
            var base = padT + chartH
            s.forEach { (v, col) ->
                val hgt = chartH * (v / maxV).toFloat()
                if (hgt > 0) { fill.color = col; c.drawRect(x - bw / 2, base - hgt, x + bw / 2, base - dp(1), fill); base -= hgt }
            }
        }
        xLabels(c, labels, slotW)
    }
}

class LineChart(ctx: Context, val series: List<List<Double?>>, val colors: List<Int>, val labels: List<String>, val fixedMax: Double? = null,
                heightDp: Int = 140, val fmt: (Double) -> String = { "%.1f".format(it) }) : ChartView(ctx, heightDp) {
    override fun onDraw(c: Canvas) {
        val n = series.maxOfOrNull { it.size } ?: 0
        if (n == 0) return
        val maxV = fixedMax ?: niceMax((series.flatten().filterNotNull().maxOrNull() ?: 1.0) * 1.05)
        yAxis(c, maxV, fmt)
        val chartH = height - padB - padT
        val slotW = (width - padL - padR) / n
        series.forEachIndexed { si, s ->
            stroke.color = colors[si]; stroke.strokeWidth = dp(2.2f).toFloat()
            val path = Path(); var started = false
            s.forEachIndexed { i, v ->
                if (v == null) { started = false; return@forEachIndexed }
                val x = padL + slotW * (i + 0.5f); val y = padT + chartH * (1 - (v / maxV)).toFloat()
                if (!started) { path.moveTo(x, y); started = true } else path.lineTo(x, y)
                fill.color = colors[si]; c.drawCircle(x, y, dp(2.5f).toFloat(), fill)
            }
            c.drawPath(path, stroke)
        }
        xLabels(c, labels, slotW)
    }
}

/** Two bars per slot (e.g. focus and energy by hour; sleep vs essential hours). */
class DualBarChart(ctx: Context, val a: List<Double?>, val b: List<Double?>, val colorA: Int, val colorB: Int, val labels: List<String>,
                   val fixedMax: Double? = null, heightDp: Int = 150, val fmt: (Double) -> String = { "%.1f".format(it) }) : ChartView(ctx, heightDp) {
    override fun onDraw(c: Canvas) {
        val n = max(a.size, b.size)
        if (n == 0) return
        val maxV = fixedMax ?: niceMax(((a + b).filterNotNull().maxOrNull() ?: 1.0) * 1.05)
        yAxis(c, maxV, fmt)
        val chartH = height - padB - padT
        val slotW = (width - padL - padR) / n
        val bw = (slotW * 0.34f).coerceAtMost(dp(12).toFloat())
        for (i in 0 until n) {
            val x = padL + slotW * (i + 0.5f)
            a.getOrNull(i)?.let { v -> fill.color = colorA; c.drawRoundRect(RectF(x - bw - dp(1), padT + chartH * (1 - (v / maxV)).toFloat(), x - dp(1), padT + chartH), dp(3).toFloat(), dp(3).toFloat(), fill) }
            b.getOrNull(i)?.let { v -> fill.color = colorB; c.drawRoundRect(RectF(x + dp(1), padT + chartH * (1 - (v / maxV)).toFloat(), x + bw + dp(1), padT + chartH), dp(3).toFloat(), dp(3).toFloat(), fill) }
        }
        xLabels(c, labels, slotW)
    }
}

/** Calendar heatmap: columns are weeks (Mon–Sun rows). */
class Heatmap(ctx: Context, val days: List<Pair<java.time.LocalDate, Int?>>) : View(ctx) {
    private val fill = Paint(Paint.ANTI_ALIAS_FLAG)
    private val label = Paint(Paint.ANTI_ALIAS_FLAG).apply { typeface = Fonts.regular; textSize = ctx.dp(10).toFloat(); color = Th.faint }
    private val weeks: Int get() {
        if (days.isEmpty()) return 0
        val first = com.essential.app.core.TimeUtil.weekStart(days.first().first)
        return (java.time.temporal.ChronoUnit.DAYS.between(first, days.last().first) / 7 + 1).toInt()
    }
    override fun onMeasure(w: Int, h: Int) {
        val width = MeasureSpec.getSize(w)
        val cell = cellSize(width)
        setMeasuredDimension(width, (cell * 7 + dp(4) * 6).toInt())
    }
    private fun cellSize(width: Int): Float = ((width - dp(22)) / weeks.coerceAtLeast(1) - dp(4)).toFloat().coerceIn(dp(8).toFloat(), dp(26).toFloat())
    override fun onDraw(c: Canvas) {
        if (days.isEmpty()) return
        val cell = cellSize(width); val gap = dp(4)
        val first = com.essential.app.core.TimeUtil.weekStart(days.first().first)
        listOf(0 to "M", 2 to "W", 4 to "F", 6 to "S").forEach { (r, s) -> c.drawText(s, 0f, r * (cell + gap) + cell * 0.75f, label) }
        days.forEach { (d, score) ->
            val col = (java.time.temporal.ChronoUnit.DAYS.between(first, d) / 7).toInt()
            val row = d.dayOfWeek.value - 1
            val x = dp(18) + col * (cell + gap); val y = row * (cell + gap)
            fill.color = if (score == null) Th.surface2 else Th.scoreColor(score)
            c.drawRoundRect(RectF(x, y, x + cell, y + cell), dp(4).toFloat(), dp(4).toFloat(), fill)
        }
    }
}

/** Legend row: colored dots with labels. */
fun Context.legend(vararg items: Pair<String, Int>): Flow {
    val f = Flow(this, dp(14), dp(4))
    items.forEach { (name, col) ->
        val row = hbox()
        row.add(dot(col, 9), dp(9), dp(9), end = 6)
        row.add(txt(name, 12.5f, Th.dim), WRAP, WRAP)
        f.addView(row)
    }
    return f
}

/** Horizontal labelled bars built from views. */
fun Context.hbars(rows: List<Triple<String, Double, Int>>, valueText: (Double) -> String, max: Double? = null, labels: List<String>? = null): View {
    val box = vbox()
    val m = max ?: (rows.maxOfOrNull { it.second } ?: 1.0).coerceAtLeast(0.0001)
    rows.forEachIndexed { i, (name, v, col) ->
        val top = hbox()
        top.add(txt(name, 14f, Th.text, maxLines = 1), 0, WRAP, 1f)
        top.add(txt(labels?.getOrNull(i) ?: valueText(v), 13.5f, Th.dim), WRAP, WRAP)
        box.add(top, top = 8)
        box.addProgress((v / m).coerceIn(0.0, 1.0), col, 6, top = 6)
    }
    return box
}
