"""Builds the app's bundled offline content from the plain-text sources in
tools/content. Run after editing any source file:  python3 tools/build_content.py
Fails loudly if a count drifts from the spec."""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "content")
OUT = os.path.join(HERE, "..", "app", "src", "main", "assets")

CATEGORIES = [  # (file, display name, required count)
    ("good_morning", "Good Morning", 110),
    ("good_night", "Good Night", 110),
    ("flirty", "Flirty", 120),
    ("romantic", "Romantic", 120),
    ("appreciation", "Appreciation", 100),
    ("missing_you", "Missing You", 100),
    ("playful_tease", "Playful Tease", 80),
    ("supportive", "Supportive", 80),
    ("apology", "Apology", 40),
    ("anniversary", "Anniversary", 40),
    ("birthday", "Birthday", 40),
    ("festivals", "Festivals and Special Days", 60),
    # Appended last so the ids of the original 1000 never change (favourites/history refer to them).
    ("long_messages", "Long Messages", 100),
]
SHORT_TOTAL = 1000

FESTIVAL_NAMES = {
    "sankranti": "Makar Sankranti / Pongal",
    "holi": "Holi",
    "ugadi": "Ugadi / Gudi Padwa",
    "teej": "Hariyali Teej",
    "onam": "Onam",
    "ganesh": "Ganesh Chaturthi",
    "navratri": "Navratri begins",
    "dussehra": "Dussehra",
    "karvachauth": "Karva Chauth",
    "diwali": "Diwali",
}
FIXED = [("01-01", "newyear", "New Year's Day"), ("02-14", "valentines", "Valentine's Day"),
         ("03-08", "womensday", "Women's Day"), ("12-25", "christmas", "Christmas"),
         ("12-31", "newyear", "New Year's Eve")]


def lines(path):
    with open(path, encoding="utf-8") as fh:
        return [ln.strip() for ln in fh if ln.strip()]


def fail(msg):
    sys.exit("build_content: " + msg)


def main():
    messages, seen = [], set()
    for fname, name, count in CATEGORIES:
        rows = lines(os.path.join(SRC, "messages", fname + ".txt"))
        if len(rows) != count:
            fail(f"{fname}: expected {count} messages, found {len(rows)}")
        for row in rows:
            tag = theme = None
            if fname == "festivals":
                tag, row = row.split("|", 1)
            if fname == "long_messages":
                theme, row = row.split("|", 1)
                if theme not in {c[1] for c in CATEGORIES}:
                    fail("unknown long-message theme: " + theme)
                row = row.replace("\\n", "\n")
            if row in seen:
                fail("duplicate message: " + row)
            seen.add(row)
            msg = {"id": len(messages) + 1, "c": name, "t": row}
            if tag:
                msg["f"] = tag
            if theme:
                msg["th"] = theme
            messages.append(msg)
    if len(messages) != SHORT_TOTAL + 100:
        fail(f"expected {SHORT_TOTAL + 100} messages, found {len(messages)}")

    moves = lines(os.path.join(SRC, "moves.txt"))
    if len(moves) != 100 or len(set(moves)) != 100:
        fail("expected 100 unique daily moves")

    gifts = []
    for row in lines(os.path.join(SRC, "gifts.txt")):
        title, desc, budget, occasions, kind = row.split("|")
        assert budget in ("u500", "b500_2000", "b2000_5000", "a5000"), row
        occ = occasions.split(",")
        assert set(occ) <= {"justbecause", "birthday", "anniversary", "apology", "festival"}, row
        assert kind in ("experience", "gesture", "gift"), row
        gifts.append({"id": len(gifts) + 1, "title": title, "desc": desc, "budget": budget,
                      "occasions": occ, "kind": kind})
    if len(gifts) != 150 or len({g["title"] for g in gifts}) != 150:
        fail("expected 150 unique gift ideas")

    with open(os.path.join(SRC, "festivals_computed.json")) as fh:
        computed = json.load(fh)
    festivals = []
    for year in range(2026, 2031):
        for key, date in computed[str(year)].items():
            festivals.append({"date": date, "key": key, "name": FESTIVAL_NAMES[key]})
        for md, key, name in FIXED:
            festivals.append({"date": f"{year}-{md}", "key": key, "name": name})
    festivals.sort(key=lambda f: f["date"])

    os.makedirs(OUT, exist_ok=True)
    for name, data in (("messages", messages), ("moves", moves), ("gifts", gifts), ("festivals", festivals)):
        with open(os.path.join(OUT, name + ".json"), "w", encoding="utf-8") as fh:
            json.dump(data, fh, ensure_ascii=False, separators=(",", ":"))
    print(f"ok: {len(messages)} messages, {len(moves)} moves, {len(gifts)} gifts, {len(festivals)} festival dates")


if __name__ == "__main__":
    main()
