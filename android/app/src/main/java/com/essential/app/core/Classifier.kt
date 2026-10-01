package com.essential.app.core

import com.essential.app.data.KeywordRule

/**
 * Turns a spoken or typed activity into category / venture / type using the
 * keyword rules editable in Settings. Offline and deterministic.
 * A future optional AI parser can implement [ActivityParser].
 */
interface ActivityParser { fun parse(text: String, rules: List<KeywordRule>): Classifier.Match? }

object Classifier : ActivityParser {
    data class Match(val category: String?, val ventureId: Long?, val type: String?, val keyword: String)

    override fun parse(text: String, rules: List<KeywordRule>): Match? {
        val t = " " + text.lowercase().replace(Regex("[^\\p{L}\\p{N}]+"), " ").trim() + " "
        var best: Match? = null
        var bestLen = 0
        for (r in rules) for (w in r.words) {
            val norm = w.replace(Regex("[^\\p{L}\\p{N}]+"), " ").trim()
            if (norm.isEmpty()) continue
            if (t.contains(" $norm ") && norm.length > bestLen) {
                bestLen = norm.length
                best = Match(r.category, r.ventureId, r.type, w)
            }
        }
        return best
    }
}
