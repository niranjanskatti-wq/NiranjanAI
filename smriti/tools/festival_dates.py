"""Calculate Hindu festival dates the way Marathi almanac calendars
(Mahalakshmi, Kalnirnay, Date Panchang) do: amanta lunar months, sidereal
(Lahiri) solar months, local sunrise at Mumbai, and the classical rule for
which part of the day each festival's tithi must cover.

Usage: python3 festival_dates.py 2024 2036 > dates.json
Needs: pip install pyswisseph
"""
import json
import sys
from datetime import date, datetime, timedelta, timezone

import swisseph as swe

LAT, LON = 19.0760, 72.8777          # Mumbai
IST = timezone(timedelta(hours=5, minutes=30))
FLAGS = swe.FLG_MOSEPH               # built-in ephemeris, no data files needed
swe.set_sid_mode(swe.SIDM_LAHIRI)

MASAS = ["chaitra", "vaishakha", "jyeshtha", "ashadha", "shravana", "bhadrapada",
         "ashwin", "kartika", "margashirsha", "pausha", "magha", "phalguna"]


# ---------- astronomy ----------
def jd_of(dt):
    u = dt.astimezone(timezone.utc)
    return swe.julday(u.year, u.month, u.day, u.hour + u.minute / 60 + u.second / 3600)


def dt_of(jd):
    y, m, d, h = swe.revjul(jd)
    return datetime(y, m, d, tzinfo=timezone.utc) + timedelta(hours=h)


def lon(jd, body, sidereal=False):
    fl = FLAGS | (swe.FLG_SIDEREAL if sidereal else 0)
    return swe.calc_ut(jd, body, fl)[0][0]


def elong(jd):
    return (lon(jd, swe.MOON) - lon(jd, swe.SUN)) % 360


def tithi_at(jd):
    """0..29: 0-14 shukla pratipada..purnima, 15-29 krishna pratipada..amavasya."""
    return int(elong(jd) // 12)


def find_elong(jd_guess, target):
    """Moment near jd_guess when elongation equals target (degrees)."""
    jd = jd_guess
    for _ in range(50):
        diff = (elong(jd) - target + 180) % 360 - 180
        jd -= diff / 12.19               # mean relative speed deg/day
        if abs(diff) < 1e-7:
            break
    return jd


def tithi_bounds(jd):
    """Start and end moments of the tithi running at jd."""
    t = tithi_at(jd)
    e = elong(jd)
    start = find_elong(jd - (e - t * 12) / 12.19, t * 12)
    end = find_elong(jd + ((t + 1) * 12 - e) / 12.19, ((t + 1) * 12) % 360)
    return start, end


def sun_event(day, flag):
    start = jd_of(datetime(day.year, day.month, day.day, tzinfo=IST))
    return swe.rise_trans(start, swe.SUN, flag, (LON, LAT, 0), 1013.25, 25, FLAGS)[1][0]


def sunrise(day):
    return sun_event(day, swe.CALC_RISE)


def sunset(day):
    return sun_event(day, swe.CALC_SET)


def masa_at(jd):
    """(masa index, is_adhika) for the amanta month containing jd."""
    e = elong(jd)
    nm_prev = find_elong(jd - e / 12.19, 0)
    nm_next = find_elong(nm_prev + 29.6, 0)
    r1 = int(lon(nm_prev, swe.SUN, True) // 30)
    r2 = int(lon(nm_next, swe.SUN, True) // 30)
    return (r1 + 1) % 12, r1 == r2


# ---------- day windows ----------
def windows(day):
    sr, ss, nsr = sunrise(day), sunset(day), sunrise(day + timedelta(days=1))
    dm, night = ss - sr, nsr - ss
    return {
        "sunrise": (sr, sr + 1e-6),
        "arunodaya": (sr - 4 * dm / 30, sr - 3 * dm / 30),  # ~96 min before sunrise
        "madhyahna": (sr + 2 * dm / 5, sr + 3 * dm / 5),
        "aparahna": (sr + 3 * dm / 5, sr + 4 * dm / 5),
        "pradosh": (ss, ss + night / 5),
        "nishita": (ss + night * 7 / 15, ss + night * 8 / 15),
        "sunset": (ss, ss + 1e-6),
    }


def overlap(a, b):
    return max(0.0, min(a[1], b[1]) - max(a[0], b[0]))


def tithi_span(masa, tithi, year):
    """(start, end) of the given masa+tithi in a Gregorian year (non-adhika month)."""
    jd = jd_of(datetime(year, 1, 1, tzinfo=IST))
    end = jd_of(datetime(year + 1, 1, 15, tzinfo=IST))
    found = []
    while jd < end:
        if tithi_at(jd) == tithi:
            s, e = tithi_bounds(jd)
            m, adhika = masa_at((s + e) / 2)
            if m == masa and not adhika:
                found.append((s, e))
            jd = e + 20
        else:
            jd += 0.5
    return found


def local_date(jd):
    return dt_of(jd).astimezone(IST).date()


def pick(masa, tithi, year, window, prefer="first"):
    """Day on which the tithi covers `window`, applying prefer on ties.
    Falls back to the day the tithi is current at sunrise, then the day it starts."""
    results = []
    for s, e in tithi_span(masa, tithi, year):
        d0 = local_date(s) - timedelta(days=1)
        days = [d0 + timedelta(days=i) for i in range(4)]
        cover = [(d, overlap((s, e), windows(d)[window])) for d in days]
        hits = [d for d, o in cover if o > 0]
        if hits:
            if prefer == "max":
                best = max(cover, key=lambda x: x[1])[0]
            else:
                best = hits[0] if prefer == "first" else hits[-1]
        else:
            at_sr = [d for d in days if s <= sunrise(d) < e]
            best = at_sr[0] if at_sr else local_date(s)
        if best.year == year:
            results.append(best)
    return results


# ---------- festival rules ----------
S = lambda n: n - 1            # shukla tithi n (1..15)
K = lambda n: 14 + n           # krishna tithi n (1..15, 15 = amavasya)
M = {name: i for i, name in enumerate(MASAS)}


def makar_sankranti(year):
    jd = jd_of(datetime(year, 1, 5, tzinfo=IST))
    for _ in range(60):
        diff = (lon(jd, swe.SUN, True) - 270 + 180) % 360 - 180
        jd -= diff / 1.0146
        if abs(diff) < 1e-8:
            break
    d = local_date(jd)
    return d + timedelta(days=1) if jd > sunset(d) else d


def raksha_bandhan(year):
    return sunrise_or_day_before(M["shravana"], S(15), year)


def second_day_if_long(masa, tithi, year, fraction, window):
    """Dharmasindhu rule used by Marathi almanacs for Lakshmi Puja and Holika
    Dahan: take the second day when the tithi is current at its sunrise and
    lasts beyond `fraction` of the daytime (3.5 prahar = 0.875, 3 prahar = 0.75);
    otherwise the day on which the tithi covers `window`."""
    out = []
    for s, e in tithi_span(masa, tithi, year):
        d = local_date(s)
        chosen = None
        for cand in (d + timedelta(days=1), d + timedelta(days=2)):
            sr = sunrise(cand)
            if s <= sr < e:
                if e >= sr + fraction * (sunset(cand) - sr):
                    chosen = cand
                break
        out.append(chosen or pick(masa, tithi, year, window)[0])
    return out


def sunrise_or_day_before(masa, tithi, year):
    """Day the tithi is current at sunrise if it lasts 6 ghatis (2 h 24 m)
    after sunrise; otherwise the day before (used for purvahna festivals)."""
    out = []
    for s, e in tithi_span(masa, tithi, year):
        d = local_date(s)
        for cand in (d, d + timedelta(days=1)):
            sr = sunrise(cand)
            if s <= sr < e:
                out.append(cand if e - sr >= 0.1 else cand - timedelta(days=1))
                break
        else:
            out.append(d)
    return out


def one(lst):
    return lst[0].isoformat() if lst else None


def festivals_for(year):
    lp = second_day_if_long(M["ashwin"], K(15), year, 0.875, "pradosh")[0]
    holika = second_day_if_long(M["phalguna"], S(15), year, 0.875, "pradosh")[0]
    rb = raksha_bandhan(year)[0]
    vm = rb - timedelta(days=(rb.weekday() - 4) % 7 or 7)     # Friday before
    ganesh = pick(M["bhadrapada"], S(4), year, "madhyahna", "max")[0]
    return {
        "makar_sankranti": makar_sankranti(year).isoformat(),
        "maha_shivaratri": one(pick(M["magha"], K(14), year, "nishita")),
        "holika_dahan": holika.isoformat(),
        "holi": (holika + timedelta(days=1)).isoformat(),
        "ugadi": one(pick(M["chaitra"], S(1), year, "sunrise")),
        "ram_navami": one(pick(M["chaitra"], S(9), year, "madhyahna", "max")),
        "hanuman_jayanti": one(pick(M["chaitra"], S(15), year, "sunrise")),
        "akshaya_tritiya": one(sunrise_or_day_before(M["vaishakha"], S(3), year)),
        "guru_purnima": one(pick(M["ashadha"], S(15), year, "sunrise")),
        "nag_panchami": one(pick(M["shravana"], S(5), year, "sunrise")),
        "varamahalakshmi": vm.isoformat(),
        "raksha_bandhan": rb.isoformat(),
        "krishna_janmashtami": one(pick(M["shravana"], K(8), year, "nishita")),
        "gowri_habba": (ganesh - timedelta(days=1)).isoformat(),
        "ganesh_chaturthi": ganesh.isoformat(),
        "anant_chaturdashi": one(pick(M["bhadrapada"], S(14), year, "sunrise")),
        "navratri_begins": one(pick(M["ashwin"], S(1), year, "sunrise")),
        "vijayadashami": one(pick(M["ashwin"], S(10), year, "aparahna")),
        "dhanteras": one(pick(M["ashwin"], K(13), year, "pradosh", "last")),
        "naraka_chaturdashi": one(pick(M["ashwin"], K(14), year, "arunodaya")),
        "diwali_lakshmi_puja": lp.isoformat(),
        "balipratipada": one(pick(M["kartika"], S(1), year, "sunrise")),
        "bhai_dooj": one(pick(M["kartika"], S(2), year, "sunrise")),
    }


if __name__ == "__main__":
    y1, y2 = int(sys.argv[1]), int(sys.argv[2])
    print(json.dumps({y: festivals_for(y) for y in range(y1, y2 + 1)}, indent=1))
