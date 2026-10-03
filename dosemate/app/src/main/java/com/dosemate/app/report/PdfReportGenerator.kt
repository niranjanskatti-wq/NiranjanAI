package com.dosemate.app.report

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import com.dosemate.app.R
import com.dosemate.app.data.db.JournalEntryEntity
import com.dosemate.app.data.db.MedicineWithTimes
import com.dosemate.app.data.repo.AppSettings
import com.dosemate.app.data.repo.DoseItem
import com.dosemate.app.data.repo.PhotoStore
import com.dosemate.app.data.repo.engine
import com.dosemate.app.data.repo.sortedTimes
import com.dosemate.app.data.repo.time
import com.dosemate.app.util.TimeFormat
import com.dosemate.app.util.doseLine
import com.dosemate.core.Adherence
import com.dosemate.core.DayAdherence
import com.dosemate.core.DoseOutcome
import com.dosemate.core.DoseStatus
import java.io.File
import java.io.FileOutputStream
import java.time.LocalDate

/** Input for the doctor report. */
data class ReportData(
    val from: LocalDate,
    val to: LocalDate,
    val settings: AppSettings,
    val medicines: List<MedicineWithTimes>,
    val dosesByDay: Map<LocalDate, List<DoseItem>>,
    val journal: List<JournalEntryEntity>,
    val photos: List<JournalEntryEntity>,
    val includeMedicines: Boolean,
    val includeAdherence: Boolean,
    val includeItch: Boolean,
)

/** Draws a clean A4 PDF with [PdfDocument]; nothing leaves the phone unless the user shares it. */
class PdfReportGenerator(private val context: Context, private val photoStore: PhotoStore) {

    private val pageW = 595
    private val pageH = 842
    private val margin = 40f

    private val doc = PdfDocument()
    private var page: PdfDocument.Page? = null
    private lateinit var canvas: Canvas
    private var y = 0f
    private var pageNo = 0

    private val accent = Color.rgb(14, 140, 126)
    private val text = TextPaint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.rgb(30, 38, 48); textSize = 10f }
    private val muted = TextPaint(text).apply { color = Color.rgb(100, 112, 125) }
    private val bold = TextPaint(text).apply { typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD) }
    private val h1 = TextPaint(bold).apply { textSize = 22f; color = accent }
    private val h2 = TextPaint(bold).apply { textSize = 14f; color = Color.rgb(30, 38, 48) }
    private val fill = Paint(Paint.ANTI_ALIAS_FLAG)

    private fun s(id: Int, vararg args: Any): String = context.getString(id, *args)

    fun generate(data: ReportData, out: File): File {
        newPage()
        header(data)
        if (data.includeMedicines) medicines(data)
        if (data.includeAdherence) adherence(data)
        if (data.includeItch && data.journal.isNotEmpty()) itch(data)
        if (data.photos.isNotEmpty()) photos(data)
        finishPage()
        FileOutputStream(out).use { doc.writeTo(it) }
        doc.close()
        return out
    }

    // ---- page handling

    private fun newPage() {
        finishPage()
        pageNo++
        val p = doc.startPage(PdfDocument.PageInfo.Builder(pageW, pageH, pageNo).create())
        page = p
        canvas = p.canvas
        y = margin
    }

    private fun finishPage() {
        val p = page ?: return
        val footer = s(R.string.report_footer, pageNo)
        canvas.drawText(footer, margin, pageH - 20f, muted)
        doc.finishPage(p)
        page = null
    }

    private fun ensure(space: Float) {
        if (y + space > pageH - 50f) newPage()
    }

    private fun paragraph(value: String, paint: TextPaint = text, width: Float = pageW - 2 * margin, x: Float = margin) {
        val layout = StaticLayout.Builder.obtain(value, 0, value.length, paint, width.toInt())
            .setAlignment(Layout.Alignment.ALIGN_NORMAL).setLineSpacing(2f, 1f).build()
        ensure(layout.height.toFloat())
        canvas.save()
        canvas.translate(x, y)
        layout.draw(canvas)
        canvas.restore()
        y += layout.height
    }

    private fun section(title: String) {
        ensure(40f)
        y += 14f
        canvas.drawText(title, margin, y + 12f, h2)
        y += 18f
        fill.color = Color.rgb(225, 230, 236)
        canvas.drawRect(margin, y, pageW - margin, y + 1f, fill)
        y += 8f
    }

    // ---- sections

    private fun header(data: ReportData) {
        fill.color = accent
        canvas.drawRoundRect(RectF(margin, y, margin + 6f, y + 44f), 3f, 3f, fill)
        canvas.drawText(s(R.string.report_title), margin + 16f, y + 22f, h1)
        canvas.drawText(
            s(R.string.report_period, TimeFormat.dayMonthYear(data.from), TimeFormat.dayMonthYear(data.to)) + "   ·   " +
                s(R.string.report_generated, TimeFormat.dayMonthYear(LocalDate.now())),
            margin + 16f, y + 40f, muted,
        )
        y += 60f
        val st = data.settings
        if (st.doctorName.isNotBlank()) paragraph(s(R.string.report_doctor, st.doctorName), bold)
        st.prescribedDate?.let { paragraph(s(R.string.prescribed_on, TimeFormat.dayMonthYear(it)), text) }
        if (st.dietNote.isNotBlank()) paragraph(s(R.string.report_diet, st.dietNote), text)
    }

    private fun medicines(data: ReportData) {
        section(s(R.string.report_medicines))
        val cols = floatArrayOf(margin, margin + 150f, margin + 280f, margin + 400f)
        ensure(20f)
        listOf(R.string.report_col_medicine, R.string.report_col_dose, R.string.report_col_schedule, R.string.report_col_course)
            .forEachIndexed { i, id -> canvas.drawText(s(id), cols[i], y + 10f, bold) }
        y += 16f
        val today = LocalDate.now()
        for (med in data.medicines) {
            val m = med.medicine
            val engine = med.engine()
            val progress = engine.progress(today)
            val times = med.sortedTimes.filter { it.enabled }.joinToString(", ") { TimeFormat.time(it.time, data.settings.use24h) }
            val course = TimeFormat.dayMonthYear(m.startDate) + " → " + (engine.lastDate?.let { TimeFormat.dayMonthYear(it) } ?: s(R.string.dur_ongoing)) +
                (progress.totalDays?.let { "\n" + s(R.string.day_n_of_m, progress.dayNumber.coerceAtLeast(0), it) } ?: "") +
                if (m.archived) "\n" + s(R.string.archived_short) else if (m.paused) "\n" + s(R.string.paused) else ""
            val rowTop = y
            ensure(46f)
            val startY = y
            val heights = mutableListOf<Float>()
            listOf(m.name, context.doseLine(m), times + "\n" + m.instructions, course).forEachIndexed { i, cell ->
                y = startY
                val width = (if (i < 3) cols[i + 1] - cols[i] else pageW - margin - cols[i]) - 8f
                paragraph(cell, if (i == 0) bold else text, width, cols[i])
                heights += y - startY
            }
            y = startY + (heights.maxOrNull() ?: 12f) + 8f
            if (m.warning.isNotBlank()) paragraph("⚠ " + m.warning, muted)
            fill.color = Color.rgb(240, 243, 246)
            canvas.drawRect(margin, y, pageW - margin, y + 0.8f, fill)
            y += 6f
            if (rowTop > y) y = rowTop
        }
    }

    private fun statusColor(status: DoseStatus): Int = when (status) {
        DoseStatus.TAKEN -> Color.rgb(47, 168, 102)
        DoseStatus.LATE -> Color.rgb(242, 169, 59)
        DoseStatus.SKIPPED -> Color.rgb(126, 140, 160)
        DoseStatus.MISSED -> Color.rgb(229, 72, 77)
        else -> Color.rgb(210, 216, 222)
    }

    private fun dayColor(day: DayAdherence): Int = when (day) {
        DayAdherence.TAKEN -> statusColor(DoseStatus.TAKEN)
        DayAdherence.LATE -> statusColor(DoseStatus.LATE)
        DayAdherence.SKIPPED -> statusColor(DoseStatus.SKIPPED)
        DayAdherence.MISSED -> statusColor(DoseStatus.MISSED)
        DayAdherence.PENDING -> Color.rgb(210, 216, 222)
        DayAdherence.NO_DOSES -> Color.rgb(240, 243, 246)
    }

    private fun adherence(data: ReportData) {
        section(s(R.string.report_adherence))
        val all = data.dosesByDay.values.flatten().map { DoseOutcome(it.med.medicine.id, it.slot.id, it.scheduledAt, it.status) }
        val pct = Adherence.percent(all)
        val counts = all.groupingBy { it.status }.eachCount()
        paragraph(
            s(R.string.report_overall, pct?.let { "$it%" } ?: "—") + "   " +
                s(R.string.status_taken) + ": ${counts[DoseStatus.TAKEN] ?: 0}   " +
                s(R.string.status_late) + ": ${counts[DoseStatus.LATE] ?: 0}   " +
                s(R.string.status_skipped) + ": ${counts[DoseStatus.SKIPPED] ?: 0}   " +
                s(R.string.status_missed) + ": ${counts[DoseStatus.MISSED] ?: 0}",
            bold,
        )
        y += 6f

        // Per medicine
        for (med in data.medicines) {
            val list = all.filter { it.medicineId == med.medicine.id }
            if (list.isEmpty()) continue
            val p = Adherence.percent(list) ?: continue
            ensure(16f)
            canvas.drawText(med.medicine.name, margin, y + 10f, text)
            val barX = margin + 200f
            val barW = 220f
            fill.color = Color.rgb(230, 234, 238)
            canvas.drawRoundRect(RectF(barX, y + 2f, barX + barW, y + 11f), 4f, 4f, fill)
            fill.color = accent
            canvas.drawRoundRect(RectF(barX, y + 2f, barX + barW * p / 100f, y + 11f), 4f, 4f, fill)
            canvas.drawText("$p%", barX + barW + 10f, y + 10f, bold)
            y += 16f
        }

        // Calendar strip: one square per day.
        y += 8f
        ensure(30f)
        canvas.drawText(s(R.string.report_daily), margin, y + 10f, muted)
        y += 16f
        val size = 12f
        val gap = 3f
        val perRow = ((pageW - 2 * margin) / (size + gap)).toInt()
        var d = data.from
        var i = 0
        ensure(size + 4)
        while (!d.isAfter(data.to)) {
            if (i > 0 && i % perRow == 0) {
                y += size + gap
                ensure(size + 4)
            }
            val outcomes = data.dosesByDay[d].orEmpty().map { DoseOutcome(it.med.medicine.id, it.slot.id, it.scheduledAt, it.status) }
            fill.color = dayColor(Adherence.dayAdherence(outcomes))
            val x = margin + (i % perRow) * (size + gap)
            canvas.drawRoundRect(RectF(x, y, x + size, y + size), 2f, 2f, fill)
            d = d.plusDays(1)
            i++
        }
        y += size + 10f
        legend()

        // Missed / skipped list
        val problems = data.dosesByDay.values.flatten()
            .filter { it.status == DoseStatus.MISSED || it.status == DoseStatus.SKIPPED }
            .sortedBy { it.scheduledAt }
        if (problems.isNotEmpty()) {
            y += 6f
            paragraph(s(R.string.report_missed_list), bold)
            problems.take(60).forEach { item ->
                val label = if (item.status == DoseStatus.MISSED) s(R.string.status_missed) else s(R.string.status_skipped)
                paragraph(
                    "• " + TimeFormat.dayMonthYear(item.scheduledAt.toLocalDate()) + " " +
                        TimeFormat.time(item.scheduledAt.toLocalTime(), data.settings.use24h) + " — " + item.med.medicine.name +
                        " — " + label + (item.log?.skipReason?.let { " ($it)" } ?: ""),
                    text,
                )
            }
            if (problems.size > 60) paragraph("… +${problems.size - 60}", muted)
        }
    }

    private fun legend() {
        ensure(16f)
        var x = margin
        listOf(
            DoseStatus.TAKEN to R.string.status_taken, DoseStatus.LATE to R.string.status_late,
            DoseStatus.SKIPPED to R.string.status_skipped, DoseStatus.MISSED to R.string.status_missed,
        ).forEach { (status, label) ->
            fill.color = statusColor(status)
            canvas.drawCircle(x + 4f, y + 6f, 4f, fill)
            val t = s(label)
            canvas.drawText(t, x + 12f, y + 10f, muted)
            x += 22f + muted.measureText(t)
        }
        y += 16f
    }

    private fun itch(data: ReportData) {
        section(s(R.string.report_itch))
        val entries = data.journal.filter { !it.date.isBefore(data.from) && !it.date.isAfter(data.to) }.sortedBy { it.date }
        if (entries.isEmpty()) {
            paragraph(s(R.string.report_no_itch), muted)
            return
        }
        if (entries.size >= 2) {
            ensure(110f)
            val left = margin + 20f
            val right = pageW - margin
            val top = y + 6f
            val bottom = y + 96f
            fill.color = Color.rgb(230, 234, 238)
            for (k in 0..2) {
                val gy = top + (bottom - top) * k / 2f
                canvas.drawRect(left, gy, right, gy + 0.6f, fill)
                canvas.drawText(listOf("10", "5", "0")[k], margin, gy + 3f, muted)
            }
            val line = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = accent; strokeWidth = 2f; style = Paint.Style.STROKE }
            var px = 0f
            var py = 0f
            entries.forEachIndexed { idx, e ->
                val x = left + (right - left) * idx / (entries.size - 1)
                val yy = bottom - (bottom - top) * e.itchScore / 10f
                if (idx > 0) canvas.drawLine(px, py, x, yy, line)
                fill.color = accent
                canvas.drawCircle(x, yy, 3f, fill)
                px = x
                py = yy
            }
            y = bottom + 10f
        }
        entries.forEach { e ->
            paragraph(TimeFormat.dayMonthYear(e.date) + " — " + s(R.string.itch_score_n, e.itchScore) +
                if (e.notes.isNotBlank()) " — ${e.notes}" else "", text)
        }
    }

    private fun photos(data: ReportData) {
        section(s(R.string.report_photos))
        val cellW = (pageW - 2 * margin - 16f) / 2f
        val cellH = cellW * 1.1f
        data.photos.sortedBy { it.date }.chunked(2).forEach { row ->
            ensure(cellH + 30f)
            row.forEachIndexed { idx, e ->
                val x = margin + idx * (cellW + 16f)
                val bmp = e.photoPath?.let { decode(photoStore.file(PhotoStore.JOURNAL, it), 900) }
                if (bmp != null) {
                    val scale = minOf(cellW / bmp.width, cellH / bmp.height)
                    val w = bmp.width * scale
                    val h = bmp.height * scale
                    canvas.drawBitmap(bmp, null, RectF(x, y, x + w, y + h), null)
                    bmp.recycle()
                }
                canvas.drawText(TimeFormat.dayMonthYear(e.date) + " · " + s(R.string.itch_score_n, e.itchScore), x, y + cellH + 14f, muted)
            }
            y += cellH + 26f
        }
    }

    private fun decode(file: File, maxEdge: Int): Bitmap? = runCatching {
        if (!file.exists()) return null
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.absolutePath, bounds)
        var sample = 1
        while (bounds.outWidth / (sample * 2) >= maxEdge) sample *= 2
        BitmapFactory.decodeFile(file.absolutePath, BitmapFactory.Options().apply { inSampleSize = sample })
    }.getOrNull()
}
