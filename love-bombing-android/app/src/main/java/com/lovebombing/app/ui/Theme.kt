package com.lovebombing.app.ui

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

val Plum = Color(0xFF4A1942)
val PlumLight = Color(0xFF6B2560)
val Rose = Color(0xFFD9546E)
val RoseSoft = Color(0xFFFBE3E8)
val Marigold = Color(0xFFF2A12E)
val MarigoldSoft = Color(0xFFFFF0D6)
val Cream = Color(0xFFFFF7F2)
val Ink = Color(0xFF2B1A28)
val Muted = Color(0xFF7A6676)
val SentGreen = Color(0xFF2E9E5B)

private val colors = lightColorScheme(
    primary = Plum,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFF3DDEE),
    onPrimaryContainer = Plum,
    secondary = Rose,
    onSecondary = Color.White,
    secondaryContainer = RoseSoft,
    onSecondaryContainer = Color(0xFF5C1426),
    tertiary = Marigold,
    onTertiary = Ink,
    tertiaryContainer = MarigoldSoft,
    onTertiaryContainer = Color(0xFF5A3A00),
    background = Cream,
    onBackground = Ink,
    surface = Color.White,
    onSurface = Ink,
    surfaceVariant = Color(0xFFF6ECEF),
    onSurfaceVariant = Muted,
    surfaceContainer = Color(0xFFFFF0EC),
    surfaceContainerHigh = Color.White,
    surfaceContainerLow = Color(0xFFFFFAF7),
    outline = Color(0xFFD9C6D2),
    outlineVariant = Color(0xFFEBDDE5),
)

// Bundled system fonts only: serif headings for warmth, sans-serif body for readability.
private val Serif = FontFamily.Serif
private val Sans = FontFamily.SansSerif

private val type = Typography(
    displaySmall = TextStyle(fontFamily = Serif, fontWeight = FontWeight.Bold, fontSize = 32.sp, lineHeight = 38.sp),
    headlineMedium = TextStyle(fontFamily = Serif, fontWeight = FontWeight.Bold, fontSize = 28.sp, lineHeight = 34.sp),
    headlineSmall = TextStyle(fontFamily = Serif, fontWeight = FontWeight.Bold, fontSize = 24.sp, lineHeight = 30.sp),
    titleLarge = TextStyle(fontFamily = Serif, fontWeight = FontWeight.SemiBold, fontSize = 22.sp, lineHeight = 28.sp),
    titleMedium = TextStyle(fontFamily = Sans, fontWeight = FontWeight.SemiBold, fontSize = 18.sp, lineHeight = 24.sp),
    titleSmall = TextStyle(fontFamily = Sans, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, lineHeight = 22.sp),
    bodyLarge = TextStyle(fontFamily = Sans, fontSize = 18.sp, lineHeight = 27.sp),
    bodyMedium = TextStyle(fontFamily = Sans, fontSize = 16.sp, lineHeight = 23.sp),
    bodySmall = TextStyle(fontFamily = Sans, fontSize = 14.sp, lineHeight = 20.sp),
    labelLarge = TextStyle(fontFamily = Sans, fontWeight = FontWeight.SemiBold, fontSize = 16.sp),
    labelMedium = TextStyle(fontFamily = Sans, fontWeight = FontWeight.Medium, fontSize = 14.sp),
    labelSmall = TextStyle(fontFamily = Sans, fontWeight = FontWeight.Medium, fontSize = 12.sp),
)

private val shapes = Shapes(
    small = RoundedCornerShape(12.dp),
    medium = RoundedCornerShape(20.dp),
    large = RoundedCornerShape(28.dp),
)

@Composable
fun LoveBombingTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = colors, typography = type, shapes = shapes, content = content)
}
