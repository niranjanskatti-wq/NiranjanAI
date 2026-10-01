package com.essential.app.ui

import android.content.Context
import android.graphics.Typeface
import com.essential.app.data.Cat
import com.essential.app.data.Plan
import com.essential.app.data.Type

/** Calm, few-color palette. Dark is the default. */
object Th {
    var dark = true

    private fun c(d: Long, l: Long) = (if (dark) d else l).toInt()

    val bg get() = c(0xFF0E1012, 0xFFF6F5F2)
    val surface get() = c(0xFF16191C, 0xFFFFFFFF)
    val surface2 get() = c(0xFF1E2226, 0xFFEFEDE8)
    val surface3 get() = c(0xFF272C31, 0xFFE4E1DA)
    val outline get() = c(0xFF2E3439, 0xFFDAD6CE)
    val text get() = c(0xFFE9EBEC, 0xFF1A1C1E)
    val dim get() = c(0xFFA1A8AE, 0xFF5D6266)
    val faint get() = c(0xFF6C747B, 0xFF8E9296)
    val primary get() = c(0xFF7FD1B9, 0xFF22745F)
    val onPrimary get() = c(0xFF06261D, 0xFFFFFFFF)
    val primaryContainer get() = c(0xFF1C3A32, 0xFFD3EEE5)
    val onPrimaryContainer get() = c(0xFFBDEBDD, 0xFF0B3B2E)
    val essential get() = primary
    val necessary get() = c(0xFF8AB4F8, 0xFF3D6DB5)
    val trivial get() = c(0xFFE6C07B, 0xFFA77A1E)
    val green get() = c(0xFF7FD1B9, 0xFF2E8B6F)
    val yellow get() = c(0xFFE6C07B, 0xFFC4932A)
    val red get() = c(0xFFE88A8A, 0xFFC0504D)
    val grey get() = c(0xFF353B41, 0xFFD5D2CB)
    val scrim get() = c(0xAA000000, 0x66000000)

    fun type(t: String?) = when (t) { Type.ESSENTIAL -> essential; Type.NECESSARY -> necessary; Type.TRIVIAL -> trivial; else -> grey }
    fun plan(p: String?) = when (p) { Plan.YES -> green; Plan.PARTLY -> yellow; Plan.NO -> red; else -> grey }

    fun category(cat: String?) = when (cat) {
        Cat.ESSENTIAL, Cat.THINK -> essential
        Cat.BUSINESS, Cat.ADMIN, Cat.PLANNING, Cat.LEARNING, Cat.BUFFER -> necessary
        Cat.SLEEP, Cat.REST -> faint
        else -> dim
    }

    fun alpha(color: Int, a: Float): Int = (color and 0x00FFFFFF) or ((a * 255).toInt().coerceIn(0, 255) shl 24)

    fun scoreColor(score: Int): Int = when {
        score >= 75 -> green
        score >= 50 -> alpha(green, 0.6f)
        score >= 25 -> alpha(green, 0.32f)
        score > 0 -> alpha(green, 0.15f)
        else -> grey
    }
}

object Fonts {
    lateinit var light: Typeface; lateinit var regular: Typeface; lateinit var medium: Typeface; lateinit var semibold: Typeface
    private var loaded = false
    fun load(ctx: Context) {
        if (loaded) return
        fun f(n: String) = try { Typeface.createFromAsset(ctx.assets, "fonts/$n") } catch (e: Exception) { Typeface.DEFAULT }
        light = f("Inter_300Light.ttf"); regular = f("Inter_400Regular.ttf"); medium = f("Inter_500Medium.ttf"); semibold = f("Inter_600SemiBold.ttf")
        loaded = true
    }
}
