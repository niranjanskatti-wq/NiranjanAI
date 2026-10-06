"""Computes Indian festival dates (2026-2030) from astronomy so the app ships
them offline. Rules follow the usual panchang conventions (Lahiri ayanamsa,
amanta months, tithi at the customary time of observance, Ujjain location).
Output: tools/content/festivals_computed.json (reviewed, then bundled)."""
import datetime as dt
import json
import math
import os
import ephem

IST = dt.timedelta(hours=5, minutes=30)
UJJAIN = ("23.1765", "75.7885")
KERALA = ("8.5241", "76.9366")
MONTHS = {0: "Chaitra", 1: "Vaishakha", 2: "Jyeshtha", 3: "Ashadha", 4: "Shravana", 5: "Bhadrapada",
          6: "Ashwin", 7: "Kartika", 8: "Margashirsha", 9: "Pausha", 10: "Magha", 11: "Phalguna"}


# Published panchangs shift Holika Dahan 2026 by a day because Bhadra covers
# the Purnima evening of 2 March; the plain tithi rule can't see that.
OVERRIDES = {2026: {"holi": "2026-03-04"}}


def ayanamsa(d):
    year = 2000 + (ephem.Date(d) - ephem.Date("2000/1/1")) / 365.25
    return 23.853 + (year - 2000) * 50.2788 / 3600.0


def lon(body, d):
    body.compute(d, epoch=d)
    return math.degrees(ephem.Ecliptic(body, epoch=d).lon)


def sid_sun(d):
    return (lon(ephem.Sun(), d) - ayanamsa(d)) % 360


def sid_moon(d):
    return (lon(ephem.Moon(), d) - ayanamsa(d)) % 360


def tithi(d):
    diff = (lon(ephem.Moon(), d) - lon(ephem.Sun(), d)) % 360
    return int(diff // 12) + 1


def utc(day, hours_ist):
    """ephem date for a civil IST date at given IST hour."""
    t = dt.datetime.combine(day, dt.time()) + dt.timedelta(hours=hours_ist) - IST
    return ephem.Date(t)


def observer(loc, day):
    o = ephem.Observer()
    o.lat, o.lon = loc
    o.elevation = 0
    o.date = utc(day, 0)
    return o


def sunrise(day, loc=UJJAIN):
    return observer(loc, day).next_rising(ephem.Sun())


def sunset(day, loc=UJJAIN):
    return observer(loc, day).next_setting(ephem.Sun())


def moonrise(day, loc=UJJAIN):
    o = observer(loc, day)
    o.date = utc(day, 12)
    return o.next_rising(ephem.Moon())


def to_ist_date(d):
    return (ephem.Date(d).datetime() + IST).date()


def lunar_months(year):
    out = []
    d = ephem.Date(f"{year - 1}/11/1")
    nms = []
    while d < ephem.Date(f"{year + 1}/2/1"):
        d = ephem.next_new_moon(d)
        nms.append(d)
        d = ephem.Date(d + 1)
    for a, b in zip(nms, nms[1:]):
        sa, sb = int(sid_sun(a) // 30), int(sid_sun(b) // 30)
        if sa == sb:
            continue  # adhik masa
        out.append((MONTHS[sb % 12], a, b))
    return out


def find_day(a, b, target, when, kshaya_prev=False):
    """First civil day whose tithi at the observance time is `target`
    (1-30, counted from the month's new moon). A tithi that never touches
    the observance time (kshaya) is observed on the day it ends, or on the
    day it began when `kshaya_prev` is set (Ugadi convention)."""
    day = to_ist_date(a)
    end = to_ist_date(b) + dt.timedelta(days=1)
    prev = None
    while day <= end:
        w = when(day)
        t = tithi(w)
        if t == 30 and w < a + 15:
            t = 0  # still the previous month's amavasya
        if t == 1 and w > a + 15:
            t = 31  # next month already started
        if t == target:
            return day
        if prev is not None and prev < target < t:
            return day - dt.timedelta(days=1) if kshaya_prev else day
        prev = t
        day += dt.timedelta(days=1)
    raise ValueError("not found")


def sankranti(year, sign_deg):
    lo, hi = ephem.Date(f"{year}/1/1"), ephem.Date(f"{year}/12/31")
    # coarse scan then bisect
    d = lo
    while d < hi:
        n = ephem.Date(d + 1)
        if (sid_sun(d) - sign_deg) % 360 > 300 and (sid_sun(n) - sign_deg) % 360 < 60:
            a, b = d, n
            for _ in range(40):
                m = ephem.Date((a + b) / 2)
                if (sid_sun(m) - sign_deg) % 360 > 300:
                    a = m
                else:
                    b = m
            day = to_ist_date(b)
            return day if b < sunset(day) else day + dt.timedelta(days=1)
        d = n
    raise ValueError


def onam(year):
    day = dt.date(year, 8, 1)
    while day < dt.date(year, 10, 1):
        sr = sunrise(day, KERALA)
        s = sid_sun(sr)
        m = sid_moon(sr)
        if 120 <= s < 150 and 280 <= m < 293.3334:
            return day
        day += dt.timedelta(days=1)
    raise ValueError


def compute(year):
    pradosh = lambda d: ephem.Date(sunset(d) + 1.5 / 24)
    noon = lambda d: utc(d, 12.5)
    aparahna = lambda d: utc(d, 14.5)
    f = {}
    a, b = [(x, y) for n, x, y in lunar_months(year) if n == "Phalguna" and to_ist_date(y).year == year][0]
    f["holi"] = find_day(a, b, 15, pradosh) + dt.timedelta(days=1)
    a, b = [(x, y) for n, x, y in lunar_months(year) if n == "Chaitra" and to_ist_date(x).year == year][0]
    f["ugadi"] = find_day(a, b, 1, sunrise, kshaya_prev=True)
    a, b = [(x, y) for n, x, y in lunar_months(year) if n == "Shravana" and to_ist_date(x).year == year][0]
    f["teej"] = find_day(a, b, 3, sunrise)
    a, b = [(x, y) for n, x, y in lunar_months(year) if n == "Bhadrapada" and to_ist_date(x).year == year][0]
    f["ganesh"] = find_day(a, b, 4, noon)
    a, b = [(x, y) for n, x, y in lunar_months(year) if n == "Ashwin" and to_ist_date(x).year == year][0]
    f["navratri"] = find_day(a, b, 1, sunrise)
    f["dussehra"] = find_day(a, b, 10, aparahna)
    f["karvachauth"] = find_day(a, b, 19, moonrise)
    f["diwali"] = find_day(a, b, 30, pradosh)
    f["sankranti"] = sankranti(year, 270)
    f["onam"] = onam(year)
    out = {k: v.isoformat() for k, v in f.items()}
    out.update(OVERRIDES.get(year, {}))
    return out


if __name__ == "__main__":
    res = {y: compute(y) for y in range(2026, 2031)}
    for y, v in res.items():
        print(y, v)
    here = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(here, "content", "festivals_computed.json"), "w") as fh:
        json.dump(res, fh, indent=1)
