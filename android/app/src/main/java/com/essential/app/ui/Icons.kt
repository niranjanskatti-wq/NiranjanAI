package com.essential.app.ui

import android.graphics.Canvas
import android.graphics.ColorFilter
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.RectF
import android.graphics.drawable.Drawable

/** Bundled line icons drawn on a 24-unit grid (no icon fonts, nothing downloaded). */
class Icon(private val name: String, private val color: Int, private val sizePx: Int) : Drawable() {
    private val p = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE; strokeCap = Paint.Cap.ROUND; strokeJoin = Paint.Join.ROUND; this.color = this@Icon.color
    }
    private val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL; this.color = this@Icon.color }

    override fun getIntrinsicWidth() = sizePx
    override fun getIntrinsicHeight() = sizePx
    override fun setAlpha(alpha: Int) { p.alpha = alpha; fill.alpha = alpha }
    override fun setColorFilter(colorFilter: ColorFilter?) { p.colorFilter = colorFilter; fill.colorFilter = colorFilter }
    @Deprecated("Deprecated in Java") override fun getOpacity() = PixelFormat.TRANSLUCENT

    override fun draw(c: Canvas) {
        val b = bounds
        val s = minOf(b.width(), b.height()) / 24f
        c.save()
        c.translate(b.left + (b.width() - 24 * s) / 2, b.top + (b.height() - 24 * s) / 2)
        c.scale(s, s)
        p.strokeWidth = 1.8f
        val path = Path()
        when (name) {
            "now" -> { c.drawCircle(12f, 12f, 8.5f, p); c.drawCircle(12f, 12f, 4f, p); c.drawCircle(12f, 12f, 1.2f, fill) }
            "log" -> { c.drawCircle(12f, 12f, 8.5f, p); path.moveTo(12f, 7.5f); path.lineTo(12f, 12f); path.lineTo(15f, 14f); c.drawPath(path, p) }
            "insights" -> { c.drawLine(5f, 19f, 5f, 12f, p); c.drawLine(10f, 19f, 10f, 6f, p); c.drawLine(15f, 19f, 15f, 10f, p); c.drawLine(20f, 19f, 20f, 4f, p) }
            "tools" -> { for ((x, y) in listOf(6.5f to 6.5f, 17.5f to 6.5f, 6.5f to 17.5f, 17.5f to 17.5f)) c.drawRoundRect(RectF(x - 3.5f, y - 3.5f, x + 3.5f, y + 3.5f), 1.5f, 1.5f, p) }
            "settings" -> { c.drawLine(4f, 7f, 20f, 7f, p); c.drawLine(4f, 17f, 20f, 17f, p); c.drawCircle(9f, 7f, 2.4f, fill); c.drawCircle(15f, 17f, 2.4f, fill) }
            "back" -> { path.moveTo(19f, 12f); path.lineTo(5f, 12f); path.moveTo(11f, 6f); path.lineTo(5f, 12f); path.lineTo(11f, 18f); c.drawPath(path, p) }
            "close" -> { c.drawLine(6f, 6f, 18f, 18f, p); c.drawLine(18f, 6f, 6f, 18f, p) }
            "plus" -> { c.drawLine(12f, 5f, 12f, 19f, p); c.drawLine(5f, 12f, 19f, 12f, p) }
            "check" -> { path.moveTo(5f, 12.5f); path.lineTo(10f, 17.5f); path.lineTo(19f, 7f); c.drawPath(path, p) }
            "lock" -> { c.drawRoundRect(RectF(5.5f, 10.5f, 18.5f, 20f), 2f, 2f, p); path.moveTo(8.5f, 10.5f); path.lineTo(8.5f, 8f)
                path.cubicTo(8.5f, 3.5f, 15.5f, 3.5f, 15.5f, 8f); path.lineTo(15.5f, 10.5f); c.drawPath(path, p) }
            "mic" -> { c.drawRoundRect(RectF(9f, 3.5f, 15f, 14f), 3f, 3f, p); path.moveTo(5.5f, 11f); path.cubicTo(5.5f, 19.5f, 18.5f, 19.5f, 18.5f, 11f)
                c.drawPath(path, p); c.drawLine(12f, 17.5f, 12f, 21f, p) }
            "play" -> { path.moveTo(8f, 5.5f); path.lineTo(18.5f, 12f); path.lineTo(8f, 18.5f); path.close(); c.drawPath(path, fill) }
            "pause" -> { c.drawRoundRect(RectF(7f, 5.5f, 10.5f, 18.5f), 1f, 1f, fill); c.drawRoundRect(RectF(13.5f, 5.5f, 17f, 18.5f), 1f, 1f, fill) }
            "stop" -> c.drawRoundRect(RectF(6.5f, 6.5f, 17.5f, 17.5f), 2f, 2f, fill)
            "right" -> { path.moveTo(9.5f, 6f); path.lineTo(15.5f, 12f); path.lineTo(9.5f, 18f); c.drawPath(path, p) }
            "left" -> { path.moveTo(14.5f, 6f); path.lineTo(8.5f, 12f); path.lineTo(14.5f, 18f); c.drawPath(path, p) }
            "up" -> { path.moveTo(6f, 14.5f); path.lineTo(12f, 8.5f); path.lineTo(18f, 14.5f); c.drawPath(path, p) }
            "down" -> { path.moveTo(6f, 9.5f); path.lineTo(12f, 15.5f); path.lineTo(18f, 9.5f); c.drawPath(path, p) }
            "edit" -> { path.moveTo(4.5f, 19.5f); path.lineTo(5.5f, 15f); path.lineTo(15.5f, 5f); path.lineTo(19f, 8.5f); path.lineTo(9f, 18.5f); path.close(); c.drawPath(path, p) }
            "trash" -> { c.drawLine(4.5f, 7f, 19.5f, 7f, p); path.moveTo(6.5f, 7f); path.lineTo(7.5f, 20f); path.lineTo(16.5f, 20f); path.lineTo(17.5f, 7f)
                path.moveTo(9.5f, 7f); path.lineTo(10f, 4f); path.lineTo(14f, 4f); path.lineTo(14.5f, 7f); c.drawPath(path, p) }
            "share" -> { c.drawCircle(6.5f, 12f, 2.5f, p); c.drawCircle(17.5f, 6f, 2.5f, p); c.drawCircle(17.5f, 18f, 2.5f, p)
                c.drawLine(8.7f, 10.8f, 15.3f, 7.2f, p); c.drawLine(8.7f, 13.2f, 15.3f, 16.8f, p) }
            "bell" -> { path.moveTo(6f, 16.5f); path.lineTo(6f, 11f); path.cubicTo(6f, 4f, 18f, 4f, 18f, 11f); path.lineTo(18f, 16.5f); path.close()
                c.drawPath(path, p); c.drawLine(10f, 20f, 14f, 20f, p) }
            "bolt" -> { path.moveTo(13f, 3f); path.lineTo(6f, 13.5f); path.lineTo(11.5f, 13.5f); path.lineTo(10.5f, 21f); path.lineTo(18f, 10f)
                path.lineTo(12.5f, 10f); path.close(); c.drawPath(path, fill) }
            "timer" -> { c.drawCircle(12f, 13f, 7.5f, p); c.drawLine(12f, 13f, 12f, 9f, p); c.drawLine(10f, 3f, 14f, 3f, p) }
            "idea" -> { path.moveTo(9f, 17f); path.cubicTo(9f, 14f, 5.5f, 13f, 5.5f, 9.5f); path.cubicTo(5.5f, 1.5f, 18.5f, 1.5f, 18.5f, 9.5f)
                path.cubicTo(18.5f, 13f, 15f, 14f, 15f, 17f); path.close(); c.drawPath(path, p); c.drawLine(10f, 20.5f, 14f, 20.5f, p) }
            "warn" -> { path.moveTo(12f, 4f); path.lineTo(21f, 19.5f); path.lineTo(3f, 19.5f); path.close(); c.drawPath(path, p)
                c.drawLine(12f, 10f, 12f, 14f, p); c.drawCircle(12f, 16.8f, 0.9f, fill) }
            "moon" -> { path.moveTo(19f, 14.5f); path.cubicTo(13f, 17f, 7f, 11f, 9.5f, 5f); path.cubicTo(3f, 7f, 3.5f, 19.5f, 12f, 20f)
                path.cubicTo(15f, 20.2f, 17.8f, 18f, 19f, 14.5f); c.drawPath(path, p) }
            "copy" -> { c.drawRoundRect(RectF(8.5f, 8.5f, 19.5f, 19.5f), 2f, 2f, p); path.moveTo(15.5f, 8.5f); path.lineTo(15.5f, 4.5f)
                path.lineTo(4.5f, 4.5f); path.lineTo(4.5f, 15.5f); path.lineTo(8.5f, 15.5f); c.drawPath(path, p) }
            "dot" -> c.drawCircle(12f, 12f, 4f, fill)
            "alarm" -> { c.drawCircle(12f, 13f, 7f, p); path.moveTo(12f, 9.5f); path.lineTo(12f, 13f); path.lineTo(14.5f, 14.5f)
                path.moveTo(3.5f, 6.5f); path.lineTo(6.5f, 3.5f); path.moveTo(20.5f, 6.5f); path.lineTo(17.5f, 3.5f)
                path.moveTo(7f, 19.5f); path.lineTo(5.5f, 21f); path.moveTo(17f, 19.5f); path.lineTo(18.5f, 21f); c.drawPath(path, p) }
            "drag" -> { for (y in listOf(8f, 12f, 16f)) c.drawLine(5f, y, 19f, y, p) }
            "repeat" -> { path.moveTo(5f, 12f); path.cubicTo(5f, 7f, 9f, 6f, 12f, 6f); path.lineTo(18f, 6f); path.moveTo(15f, 3f); path.lineTo(18f, 6f); path.lineTo(15f, 9f)
                path.moveTo(19f, 12f); path.cubicTo(19f, 17f, 15f, 18f, 12f, 18f); path.lineTo(6f, 18f); path.moveTo(9f, 15f); path.lineTo(6f, 18f); path.lineTo(9f, 21f); c.drawPath(path, p) }
            else -> c.drawCircle(12f, 12f, 3f, fill)
        }
        c.restore()
    }
}
