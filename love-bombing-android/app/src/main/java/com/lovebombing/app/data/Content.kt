package com.lovebombing.app.data

import android.content.Context
import org.json.JSONArray
import java.time.LocalDate

data class Message(
    val id: Int,
    val category: String,
    val text: String,
    val festivalKey: String?,
    /** For long messages: the short category it belongs with (e.g. "Good Morning"). */
    val theme: String? = null,
) {
    val isLong get() = category == Content.LONG_CATEGORY
}

data class Gift(
    val id: Int,
    val title: String,
    val desc: String,
    val budget: Budget,
    val occasions: List<Occasion>,
    val kind: String,
)

data class Festival(val date: LocalDate, val key: String, val name: String)

enum class Budget(val key: String, val label: String) {
    UNDER_500("u500", "Under ₹500"),
    FROM_500("b500_2000", "₹500–2000"),
    FROM_2000("b2000_5000", "₹2000–5000"),
    ABOVE_5000("a5000", "₹5000+");

    companion object {
        fun of(key: String) = entries.first { it.key == key }
    }
}

enum class Occasion(val key: String, val label: String) {
    JUST_BECAUSE("justbecause", "Just because"),
    BIRTHDAY("birthday", "Birthday"),
    ANNIVERSARY("anniversary", "Anniversary"),
    APOLOGY("apology", "Apology"),
    FESTIVAL("festival", "Festival");

    companion object {
        fun of(key: String) = entries.first { it.key == key }
    }
}

/** Read-only content bundled in assets/. Loaded once, kept in memory (~150 KB). */
class Content private constructor(context: Context) {
    val messages: List<Message>
    val moves: List<String>
    val gifts: List<Gift>
    val festivals: List<Festival>
    val categories: List<String>
    private val byId: Map<Int, Message>

    init {
        val assets = context.assets
        fun read(name: String) = JSONArray(assets.open(name).bufferedReader().use { it.readText() })

        val m = read("messages.json")
        messages = List(m.length()) { i ->
            val o = m.getJSONObject(i)
            Message(
                o.getInt("id"), o.getString("c"), o.getString("t"),
                o.optString("f").ifEmpty { null }, o.optString("th").ifEmpty { null },
            )
        }
        byId = messages.associateBy { it.id }
        categories = messages.map { it.category }.distinct()

        val mv = read("moves.json")
        moves = List(mv.length()) { mv.getString(it) }

        val g = read("gifts.json")
        gifts = List(g.length()) { i ->
            val o = g.getJSONObject(i)
            val occ = o.getJSONArray("occasions")
            Gift(
                id = o.getInt("id"),
                title = o.getString("title"),
                desc = o.getString("desc"),
                budget = Budget.of(o.getString("budget")),
                occasions = List(occ.length()) { Occasion.of(occ.getString(it)) },
                kind = o.getString("kind"),
            )
        }

        val f = read("festivals.json")
        festivals = List(f.length()) { i ->
            val o = f.getJSONObject(i)
            Festival(LocalDate.parse(o.getString("date")), o.getString("key"), o.getString("name"))
        }
    }

    fun message(id: Int?): Message? = id?.let { byId[it] }

    fun moveFor(day: LocalDate): String = moves[Math.floorMod(day.toEpochDay(), moves.size.toLong()).toInt()]

    companion object {
        const val FESTIVAL_CATEGORY = "Festivals and Special Days"
        const val LONG_CATEGORY = "Long Messages"

        @Volatile private var instance: Content? = null

        fun get(context: Context): Content = instance ?: synchronized(this) {
            instance ?: Content(context.applicationContext).also { instance = it }
        }
    }
}

/** Replaces the {name} placeholder; falls back to a neutral word if no name is saved. */
fun personalize(text: String, name: String): String =
    text.replace("{name}", name.trim().ifEmpty { "love" })
