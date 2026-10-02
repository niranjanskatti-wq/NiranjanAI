"""Karnataka bank holidays (Negotiable Instruments Act list, as banks in
Bengaluru follow it) for the Business calendar.

Hindu festival days use the same almanac rules as festival_dates.py; Muslim
festivals use the tabular Islamic calendar, which matched India's 2025 dates
(Eid 31 Mar, Bakrid 7 Jun, Muharram 6 Jul, Milad 5 Sep) but can move a day
with the moon sighting. Sundays and 2nd/4th Saturdays are worked out in the
app, not listed here.

Usage: python3 build_bank_holidays.py 2026 2036 > ../assets/holidays/karnataka_bank.json
"""
import json
import sys
from datetime import date, timedelta

from festival_dates import K, M, S, festivals_for, one, pick


def hijri(y, m, d):
    jd = d + int(29.5 * (m - 1) + 0.99) + (y - 1) * 354 + (3 + 11 * y) // 30 + 1948439.5 - 1
    return date.fromordinal(int(jd + 0.5 - 1721424.5))


def islamic_in(year, month, day):
    """Gregorian dates in `year` of the given Islamic month/day."""
    hy = year - 579
    return [d for d in (hijri(h, month, day) for h in range(hy - 1, hy + 2)) if d.year == year]


def easter(y):
    a, b, c = y % 19, y // 100, y % 100
    d, e = b // 4, b % 4
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i, k = c // 4, c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) // 451
    month = (h + l - 7 * m + 114) // 31
    return date(y, month, (h + l - 7 * m + 114) % 31 + 1)


def holidays(year):
    f = festivals_for(year)
    iso = date.fromisoformat
    vd = iso(f["vijayadashami"])
    out = [
        (f["makar_sankranti"], "Makara Sankranti", False),
        (f"{year}-01-26", "Republic Day", False),
        (f["maha_shivaratri"], "Maha Shivaratri", False),
        (f["ugadi"], "Ugadi", False),
        (f"{year}-04-01", "Bank closing of accounts (banks only)", False),
        (one(pick(M["chaitra"], S(13), year, "sunrise")), "Mahaveer Jayanti", False),
        ((easter(year) - timedelta(days=2)).isoformat(), "Good Friday", False),
        (f"{year}-04-14", "Dr. B.R. Ambedkar Jayanti", False),
        (f["akshaya_tritiya"], "Basava Jayanti / Akshaya Tritiya", False),
        (f"{year}-05-01", "May Day", False),
        (f"{year}-08-15", "Independence Day", False),
        (f["ganesh_chaturthi"], "Varasiddhi Vinayaka Vrata (Ganesh Chaturthi)", False),
        (one(pick(M["bhadrapada"], K(15), year, "aparahna")), "Mahalaya Amavasya", False),
        (f"{year}-10-02", "Gandhi Jayanti", False),
        ((vd - timedelta(days=1)).isoformat(), "Mahanavami / Ayudha Puja", False),
        (vd.isoformat(), "Vijayadashami", False),
        (one(pick(M["ashwin"], S(15), year, "sunrise")), "Maharshi Valmiki Jayanti", False),
        (f["naraka_chaturdashi"], "Naraka Chaturdashi", False),
        (f["balipratipada"], "Balipadyami, Deepavali", False),
        (f"{year}-11-01", "Kannada Rajyotsava", False),
        (one(pick(M["kartika"], K(3), year, "sunrise")), "Kanakadasa Jayanti", False),
        (f"{year}-12-25", "Christmas", False),
    ]
    for d in islamic_in(year, 10, 1):
        out.append((d.isoformat(), "Khutub-E-Ramzan (Eid ul-Fitr)", True))
    for d in islamic_in(year, 12, 10):
        out.append((d.isoformat(), "Bakrid (Eid ul-Adha)", True))
    for d in islamic_in(year, 1, 10):
        out.append((d.isoformat(), "Last day of Muharram", True))
    for d in islamic_in(year, 3, 12):
        out.append((d.isoformat(), "Eid-e-Milad", True))
    return sorted({(d, n, a) for d, n, a in out if d})


if __name__ == "__main__":
    y1, y2 = int(sys.argv[1]), int(sys.argv[2])
    data = {
        "about": "Karnataka bank holidays. Dates for moon-based festivals are worked out from the almanac and can "
                 "differ by a day from the official notification; Muslim festival dates depend on the moon sighting. "
                 "You can add, rename or remove any holiday in the app. Sundays and 2nd/4th Saturdays are added by the app.",
        "years": [y1, y2],
        "holidays": [
            {"date": d, "name": n, **({"approx": True} if a else {})}
            for y in range(y1, y2 + 1) for d, n, a in holidays(y)
        ],
    }
    json.dump(data, sys.stdout, ensure_ascii=False, indent=1)
    print()
