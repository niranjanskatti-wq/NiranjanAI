package com.dosemate.app.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.shape.RoundedCornerShape
import com.dosemate.app.data.repo.AppSettings
import com.dosemate.app.data.repo.ThemeMode

data class Accent(val nameRes: Int, val light: Color, val dark: Color)

val Accents = listOf(
    Accent(com.dosemate.app.R.string.accent_teal, Color(0xFF0E8C7E), Color(0xFF63DCC8)),
    Accent(com.dosemate.app.R.string.accent_indigo, Color(0xFF4A56CF), Color(0xFFB0B8FF)),
    Accent(com.dosemate.app.R.string.accent_rose, Color(0xFFC93D72), Color(0xFFFFB1CB)),
    Accent(com.dosemate.app.R.string.accent_amber, Color(0xFFB86E00), Color(0xFFFFC46B)),
    Accent(com.dosemate.app.R.string.accent_emerald, Color(0xFF2B8F55), Color(0xFF8FE0AA)),
    Accent(com.dosemate.app.R.string.accent_violet, Color(0xFF7448D4), Color(0xFFD0B9FF)),
)

/** Colour tags for medicines. */
val MedicineColors = listOf(
    Color(0xFF14A38B), Color(0xFF3D7BF7), Color(0xFF9B59D0), Color(0xFFF08A24), Color(0xFFE5508C),
    Color(0xFF3FAF5A), Color(0xFFE04848), Color(0xFFE2B714), Color(0xFF1DB6D3), Color(0xFF8D6E63),
)

fun medicineColor(index: Int): Color = MedicineColors[index.mod(MedicineColors.size)]

/** Adherence status colours (shared by calendar, insights and the PDF). */
object StatusColors {
    val Taken = Color(0xFF2FA866)
    val Late = Color(0xFFF2A93B)
    val Skipped = Color(0xFF7E8CA0)
    val Missed = Color(0xFFE5484D)
    val Pending = Color(0xFF9AA5B1)
}

val LocalSettings = staticCompositionLocalOf { AppSettings() }

private fun scheme(accent: Accent, dark: Boolean, amoled: Boolean): ColorScheme {
    return if (!dark) {
        val p = accent.light
        lightColorScheme(
            primary = p,
            onPrimary = Color.White,
            primaryContainer = p.copy(alpha = 0.14f).compositeOver(Color.White),
            onPrimaryContainer = p.copy(alpha = 1f).darken(0.45f),
            secondary = p.darken(0.2f),
            secondaryContainer = p.copy(alpha = 0.08f).compositeOver(Color(0xFFF4F6F9)),
            onSecondaryContainer = Color(0xFF1C2530),
            tertiary = Color(0xFFE5508C),
            background = Color(0xFFF5F7FA),
            onBackground = Color(0xFF15202B),
            surface = Color.White,
            onSurface = Color(0xFF15202B),
            surfaceVariant = Color(0xFFEDF1F5),
            onSurfaceVariant = Color(0xFF5B6876),
            surfaceContainer = Color(0xFFF0F3F7),
            surfaceContainerHigh = Color(0xFFE9EDF2),
            surfaceContainerLow = Color(0xFFF8FAFC),
            outline = Color(0xFFCBD3DC),
            outlineVariant = Color(0xFFE1E6EC),
            error = StatusColors.Missed,
        )
    } else {
        val p = accent.dark
        val bg = if (amoled) Color.Black else Color(0xFF0E1317)
        val surface = if (amoled) Color(0xFF0A0A0A) else Color(0xFF161D22)
        darkColorScheme(
            primary = p,
            onPrimary = Color(0xFF00201B),
            primaryContainer = p.copy(alpha = 0.22f).compositeOver(surface),
            onPrimaryContainer = p.lighten(0.3f),
            secondary = p.lighten(0.15f),
            secondaryContainer = p.copy(alpha = 0.10f).compositeOver(surface),
            onSecondaryContainer = Color(0xFFE2E8EE),
            tertiary = Color(0xFFFFA8C5),
            background = bg,
            onBackground = Color(0xFFE6EBF0),
            surface = surface,
            onSurface = Color(0xFFE6EBF0),
            surfaceVariant = if (amoled) Color(0xFF141414) else Color(0xFF1F272D),
            onSurfaceVariant = Color(0xFFA5B0BB),
            surfaceContainer = if (amoled) Color(0xFF101010) else Color(0xFF1A2126),
            surfaceContainerHigh = if (amoled) Color(0xFF161616) else Color(0xFF222A30),
            surfaceContainerLow = if (amoled) Color(0xFF050505) else Color(0xFF13191D),
            outline = Color(0xFF3A444D),
            outlineVariant = if (amoled) Color(0xFF1E1E1E) else Color(0xFF2A333A),
            error = Color(0xFFFF8A8E),
        )
    }
}

fun Color.darken(f: Float) = Color(red * (1 - f), green * (1 - f), blue * (1 - f), alpha)
fun Color.lighten(f: Float) = Color(red + (1 - red) * f, green + (1 - green) * f, blue + (1 - blue) * f, alpha)

private val AppTypography = Typography().let { t ->
    t.copy(
        displaySmall = t.displaySmall.copy(fontWeight = FontWeight.SemiBold),
        headlineLarge = t.headlineLarge.copy(fontWeight = FontWeight.SemiBold),
        headlineMedium = t.headlineMedium.copy(fontWeight = FontWeight.SemiBold),
        headlineSmall = t.headlineSmall.copy(fontWeight = FontWeight.SemiBold),
        titleLarge = t.titleLarge.copy(fontWeight = FontWeight.SemiBold),
        titleMedium = t.titleMedium.copy(fontWeight = FontWeight.SemiBold),
        labelLarge = t.labelLarge.copy(fontWeight = FontWeight.SemiBold, letterSpacing = 0.2.sp),
    )
}

private val AppShapes = Shapes(
    extraSmall = RoundedCornerShape(8.dp),
    small = RoundedCornerShape(12.dp),
    medium = RoundedCornerShape(18.dp),
    large = RoundedCornerShape(24.dp),
    extraLarge = RoundedCornerShape(32.dp),
)

@Composable
fun isDarkTheme(settings: AppSettings): Boolean = when (settings.themeMode) {
    ThemeMode.SYSTEM -> isSystemInDarkTheme()
    ThemeMode.LIGHT -> false
    ThemeMode.DARK, ThemeMode.AMOLED -> true
}

@Composable
fun DoseMateTheme(settings: AppSettings, content: @Composable () -> Unit) {
    val dark = isDarkTheme(settings)
    val amoled = settings.themeMode == ThemeMode.AMOLED
    val accent = Accents[settings.accent.mod(Accents.size)]
    val density = LocalDensity.current
    val scaled = if (settings.largeText) Density(density.density, density.fontScale * 1.25f) else density
    MaterialTheme(colorScheme = scheme(accent, dark, amoled), typography = AppTypography, shapes = AppShapes) {
        CompositionLocalProvider(LocalSettings provides settings, LocalDensity provides scaled) {
            content()
        }
    }
}
