package com.essential.app.core

import com.essential.app.data.Block
import com.essential.app.data.Cat

/**
 * Pure block-timeline math on a 24-hour circle. The day is fixed at 1440 minutes:
 * adding or extending a block always takes time from other blocks, and the caller
 * is told exactly which blocks give up time (the trade-off rule).
 */
object Timeline {

    data class Affect(val block: Block, val lostMinutes: Int, val removed: Boolean)
    data class Result(val blocks: List<Block>, val affected: List<Affect>) {
        val touchesProtected get() = affected.any { it.block.isProtected || it.block.category == Cat.SLEEP }
    }

    private fun norm(m: Int) = ((m % 1440) + 1440) % 1440

    /**
     * Place [edited] (new or changed, matched by id when id != 0) into [blocks].
     * Overlapped blocks are trimmed, split or removed. Nothing is changed in place.
     */
    fun place(blocks: List<Block>, edited: Block): Result {
        val others = blocks.filter { edited.id == 0L || it.id != edited.id }
        val eStart = norm(edited.start)
        val eLen = edited.duration
        val out = ArrayList<Block>()
        val affected = ArrayList<Affect>()
        for (b in others) {
            val bs = norm(b.start - eStart)          // B start relative to E start
            val bl = b.duration
            // B occupies [bs, bs+bl) ; E occupies [0, eLen) and [1440, 1440+eLen)
            val pieces = subtract(listOf(bs to bs + bl), listOf(0 to eLen, 1440 to 1440 + eLen))
            val kept = pieces.sumOf { it.second - it.first }
            if (kept == bl) { out.add(b); continue }
            affected.add(Affect(b, bl - kept, pieces.isEmpty()))
            pieces.forEachIndexed { i, p ->
                out.add(b.copy(id = if (i == 0) b.id else 0L, start = norm(p.first + eStart), end = norm(p.second + eStart)))
            }
        }
        out.add(edited.copy(start = eStart, end = norm(edited.end)))
        return Result(out, affected)
    }

    private fun subtract(src: List<Pair<Int, Int>>, cuts: List<Pair<Int, Int>>): List<Pair<Int, Int>> {
        var cur = src
        for ((cs, ce) in cuts) {
            val next = ArrayList<Pair<Int, Int>>()
            for ((s, e) in cur) {
                if (ce <= s || cs >= e) { next.add(s to e); continue }
                if (cs > s) next.add(s to cs)
                if (ce < e) next.add(ce to e)
            }
            cur = next
        }
        return cur.filter { it.second > it.first }
    }

    /** Uncovered stretches of the day, as (startMinute, endMinute). */
    fun gaps(blocks: List<Block>, dayStart: Int): List<Pair<Int, Int>> {
        if (blocks.isEmpty()) return listOf(dayStart to dayStart)
        val covered = BooleanArray(1440)
        for (b in blocks) for (i in 0 until b.duration) covered[norm(b.start + i)] = true
        val out = ArrayList<Pair<Int, Int>>()
        var i = 0
        while (i < 1440) {
            val m = norm(dayStart + i)
            if (!covered[m]) {
                val s = m; var len = 0
                while (i < 1440 && !covered[norm(dayStart + i)]) { i++; len++ }
                out.add(s to norm(s + len))
            } else i++
        }
        return out
    }

    fun overlaps(blocks: List<Block>): Boolean {
        val cnt = IntArray(1440)
        for (b in blocks) for (i in 0 until b.duration) if (++cnt[norm(b.start + i)] > 1) return true
        return false
    }

    fun sorted(blocks: List<Block>, dayStart: Int): List<Block> = blocks.sortedBy { TimeUtil.offset(it.start, dayStart) }

    /** Swap two adjacent blocks, keeping each one's duration. [first] must come right before [second]. */
    fun swapAdjacent(blocks: List<Block>, first: Block, second: Block): List<Block> {
        val a = first.start
        val newSecond = second.copy(start = a, end = norm(a + second.duration))
        val newFirst = first.copy(start = newSecond.end, end = norm(newSecond.end + first.duration))
        return blocks.map { when (it.id) { first.id -> newFirst; second.id -> newSecond; else -> it } }
    }

    /** Block covering most of clock hour [hour]. */
    fun blockForHour(blocks: List<Block>, hour: Int): Block? {
        var best: Block? = null; var bestOv = 0
        for (b in blocks) {
            var ov = 0
            for (m in hour * 60 until hour * 60 + 60) if (b.contains(m)) ov++
            if (ov > bestOv) { bestOv = ov; best = b }
        }
        return best
    }

    fun blockAt(blocks: List<Block>, minuteOfDay: Int): Block? = blocks.firstOrNull { it.contains(minuteOfDay) }

    fun nextBlock(blocks: List<Block>, current: Block?, dayStart: Int): Block? {
        if (blocks.isEmpty()) return null
        val s = sorted(blocks, dayStart)
        if (current == null) return s.first()
        val i = s.indexOfFirst { it.id == current.id && it.start == current.start }
        return if (i < 0) null else s[(i + 1) % s.size]
    }

    fun hasBuffer(blocks: List<Block>): Boolean =
        blocks.any { it.category == Cat.BUFFER || it.title.contains("buffer", ignoreCase = true) }

    fun minutesBy(blocks: List<Block>, cats: Set<String>): Int = blocks.filter { it.category in cats }.sumOf { it.duration }
}
