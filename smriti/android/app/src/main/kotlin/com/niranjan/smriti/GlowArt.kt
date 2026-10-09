package com.niranjan.smriti

import android.graphics.Bitmap
import android.graphics.BlurMaskFilter
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PathMeasure
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.SweepGradient
import java.io.ByteArrayOutputStream
import java.util.Random
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * Moving effects for the Today widget. A home-screen widget can't run real
 * animations, so each effect is drawn as [FRAMES] pictures that a ViewFlipper
 * shows one after another, like a flip-book. Every effect loops seamlessly.
 */
object GlowArt {
    const val FRAMES = 12

    val STYLES = setOf(
        "fire", "rays", "chase", "rainbow", "sparkle", "heartbeat", "lightning",
        "diya", "confetti", "balloons", "fireworks", "marquee", "aurora", "mandala",
        "muzzle", "tracer", "bullseye", "ricochet", "glass", "laser",
    )

    /** Pictures for [style] at [w]×[h] pixels. [color] null means the effect's own colours. */
    fun frames(style: String, w: Int, h: Int, color: Int?, density: Float, widthName: String, count: Int = FRAMES): List<Bitmap> =
        (0 until count).map { f -> render(style, w, h, color, density, widthName, f, count) }

    /** The same pictures as PNG files' bytes, for the preview in Settings. */
    fun png(frames: List<Bitmap>): List<ByteArray> = frames.map { b ->
        ByteArrayOutputStream().use { out ->
            b.compress(Bitmap.CompressFormat.PNG, 100, out)
            out.toByteArray()
        }
    }

    private class Ctx(
        val c: Canvas,
        val w: Float,
        val h: Float,
        val d: Float,
        val f: Int,
        val n: Int,
        val color: Int?,
        val stroke: Float,
    ) {
        val t get() = f.toFloat() / n
        val radius get() = 22 * d
        fun dp(v: Float) = v * d
    }

    private fun render(style: String, w: Int, h: Int, color: Int?, d: Float, widthName: String, f: Int, n: Int): Bitmap {
        val bmp = Bitmap.createBitmap(max(1, w), max(1, h), Bitmap.Config.ARGB_8888)
        val stroke = when (widthName) {
            "thin" -> 2f
            "thick" -> 5f
            else -> 3f
        } * d
        val x = Ctx(Canvas(bmp), w.toFloat(), h.toFloat(), d, f, n, color, stroke)
        when (style) {
            "fire" -> fire(x)
            "rays" -> rays(x)
            "chase" -> chase(x)
            "rainbow" -> rainbow(x)
            "sparkle" -> sparkle(x)
            "heartbeat" -> heartbeat(x)
            "lightning" -> lightning(x)
            "diya" -> diya(x)
            "confetti" -> confetti(x)
            "balloons" -> balloons(x)
            "fireworks" -> fireworks(x)
            "marquee" -> marquee(x)
            "aurora" -> aurora(x)
            "mandala" -> mandala(x)
            "muzzle" -> muzzle(x)
            "tracer" -> tracer(x)
            "bullseye" -> bullseye(x)
            "ricochet" -> ricochet(x)
            "glass" -> glass(x)
            "laser" -> laser(x)
        }
        return bmp
    }

    // ------------------------------------------------------------------ helpers

    private fun ring(x: Ctx, inset: Float): Path {
        val r = RectF(inset, inset, x.w - inset, x.h - inset)
        val rr = max(0f, x.radius - inset)
        return Path().apply { addRoundRect(r, rr, rr, Path.Direction.CW) }
    }

    private fun paint(color: Int, style: Paint.Style = Paint.Style.FILL, width: Float = 0f, blur: Float = 0f) =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            this.style = style
            strokeWidth = width
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
            if (blur > 0f) maskFilter = BlurMaskFilter(blur, BlurMaskFilter.Blur.NORMAL)
        }

    private fun alpha(c: Int, a: Float) = Color.argb((255 * a.coerceIn(0f, 1f)).toInt(), Color.red(c), Color.green(c), Color.blue(c))

    private fun mix(a: Int, b: Int, k: Float): Int {
        val t = k.coerceIn(0f, 1f)
        return Color.argb(
            (Color.alpha(a) + (Color.alpha(b) - Color.alpha(a)) * t).toInt(),
            (Color.red(a) + (Color.red(b) - Color.red(a)) * t).toInt(),
            (Color.green(a) + (Color.green(b) - Color.green(a)) * t).toInt(),
            (Color.blue(a) + (Color.blue(b) - Color.blue(a)) * t).toInt(),
        )
    }

    /** A soft glow under a bright line: the neon look. */
    private fun glowLine(x: Ctx, path: Path, color: Int, width: Float, strength: Float = 1f) {
        x.c.drawPath(path, paint(alpha(color, 0.55f * strength), Paint.Style.STROKE, width * 3.2f, width * 2.6f))
        x.c.drawPath(path, paint(alpha(color, strength), Paint.Style.STROKE, width))
        x.c.drawPath(path, paint(alpha(mix(color, Color.WHITE, 0.6f), strength), Paint.Style.STROKE, max(1f, width * 0.35f)))
    }

    private fun wave(t: Float, k: Int = 1) = sin(2 * PI * k * t).toFloat()

    // ------------------------------------------------------------------ effects

    /** Flames licking up from the border, like a frame on fire. */
    private fun fire(x: Ctx) {
        val base = x.color ?: Color.rgb(255, 120, 20)
        val outer = mix(base, Color.rgb(200, 20, 0), 0.45f)
        val core = mix(base, Color.rgb(255, 245, 190), 0.7f)
        val inset = x.dp(9f)
        val path = ring(x, inset)
        val pm = PathMeasure(path, false)
        val len = pm.length
        val step = x.dp(4.5f)
        val count = (len / step).toInt()
        val pos = FloatArray(2)
        val tan = FloatArray(2)
        val rnd = Random(4242L + x.f * 31L)
        for (layer in 0..1) {
            for (i in 0 until count) {
                pm.getPosTan(i * step, pos, tan)
                val top = pos[1] < x.h / 2
                // Flames always rise; the bottom edge burns inward, the top edge outward.
                val flicker = 0.55f + 0.25f * sin(i * 1.7f + 2f * PI.toFloat() * x.t * 2) +
                    0.2f * sin(i * 0.43f - 2f * PI.toFloat() * x.t) + rnd.nextFloat() * 0.25f
                val maxH = if (top) x.dp(9f) else x.dp(12f)
                val fh = maxH * flicker * (if (layer == 0) 1f else 0.55f)
                val fw = step * (if (layer == 0) 1.9f else 1.1f)
                val sway = (rnd.nextFloat() - 0.5f) * fw * 0.6f
                val px = pos[0]
                val py = pos[1]
                val p = Path().apply {
                    moveTo(px - fw / 2, py)
                    quadTo(px - fw * 0.35f, py - fh * 0.55f, px + sway, py - fh)
                    quadTo(px + fw * 0.35f, py - fh * 0.55f, px + fw / 2, py)
                    close()
                }
                val g = LinearGradient(
                    px, py, px, py - fh,
                    if (layer == 0) intArrayOf(alpha(base, 0.95f), alpha(outer, 0.75f), alpha(outer, 0f))
                    else intArrayOf(alpha(core, 1f), alpha(base, 0.8f), alpha(base, 0f)),
                    floatArrayOf(0f, 0.55f, 1f), Shader.TileMode.CLAMP,
                )
                x.c.drawPath(p, paint(Color.WHITE, blur = if (layer == 0) x.dp(1.5f) else 0f).apply { shader = g })
            }
        }
        glowLine(x, path, base, x.stroke * 0.8f)
        x.c.drawPath(path, paint(alpha(core, 0.9f), Paint.Style.STROKE, max(1f, x.stroke * 0.4f)))
    }

    /** Light rays spinning slowly out from the middle, behind the names. */
    private fun rays(x: Ctx) {
        val c = x.color ?: Color.rgb(230, 30, 30)
        val cx = x.w / 2
        val cy = x.h / 2
        val far = hypot(x.w, x.h)
        val near = min(x.w, x.h) * 0.18f
        val count = 12
        val turn = 2 * PI / count * x.t
        val rnd = Random(77L)
        for (i in 0 until count) {
            val a = 2 * PI * i / count + turn + (rnd.nextFloat() - 0.5f) * 0.25f
            val spread = 0.045f + rnd.nextFloat() * 0.035f
            val p = Path().apply {
                moveTo(cx + (near * cos(a - spread)).toFloat(), cy + (near * sin(a - spread)).toFloat())
                lineTo(cx + (far * cos(a - spread * 1.6f)).toFloat(), cy + (far * sin(a - spread * 1.6f)).toFloat())
                lineTo(cx + (far * cos(a + spread * 1.6f)).toFloat(), cy + (far * sin(a + spread * 1.6f)).toFloat())
                lineTo(cx + (near * cos(a + spread)).toFloat(), cy + (near * sin(a + spread)).toFloat())
                close()
            }
            val g = RadialGradient(cx, cy, far * 0.75f, intArrayOf(alpha(c, 0f), alpha(c, 0.55f), alpha(c, 0.25f)),
                floatArrayOf(0f, 0.45f, 1f), Shader.TileMode.CLAMP)
            x.c.drawPath(p, paint(Color.WHITE, blur = x.dp(1.2f)).apply { shader = g })
        }
        glowLine(x, ring(x, x.stroke * 1.5f), c, x.stroke * 0.7f, 0.8f)
    }

    /** A bright light with a tail racing round the edge. */
    private fun chase(x: Ctx) {
        val c = x.color ?: Color.rgb(64, 160, 255)
        val path = ring(x, x.stroke * 1.6f)
        x.c.drawPath(path, paint(alpha(c, 0.22f), Paint.Style.STROKE, x.stroke * 0.6f))
        val pm = PathMeasure(path, false)
        val len = pm.length
        for (k in 0..1) {
            val head = (len * (x.t + k * 0.5f)) % len
            val tail = len * 0.22f
            for (s in 0 until 8) {
                val from = head - tail * (s + 1) / 8
                val to = head - tail * s / 8
                val seg = Path()
                if (from >= 0) pm.getSegment(from, to, seg, true) else {
                    pm.getSegment(len + from, len, seg, true)
                    if (to > 0) pm.getSegment(0f, to, seg, true)
                }
                glowLine(x, seg, mix(c, Color.WHITE, if (s == 0) 0.4f else 0f), x.stroke * (1f - s * 0.08f), 1f - s * 0.11f)
            }
        }
    }

    /** A rainbow flowing round the border. */
    private fun rainbow(x: Ctx) {
        val colors = intArrayOf(
            Color.rgb(255, 59, 48), Color.rgb(255, 149, 0), Color.rgb(255, 214, 10), Color.rgb(52, 199, 89),
            Color.rgb(10, 132, 255), Color.rgb(191, 90, 242), Color.rgb(255, 59, 48),
        )
        val g = SweepGradient(x.w / 2, x.h / 2, colors, null)
        g.setLocalMatrix(Matrix().apply { setRotate(360f * x.t, x.w / 2, x.h / 2) })
        val path = ring(x, x.stroke * 1.6f)
        x.c.drawPath(path, paint(Color.WHITE, Paint.Style.STROKE, x.stroke * 3.2f, x.stroke * 2.4f).apply { shader = g; alpha = 150 })
        x.c.drawPath(path, paint(Color.WHITE, Paint.Style.STROKE, x.stroke).apply { shader = g })
    }

    private fun star(x: Ctx, cx: Float, cy: Float, size: Float, color: Int, a: Float) {
        if (a <= 0.02f) return
        val p = Path().apply {
            moveTo(cx, cy - size)
            quadTo(cx, cy, cx + size, cy)
            quadTo(cx, cy, cx, cy + size)
            quadTo(cx, cy, cx - size, cy)
            quadTo(cx, cy, cx, cy - size)
            close()
        }
        x.c.drawCircle(cx, cy, size * 0.9f, paint(alpha(color, a * 0.5f), blur = size))
        x.c.drawPath(p, paint(alpha(mix(color, Color.WHITE, 0.5f), a)))
    }

    /** Stars twinkling along the edge. */
    private fun sparkle(x: Ctx) {
        val c = x.color ?: Color.rgb(255, 215, 120)
        val path = ring(x, x.stroke * 1.6f)
        glowLine(x, path, c, x.stroke * 0.45f, 0.45f)
        val pm = PathMeasure(path, false)
        val pos = FloatArray(2)
        val rnd = Random(99L)
        val count = 18
        for (i in 0 until count) {
            pm.getPosTan(pm.length * (i + rnd.nextFloat() * 0.6f) / count, pos, null)
            val phase = rnd.nextFloat()
            val a = abs(sin(PI * (x.t * 2 + phase))).toFloat()
            star(x, pos[0], pos[1], x.dp(3f + 4f * a), if (i % 3 == 0) Color.WHITE else c, a)
        }
    }

    private fun heart(cx: Float, cy: Float, s: Float) = Path().apply {
        moveTo(cx, cy + s * 0.9f)
        cubicTo(cx - s * 1.4f, cy - s * 0.1f, cx - s * 0.7f, cy - s * 1.2f, cx, cy - s * 0.45f)
        cubicTo(cx + s * 0.7f, cy - s * 1.2f, cx + s * 1.4f, cy - s * 0.1f, cx, cy + s * 0.9f)
        close()
    }

    /** Lub-dub: the border and a little heart beat twice, then rest. */
    private fun heartbeat(x: Ctx) {
        val c = x.color ?: Color.rgb(255, 59, 107)
        val t = x.t
        val beat = max(0f, 1f - abs(t - 0.08f) * 9f) + 0.8f * max(0f, 1f - abs(t - 0.3f) * 9f)
        val k = 0.25f + 0.75f * beat.coerceIn(0f, 1f)
        val path = ring(x, x.stroke * 1.6f)
        glowLine(x, path, c, x.stroke * (0.7f + 0.6f * k), k)
        val s = x.dp(5f) * (1f + 0.35f * k)
        val hx = x.w - x.dp(16f)
        val hy = x.dp(15f)
        x.c.drawPath(heart(hx, hy, s), paint(alpha(c, 0.6f * k), blur = s))
        x.c.drawPath(heart(hx, hy, s), paint(alpha(c, 0.4f + 0.6f * k)))
    }

    /** Electric sparks crackling along the edge. */
    private fun lightning(x: Ctx) {
        val c = x.color ?: Color.rgb(120, 215, 255)
        val path = ring(x, x.stroke * 2f)
        glowLine(x, path, c, x.stroke * 0.4f, 0.35f)
        val pm = PathMeasure(path, false)
        val len = pm.length
        val rnd = Random(500L + x.f * 17L)
        val pos = FloatArray(2)
        val tan = FloatArray(2)
        repeat(3) {
            val start = rnd.nextFloat() * len
            val seg = len * (0.12f + rnd.nextFloat() * 0.15f)
            val bolt = Path()
            var d = 0f
            var first = true
            while (d <= seg) {
                pm.getPosTan((start + d) % len, pos, tan)
                val off = (rnd.nextFloat() - 0.5f) * x.dp(7f)
                val px = pos[0] - tan[1] * off
                val py = pos[1] + tan[0] * off
                if (first) bolt.moveTo(px, py) else bolt.lineTo(px, py)
                first = false
                d += x.dp(5f)
            }
            x.c.drawPath(bolt, paint(alpha(c, 0.7f), Paint.Style.STROKE, x.stroke * 2.4f, x.stroke * 2f))
            x.c.drawPath(bolt, paint(Color.WHITE, Paint.Style.STROKE, max(1f, x.stroke * 0.55f)))
        }
    }

    private fun flame(x: Ctx, px: Float, py: Float, fw: Float, fh: Float, color: Int) {
        val p = Path().apply {
            moveTo(px - fw / 2, py)
            quadTo(px - fw * 0.5f, py - fh * 0.5f, px, py - fh)
            quadTo(px + fw * 0.5f, py - fh * 0.5f, px + fw / 2, py)
            close()
        }
        x.c.drawCircle(px, py - fh * 0.45f, fh * 0.9f, paint(alpha(color, 0.35f), blur = fh * 0.8f))
        val g = LinearGradient(px, py, px, py - fh,
            intArrayOf(Color.rgb(255, 250, 220), mix(color, Color.YELLOW, 0.4f), alpha(color, 0.2f)),
            floatArrayOf(0f, 0.45f, 1f), Shader.TileMode.CLAMP)
        x.c.drawPath(p, paint(Color.WHITE).apply { shader = g })
    }

    /** A row of flickering diyas along the bottom, with a warm glowing edge. */
    private fun diya(x: Ctx) {
        val c = x.color ?: Color.rgb(255, 170, 40)
        glowLine(x, ring(x, x.stroke * 1.6f), c, x.stroke * 0.6f, 0.55f)
        val count = max(3, (x.w / x.dp(52f)).toInt())
        val rnd = Random(300L + x.f * 13L)
        val by = x.h - x.dp(5f)
        val bw = x.dp(13f)
        for (i in 0 until count) {
            val cx = x.w * (i + 0.5f) / count
            // Clay lamp
            val bowl = RectF(cx - bw / 2, by - x.dp(6f), cx + bw / 2, by + x.dp(3f))
            x.c.drawArc(bowl, 0f, 180f, true, paint(Color.rgb(178, 92, 38)))
            x.c.drawLine(cx - bw / 2, by - x.dp(1.5f), cx + bw / 2, by - x.dp(1.5f), paint(Color.rgb(214, 130, 60), Paint.Style.STROKE, x.dp(1.5f)))
            val fh = x.dp(8f) * (0.75f + rnd.nextFloat() * 0.45f)
            flame(x, cx + (rnd.nextFloat() - 0.5f) * x.dp(1.5f), by - x.dp(2f), x.dp(4.5f), fh, c)
        }
    }

    /** Coloured confetti falling gently. */
    private fun confetti(x: Ctx) {
        val palette = if (x.color == null) intArrayOf(
            Color.rgb(255, 82, 82), Color.rgb(255, 196, 0), Color.rgb(64, 196, 255),
            Color.rgb(105, 240, 174), Color.rgb(224, 64, 251),
        ) else intArrayOf(x.color, mix(x.color, Color.WHITE, 0.45f), mix(x.color, Color.BLACK, 0.25f))
        glowLine(x, ring(x, x.stroke * 1.6f), palette[0], x.stroke * 0.4f, 0.4f)
        val rnd = Random(11L)
        val count = (x.w * x.h / (x.dp(16f) * x.dp(16f))).toInt().coerceIn(18, 60)
        for (i in 0 until count) {
            val x0 = rnd.nextFloat() * x.w
            val y0 = rnd.nextFloat()
            val speed = 1 + rnd.nextInt(2)
            val y = ((y0 + x.t * speed) % 1f) * (x.h + x.dp(10f)) - x.dp(5f)
            val sway = sin(2 * PI * (x.t * speed + y0)).toFloat() * x.dp(4f)
            val size = x.dp(2.2f + rnd.nextFloat() * 2f)
            val col = palette[i % palette.size]
            x.c.save()
            x.c.translate(x0 + sway, y)
            x.c.rotate(360f * (x.t * speed + rnd.nextFloat()))
            if (i % 3 == 0) x.c.drawCircle(0f, 0f, size * 0.55f, paint(alpha(col, 0.85f)))
            else x.c.drawRect(-size, -size * 0.45f, size, size * 0.45f, paint(alpha(col, 0.85f)))
            x.c.restore()
        }
    }

    /** Balloons floating up at both ends. */
    private fun balloons(x: Ctx) {
        val palette = if (x.color == null) intArrayOf(
            Color.rgb(255, 82, 82), Color.rgb(255, 196, 0), Color.rgb(64, 196, 255),
            Color.rgb(224, 64, 251), Color.rgb(105, 240, 174),
        ) else intArrayOf(x.color, mix(x.color, Color.WHITE, 0.35f), mix(x.color, Color.BLACK, 0.2f))
        glowLine(x, ring(x, x.stroke * 1.6f), palette[0], x.stroke * 0.4f, 0.35f)
        val rnd = Random(21L)
        val count = 7
        val bw = x.dp(9f)
        for (i in 0 until count) {
            // Keep them to the left and right edges so the names stay clear.
            val side = i % 2
            val xb = if (side == 0) x.dp(8f) + rnd.nextFloat() * x.dp(22f) else x.w - x.dp(8f) - rnd.nextFloat() * x.dp(22f)
            val phase = rnd.nextFloat()
            val y = x.h + bw * 2 - ((x.t + phase) % 1f) * (x.h + bw * 4)
            val sway = sin(2 * PI * (x.t + phase)).toFloat() * x.dp(3f)
            val col = palette[i % palette.size]
            val cx = xb + sway
            x.c.drawLine(cx, y + bw * 1.15f, cx - sway * 0.6f, y + bw * 3.2f, paint(Color.argb(150, 230, 230, 230), Paint.Style.STROKE, x.dp(0.8f)))
            x.c.drawOval(RectF(cx - bw * 0.85f, y - bw * 1.1f, cx + bw * 0.85f, y + bw * 1.1f), paint(alpha(col, 0.92f)))
            x.c.drawOval(RectF(cx - bw * 0.45f, y - bw * 0.75f, cx - bw * 0.1f, y - bw * 0.25f), paint(Color.argb(120, 255, 255, 255)))
            val knot = Path().apply {
                moveTo(cx, y + bw * 1.05f)
                lineTo(cx - bw * 0.2f, y + bw * 1.35f)
                lineTo(cx + bw * 0.2f, y + bw * 1.35f)
                close()
            }
            x.c.drawPath(knot, paint(alpha(col, 0.92f)))
        }
    }

    /** Firework bursts popping in the corners. */
    private fun fireworks(x: Ctx) {
        val palette = if (x.color == null) intArrayOf(
            Color.rgb(255, 214, 10), Color.rgb(255, 82, 140), Color.rgb(64, 196, 255), Color.rgb(105, 240, 174),
        ) else intArrayOf(x.color, mix(x.color, Color.WHITE, 0.5f))
        glowLine(x, ring(x, x.stroke * 1.6f), palette[0], x.stroke * 0.4f, 0.3f)
        val spots = listOf(0.12f to 0.3f, 0.88f to 0.32f, 0.5f to 0.18f, 0.25f to 0.75f, 0.78f to 0.78f)
        val size = min(x.w, x.h) * 0.42f
        spots.forEachIndexed { k, (sx, sy) ->
            val p = (x.t + k / spots.size.toFloat()) % 1f
            if (p > 0.85f) return@forEachIndexed
            val r = size * (0.15f + 0.85f * (p / 0.85f))
            val a = 1f - p / 0.85f
            val col = palette[k % palette.size]
            val cx = x.w * sx
            val cy = x.h * sy
            for (i in 0 until 14) {
                val ang = 2 * PI * i / 14
                val ex = cx + (r * cos(ang)).toFloat()
                val ey = cy + (r * sin(ang)).toFloat() + r * 0.15f * p
                x.c.drawLine(cx + (r * 0.6f * cos(ang)).toFloat(), cy + (r * 0.6f * sin(ang)).toFloat(), ex, ey,
                    paint(alpha(col, a * 0.8f), Paint.Style.STROKE, x.dp(1.2f)))
                x.c.drawCircle(ex, ey, x.dp(1.8f), paint(alpha(mix(col, Color.WHITE, 0.4f), a), blur = x.dp(1.2f)))
            }
            if (p < 0.12f) x.c.drawCircle(cx, cy, x.dp(5f), paint(alpha(Color.WHITE, 1f - p / 0.12f), blur = x.dp(4f)))
        }
    }

    /** Theatre-style bulbs chasing round the edge. */
    private fun marquee(x: Ctx) {
        val c = x.color ?: Color.rgb(255, 213, 79)
        val path = ring(x, x.dp(6f))
        val pm = PathMeasure(path, false)
        val gap = x.dp(11f)
        val count = max(6, (pm.length / gap).toInt() / 3 * 3)
        val step = pm.length / count
        val pos = FloatArray(2)
        val on = x.f % 3
        for (i in 0 until count) {
            pm.getPosTan(i * step, pos, null)
            val lit = i % 3 == on
            val r = x.dp(if (lit) 2.6f else 2f)
            if (lit) x.c.drawCircle(pos[0], pos[1], r * 2.4f, paint(alpha(c, 0.55f), blur = r * 1.8f))
            x.c.drawCircle(pos[0], pos[1], r, paint(if (lit) mix(c, Color.WHITE, 0.55f) else alpha(c, 0.28f)))
        }
    }

    /** Northern-lights colours flowing round the edge. */
    private fun aurora(x: Ctx) {
        val colors = if (x.color == null) intArrayOf(
            Color.rgb(46, 230, 166), Color.rgb(0, 194, 255), Color.rgb(177, 77, 255), Color.rgb(46, 230, 166),
        ) else intArrayOf(x.color, mix(x.color, Color.WHITE, 0.5f), mix(x.color, Color.BLUE, 0.3f), x.color)
        val g = LinearGradient(0f, 0f, x.w, x.h, colors, null, Shader.TileMode.MIRROR)
        g.setLocalMatrix(Matrix().apply { setTranslate(x.w * 2 * x.t, x.h * wave(x.t) * 0.3f) })
        val path = ring(x, x.stroke * 2f)
        x.c.drawPath(path, paint(Color.WHITE, Paint.Style.STROKE, x.stroke * 4.5f, x.stroke * 3.5f).apply { shader = g; alpha = 170 })
        x.c.drawPath(path, paint(Color.WHITE, Paint.Style.STROKE, x.stroke * 1.2f).apply { shader = g })
    }

    /** Rangoli flowers slowly turning at both ends. */
    private fun mandala(x: Ctx) {
        val c1 = x.color ?: Color.rgb(255, 120, 40)
        val c2 = if (x.color == null) Color.rgb(230, 50, 140) else mix(x.color, Color.WHITE, 0.4f)
        glowLine(x, ring(x, x.stroke * 1.6f), c1, x.stroke * 0.45f, 0.45f)
        val r = min(x.h * 0.42f, x.w * 0.18f)
        for ((cx, dir) in listOf(r * 0.95f to 1f, x.w - r * 0.95f to -1f)) {
            val cy = x.h / 2
            x.c.save()
            x.c.translate(cx, cy)
            x.c.rotate(dir * 45f * x.t)
            for (layer in 0..2) {
                val petals = 8 + layer * 4
                val pr = r * (1f - layer * 0.28f)
                val col = if (layer % 2 == 0) c1 else c2
                for (i in 0 until petals) {
                    x.c.save()
                    x.c.rotate(360f * i / petals + layer * 11f)
                    val p = Path().apply {
                        moveTo(0f, 0f)
                        quadTo(pr * 0.22f, -pr * 0.5f, 0f, -pr)
                        quadTo(-pr * 0.22f, -pr * 0.5f, 0f, 0f)
                        close()
                    }
                    x.c.drawPath(p, paint(alpha(col, 0.45f)))
                    x.c.restore()
                }
            }
            x.c.drawCircle(0f, 0f, r * 0.14f, paint(alpha(Color.rgb(255, 214, 10), 0.8f)))
            x.c.restore()
        }
    }

    // ------------------------------------------------------------------ shooting range

    /** A star-shaped muzzle flash, longest in the direction of the shot. */
    private fun burst(x: Ctx, cx: Float, cy: Float, size: Float, angle: Double, a: Float, col: Int) {
        if (a <= 0f) return
        x.c.drawCircle(cx, cy, size * 0.9f, paint(alpha(col, 0.45f * a), blur = size * 0.6f))
        val spikes = 9
        val p = Path()
        for (i in 0 until spikes * 2) {
            val ang = angle + PI * i / spikes
            val forward = cos(ang - angle).toFloat().coerceAtLeast(0f)
            val r = if (i % 2 == 0) size * (0.45f + 0.95f * forward * forward) else size * 0.2f
            val px = cx + (r * cos(ang)).toFloat()
            val py = cy + (r * sin(ang)).toFloat()
            if (i == 0) p.moveTo(px, py) else p.lineTo(px, py)
        }
        p.close()
        x.c.drawPath(p, paint(alpha(col, 0.9f * a), blur = x.dp(1.5f)))
        x.c.drawCircle(cx, cy, size * 0.26f, paint(alpha(mix(col, Color.WHITE, 0.8f), a), blur = size * 0.12f))
    }

    /** A bullet with a glowing tail; ([dx], [dy]) is its direction of travel. */
    private fun streak(x: Ctx, hx: Float, hy: Float, dx: Float, dy: Float, len: Float, col: Int, a: Float = 1f, thick: Float = 1f) {
        val tx = hx - dx * len
        val ty = hy - dy * len
        val glow = LinearGradient(tx, ty, hx, hy, alpha(col, 0f), alpha(col, a), Shader.TileMode.CLAMP)
        x.c.drawLine(tx, ty, hx, hy, paint(Color.WHITE, Paint.Style.STROKE, x.dp(4.5f) * thick, x.dp(3f) * thick).apply { shader = glow })
        val core = LinearGradient(tx, ty, hx, hy, alpha(Color.WHITE, 0f), alpha(Color.WHITE, a), Shader.TileMode.CLAMP)
        x.c.drawLine(tx, ty, hx, hy, paint(Color.WHITE, Paint.Style.STROKE, x.dp(1.6f) * thick).apply { shader = core })
        x.c.drawCircle(hx, hy, x.dp(2.2f) * thick, paint(alpha(mix(col, Color.WHITE, 0.7f), a), blur = x.dp(1.5f)))
    }

    /** Sparks flying out from a hit; [p] runs 0..1 as they fly and fade. */
    private fun sparks(x: Ctx, cx: Float, cy: Float, p: Float, col: Int, size: Float, seed: Int, dir: Double = 0.0, spread: Double = 2 * PI) {
        if (p < 0f || p > 1f) return
        val rnd = Random(seed.toLong())
        val a = 1f - p
        val hot = mix(col, Color.WHITE, 0.55f)
        for (i in 0 until 12) {
            val ang = dir - spread / 2 + spread * rnd.nextFloat()
            val reach = size * (0.5f + rnd.nextFloat())
            val r1 = reach * p
            val r0 = max(0f, r1 - x.dp(6f))
            val fall = size * 0.35f * p * p
            x.c.drawLine(
                cx + (r0 * cos(ang)).toFloat(), cy + (r0 * sin(ang)).toFloat() + fall * 0.6f,
                cx + (r1 * cos(ang)).toFloat(), cy + (r1 * sin(ang)).toFloat() + fall,
                paint(alpha(hot, a), Paint.Style.STROKE, x.dp(1.4f)),
            )
        }
    }

    /** Gun smoke drifting up and fading; [p] runs 0..1. */
    private fun smoke(x: Ctx, cx: Float, cy: Float, p: Float, size: Float) {
        if (p < 0f || p > 1f) return
        for (i in 0 until 3) {
            val r = size * (0.35f + 0.25f * i) * (0.5f + p)
            val px = cx + size * 0.5f * i * p
            val py = cy - size * (0.3f + 0.4f * i) * p
            x.c.drawCircle(px, py, r, paint(alpha(Color.rgb(200, 200, 205), 0.28f * (1f - p)), blur = r * 0.6f))
        }
    }

    /** Bang! A muzzle flash in the corner, a bullet along the bottom, sparks where it lands. */
    private fun muzzle(x: Ctx) {
        val col = x.color ?: Color.rgb(255, 150, 40)
        val t = x.t
        val kick = max(0f, 1f - t * 5f)
        glowLine(x, ring(x, x.stroke * 1.6f), col, x.stroke * 0.5f, 0.25f + 0.75f * kick)
        val gx = x.dp(16f)
        val gy = x.h - x.dp(16f)
        val endX = x.w - x.dp(14f)
        smoke(x, gx + x.dp(8f), gy, t, min(x.h * 0.3f, x.dp(26f)))
        if (t < 0.25f) {
            val a = 1f - t / 0.25f
            burst(x, gx + x.dp(6f), gy, min(x.h * 0.42f, x.dp(36f)) * (0.8f + 0.5f * (1f - a)), 0.0, a, col)
        }
        if (t in 0.05f..0.6f) {
            val p = (t - 0.05f) / 0.55f
            streak(x, gx + (endX - gx) * p, gy, 1f, 0f, x.dp(46f), col)
        }
        sparks(x, endX, gy, (t - 0.6f) / 0.35f, col, x.dp(26f), 7, PI, PI * 1.1)
    }

    /** Tracer rounds racing along the top and bottom edges. */
    private fun tracer(x: Ctx) {
        val col = x.color ?: Color.rgb(255, 196, 64)
        glowLine(x, ring(x, x.stroke * 1.6f), col, x.stroke * 0.4f, 0.3f)
        val len = x.dp(40f)
        val span = x.w + len * 2
        for (k in 0 until 3) {
            val p = (x.t + k / 3f) % 1f
            val top = x.dp(9f)
            val bottom = x.h - x.dp(9f)
            streak(x, -len + span * p, top, 1f, 0f, len, col, 0.95f)
            streak(x, x.w + len - span * ((p + 0.17f) % 1f), bottom, -1f, 0f, len, col, 0.95f)
            if (p < 0.1f) burst(x, x.dp(4f), top, x.dp(14f), 0.0, 1f - p / 0.1f, col)
        }
    }

    /** A shot hits a target at the right end: ripples, sparks and a bullet hole. */
    private fun bullseye(x: Ctx) {
        val col = x.color ?: Color.rgb(230, 40, 40)
        val t = x.t
        // Small and faint, so "to wish" and the Done button stay easy to read over it.
        val r = min(x.h * 0.3f, x.w * 0.13f)
        val hitAt = 0.4f
        val shake = if (t in hitAt..hitAt + 0.2f) x.dp(3f) * wave((t - hitAt) * 5f, 1) else 0f
        val cx = x.w - r - x.dp(10f) + shake
        val cy = x.h / 2
        for (i in 4 downTo 0) {
            val ringCol = if (i % 2 == 0) col else Color.WHITE
            x.c.drawCircle(cx, cy, r * (i + 1) / 5f, paint(alpha(ringCol, 0.22f)))
        }
        x.c.drawCircle(cx, cy, r, paint(alpha(col, 0.45f), Paint.Style.STROKE, x.dp(1.2f)))
        if (t < hitAt) {
            if (t < 0.12f) burst(x, x.dp(12f), cy, min(x.h * 0.32f, x.dp(26f)), 0.0, 1f - t / 0.12f, Color.rgb(255, 170, 60))
            val p = t / hitAt
            streak(x, x.dp(16f) + (cx - x.dp(16f)) * p, cy, 1f, 0f, x.dp(44f), Color.rgb(255, 210, 120), 0.8f)
        } else {
            val p = (t - hitAt) / (1f - hitAt)
            for (k in 0..1) {
                val rp = (p * 1.6f - k * 0.35f)
                if (rp in 0f..1f) x.c.drawCircle(cx, cy, r * (1f + rp * 0.9f),
                    paint(alpha(col, 0.6f * (1f - rp)), Paint.Style.STROKE, x.dp(2f), x.dp(1.5f)))
            }
            sparks(x, cx, cy, p * 2.2f, Color.rgb(255, 200, 90), r * 1.3f, 11)
            x.c.drawCircle(cx + x.dp(1f), cy - x.dp(1f), x.dp(3.2f), paint(Color.rgb(25, 20, 20)))
            x.c.drawCircle(cx + x.dp(1f), cy - x.dp(1f), x.dp(3.2f), paint(alpha(Color.rgb(255, 180, 80), 0.7f), Paint.Style.STROKE, x.dp(1f)))
        }
        glowLine(x, ring(x, x.stroke * 1.6f), col, x.stroke * 0.45f, if (t in hitAt..hitAt + 0.15f) 1f else 0.35f)
    }

    private fun tri(u: Float): Float {
        val v = u - kotlin.math.floor(u)
        return 1f - abs(2f * v - 1f)
    }

    /** A bullet bouncing round inside the widget, sparking off every wall. */
    private fun ricochet(x: Ctx) {
        val col = x.color ?: Color.rgb(255, 214, 90)
        val m = x.dp(10f)
        val kx = 3
        val ky = 2
        fun pos(t: Float) = (m + (x.w - 2 * m) * tri(t * kx)) to (m + (x.h - 2 * m) * tri(t * ky + 0.5f))
        glowLine(x, ring(x, x.stroke * 1.6f), col, x.stroke * 0.4f, 0.3f)
        for ((k, phase) in listOf(kx to 0f, ky to 0.5f)) {
            val hits = 2 * k
            val last = kotlin.math.floor((x.t * k + phase) * 2f) / 2f
            val at = (last - phase) / k
            val age = x.t - at
            if (age in 0f..0.15f) {
                val (sx, sy) = pos(at)
                sparks(x, sx, sy, age / 0.15f, col, x.dp(22f), hits + (last * 4).toInt())
            }
        }
        val steps = 6
        for (i in steps downTo 1) {
            val (ax, ay) = pos(x.t - i * 0.012f)
            val (bx, by) = pos(x.t - (i - 1) * 0.012f)
            val a = 1f - i / (steps + 1f)
            x.c.drawLine(ax, ay, bx, by, paint(alpha(col, a * 0.7f), Paint.Style.STROKE, x.dp(4f), x.dp(2.5f)))
            x.c.drawLine(ax, ay, bx, by, paint(alpha(Color.WHITE, a), Paint.Style.STROKE, x.dp(1.5f)))
        }
        val (hx, hy) = pos(x.t)
        x.c.drawCircle(hx, hy, x.dp(3f), paint(mix(col, Color.WHITE, 0.7f), blur = x.dp(2f)))
    }

    /** Bullet holes crack the glass one after another, then it all clears. */
    private fun glass(x: Ctx) {
        val col = x.color ?: Color.rgb(220, 240, 255)
        val holes = listOf(0.09f to 0.3f, 0.92f to 0.68f, 0.5f to 0.16f)
        val fade = if (x.t > 0.85f) 1f - (x.t - 0.85f) / 0.15f else 1f
        glowLine(x, ring(x, x.stroke * 1.6f), col, x.stroke * 0.4f, 0.3f)
        val size = min(x.h * 0.5f, x.dp(46f))
        holes.forEachIndexed { k, (hx, hy) ->
            val at = k * 0.22f
            if (x.t < at) return@forEachIndexed
            val age = x.t - at
            val cx = x.w * hx
            val cy = x.h * hy
            val grow = min(1f, age / 0.1f)
            val rnd = Random(31L + k)
            val crack = paint(alpha(col, 0.75f * fade), Paint.Style.STROKE, x.dp(1f))
            val arms = 7 + rnd.nextInt(3)
            val ends = mutableListOf<Pair<Float, Float>>()
            for (i in 0 until arms) {
                val ang = 2 * PI * (i + rnd.nextFloat() * 0.6f) / arms
                val len = size * (0.55f + 0.45f * rnd.nextFloat()) * grow
                val p = Path().apply { moveTo(cx, cy) }
                var px = cx
                var py = cy
                for (s in 1..3) {
                    val jit = (rnd.nextFloat() - 0.5f) * 0.5
                    px = cx + (len * s / 3 * cos(ang + jit)).toFloat()
                    py = cy + (len * s / 3 * sin(ang + jit)).toFloat()
                    p.lineTo(px, py)
                    if (s == 2) ends.add(px to py)
                }
                x.c.drawPath(p, crack)
            }
            if (ends.size > 2) {
                val web = Path().apply {
                    moveTo(ends[0].first, ends[0].second)
                    for (e in ends.drop(1)) lineTo(e.first, e.second)
                    close()
                }
                x.c.drawPath(web, paint(alpha(col, 0.45f * fade), Paint.Style.STROKE, x.dp(0.8f)))
            }
            x.c.drawCircle(cx, cy, x.dp(4f), paint(alpha(Color.rgb(15, 15, 20), 0.9f * fade)))
            x.c.drawCircle(cx, cy, x.dp(4.5f), paint(alpha(col, 0.9f * fade), Paint.Style.STROKE, x.dp(1.2f)))
            if (age < 0.08f) burst(x, cx, cy, x.dp(18f), 2 * PI * rnd.nextFloat(), 1f - age / 0.08f, Color.rgb(255, 230, 160))
        }
    }

    /** Red laser bolts zap across, pew-pew, with a sight dot hunting about. */
    private fun laser(x: Ctx) {
        val col = x.color ?: Color.rgb(255, 30, 60)
        val t = x.t
        glowLine(x, ring(x, x.stroke * 1.6f), col, x.stroke * 0.45f, 0.35f + 0.4f * max(0f, wave(t, 2)))
        val len = x.dp(30f)
        for ((start, y, dir) in listOf(Triple(0f, x.h * 0.2f, 1f), Triple(0.5f, x.h * 0.8f, -1f))) {
            val p = ((t - start) % 1f + 1f) % 1f / 0.45f
            if (p > 1f) continue
            val from = if (dir > 0) x.dp(8f) else x.w - x.dp(8f)
            val to = if (dir > 0) x.w + len else -len
            streak(x, from + (to - from) * p, y, dir, 0f, len, col, 1f, 1.4f)
            if (p < 0.2f) {
                val a = 1f - p / 0.2f
                x.c.drawCircle(from, y, x.dp(10f) * (1.4f - a), paint(alpha(col, 0.8f * a), Paint.Style.STROKE, x.dp(2f), x.dp(1.5f)))
                x.c.drawCircle(from, y, x.dp(4f), paint(alpha(Color.WHITE, a), blur = x.dp(3f)))
            }
        }
        val dx = x.w * (0.5f + 0.38f * wave(t, 1))
        val dy = x.h * (0.5f + 0.3f * sin(2 * PI * 2 * t + 1.0).toFloat())
        x.c.drawCircle(dx, dy, x.dp(7f), paint(alpha(col, 0.35f), blur = x.dp(5f)))
        x.c.drawCircle(dx, dy, x.dp(2.2f), paint(mix(col, Color.WHITE, 0.4f)))
    }
}
