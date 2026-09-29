"""Build assets/festivals/festivals.json from festival_dates.py.

Usage: python3 build_festivals.py 2026 2036
Hand corrections go in OVERRIDES below; they win over the calculation.
"""
import json
import os
import sys

from festival_dates import festivals_for

# id: (English, Hindi, Kannada, enabled by default, suggested relations, note)
LUNAR = {
    "makar_sankranti": ("Makar Sankranti", "मकर संक्रांति", "ಮಕರ ಸಂಕ್ರಾಂತಿ", True, [], "Solar: the day the Sun enters Capricorn (sidereal)."),
    "maha_shivaratri": ("Maha Shivaratri", "महाशिवरात्रि", "ಮಹಾ ಶಿವರಾತ್ರಿ", False, [], ""),
    "holika_dahan": ("Holika Dahan", "होलिका दहन", "ಹೋಳಿಕಾ ದಹನ", False, [], ""),
    "holi": ("Holi", "होली", "ಹೋಳಿ", True, [], "Day of colours (Dhulivandan)."),
    "ugadi": ("Ugadi / Gudi Padwa", "उगादी / गुड़ी पड़वा", "ಯುಗಾದಿ", True, [], ""),
    "ram_navami": ("Ram Navami", "राम नवमी", "ಶ್ರೀರಾಮ ನವಮಿ", True, [], ""),
    "hanuman_jayanti": ("Hanuman Jayanti", "हनुमान जयंती", "ಹನುಮ ಜಯಂತಿ", False, [], "Chaitra Purnima, as in Marathi calendars. Karnataka also observes Hanuma Jayanti in December."),
    "akshaya_tritiya": ("Akshaya Tritiya", "अक्षय तृतीया", "ಅಕ್ಷಯ ತೃತೀಯ", False, [], ""),
    "guru_purnima": ("Guru Purnima", "गुरु पूर्णिमा", "ಗುರು ಪೂರ್ಣಿಮೆ", False, ["mentor"], ""),
    "nag_panchami": ("Nag Panchami", "नाग पंचमी", "ನಾಗರ ಪಂಚಮಿ", False, [], ""),
    "varamahalakshmi": ("Varamahalakshmi Vrata", "वरलक्ष्मी व्रत", "ವರಮಹಾಲಕ್ಷ್ಮಿ ವ್ರತ", False, ["wife", "mother", "sister"], "Friday before Shravana Purnima."),
    "raksha_bandhan": ("Raksha Bandhan", "रक्षा बंधन", "ರಕ್ಷಾ ಬಂಧನ", True, ["sister", "brother", "cousin"], ""),
    "krishna_janmashtami": ("Krishna Janmashtami", "कृष्ण जन्माष्टमी", "ಶ್ರೀಕೃಷ್ಣ ಜನ್ಮಾಷ್ಟಮಿ", True, [], "Gokulashtami night; Dahi Handi is the next day."),
    "gowri_habba": ("Gowri Habba", "गौरी पूजा", "ಗೌರಿ ಹಬ್ಬ", False, ["wife", "mother", "sister"], "Day before Ganesh Chaturthi."),
    "ganesh_chaturthi": ("Ganesh Chaturthi", "गणेश चतुर्थी", "ಗಣೇಶ ಚತುರ್ಥಿ", True, [], ""),
    "anant_chaturdashi": ("Anant Chaturdashi", "अनंत चतुर्दशी", "ಅನಂತ ಚತುರ್ದಶಿ", False, [], "Ganesh visarjan."),
    "navratri_begins": ("Navratri begins", "नवरात्रि आरंभ", "ನವರಾತ್ರಿ ಆರಂಭ", False, [], "Ghatasthapana."),
    "vijayadashami": ("Dasara / Vijayadashami", "दशहरा / विजयादशमी", "ವಿಜಯದಶಮಿ (ದಸರಾ)", True, [], ""),
    "dhanteras": ("Dhanteras", "धनतेरस", "ಧನ ತ್ರಯೋದಶಿ", False, [], ""),
    "naraka_chaturdashi": ("Naraka Chaturdashi", "नरक चतुर्दशी", "ನರಕ ಚತುರ್ದಶಿ", False, [], "Abhyanga snan, early morning."),
    "diwali_lakshmi_puja": ("Diwali (Lakshmi Puja)", "दीपावली (लक्ष्मी पूजन)", "ದೀಪಾವಳಿ (ಲಕ್ಷ್ಮೀ ಪೂಜೆ)", True, [], "Marathi-calendar rule: can be a day later than North Indian calendars."),
    "balipratipada": ("Balipratipada / Padwa", "बलि प्रतिपदा / पाडवा", "ಬಲಿಪಾಡ್ಯಮಿ", False, ["wife", "husband"], ""),
    "bhai_dooj": ("Bhai Dooj / Bhau Beej", "भाई दूज", "ಯಮ ದ್ವಿತೀಯ / ಭಾಯಿ ದೂಜ್", False, ["sister", "brother"], ""),
}

# id: (English, Hindi, Kannada, enabled, month-day)
FIXED = {
    "new_year": ("New Year", "नया साल", "ಹೊಸ ವರ್ಷ", True, "01-01"),
    "republic_day": ("Republic Day", "गणतंत्र दिवस", "ಗಣರಾಜ್ಯೋತ್ಸವ", True, "01-26"),
    "independence_day": ("Independence Day", "स्वतंत्रता दिवस", "ಸ್ವಾತಂತ್ರ್ಯ ದಿನಾಚರಣೆ", True, "08-15"),
    "gandhi_jayanti": ("Gandhi Jayanti", "गांधी जयंती", "ಗಾಂಧಿ ಜಯಂತಿ", False, "10-02"),
    "kannada_rajyotsava": ("Kannada Rajyotsava", "कन्नड़ राज्योत्सव", "ಕನ್ನಡ ರಾಜ್ಯೋತ್ಸವ", False, "11-01"),
    "christmas": ("Christmas", "क्रिसमस", "ಕ್ರಿಸ್‌ಮಸ್", True, "12-25"),
}

# (festival id, year): (date, reason)
OVERRIDES = {
    ("holi", 2026): ("2026-03-04", "Colours were played on 4 March because of the lunar eclipse on 3 March."),
}

ORDER = ["new_year", "makar_sankranti", "republic_day", "maha_shivaratri", "holika_dahan", "holi",
         "ugadi", "ram_navami", "hanuman_jayanti", "akshaya_tritiya", "guru_purnima", "nag_panchami",
         "independence_day", "varamahalakshmi", "raksha_bandhan", "krishna_janmashtami", "gowri_habba",
         "ganesh_chaturthi", "anant_chaturdashi", "navratri_begins", "gandhi_jayanti", "vijayadashami",
         "dhanteras", "naraka_chaturdashi", "diwali_lakshmi_puja", "balipratipada", "bhai_dooj",
         "kannada_rajyotsava", "christmas"]


def build(y1, y2):
    computed = {y: festivals_for(y) for y in range(y1, y2 + 1)}
    out = []
    for fid in ORDER:
        if fid in FIXED:
            en, hi, kn, on, md = FIXED[fid]
            entry = {"id": fid, "name": {"en": en, "hi": hi, "kn": kn}, "type": "fixed",
                     "enabled": on, "suggest": [], "note": "",
                     "dates": {str(y): f"{y}-{md}" for y in computed}}
        else:
            en, hi, kn, on, suggest, note = LUNAR[fid]
            dates = {str(y): computed[y][fid] for y in computed}
            notes = []
            for (oid, y), (d, why) in OVERRIDES.items():
                if oid == fid and str(y) in dates:
                    dates[str(y)] = d
                    notes.append(f"{y}: {why}")
            entry = {"id": fid, "name": {"en": en, "hi": hi, "kn": kn},
                     "type": "solar" if fid == "makar_sankranti" else "lunar",
                     "enabled": on, "suggest": suggest, "note": " ".join([note] + notes).strip(),
                     "dates": dates}
        out.append(entry)
    return {
        "about": ("Festival dates in the Marathi almanac convention (as printed by the Mahalakshmi "
                  "calendar): amanta months, Lahiri ayanamsha, sunrise at Mumbai. Generated by "
                  "tools/build_festivals.py. You can edit any date here; the app also lets you "
                  "correct a date or switch a festival off from the Festivals screen."),
        "years": [y1, y2],
        "festivals": out,
    }


if __name__ == "__main__":
    y1, y2 = int(sys.argv[1]), int(sys.argv[2])
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "festivals", "festivals.json")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(build(y1, y2), f, ensure_ascii=False, indent=2)
        f.write("\n")
    print("wrote", os.path.normpath(path))
