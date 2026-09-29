# Smriti — Progress

## Current status
**Phase 0 · Design review** — waiting for approval. No app code written yet.
Platform: Android only (installed as an APK, no Play Store).

Design review (screen list, data model, design system, festival dates): `docs/design-review.html`

## Done
- Screen list (45 screens across 8 phases)
- Data model (people, events, couple links, reminders, wish history, messages, festivals, Wish Mode)
- Design system (colours, fonts, spacing, components, 4 sample screens)
- Festival dates 2026–2036 in the Mahalakshmi (Marathi almanac) convention
  - Calculator: `tools/festival_dates.py`, data-file builder: `tools/build_festivals.py`
  - Output: `assets/festivals/festivals.json` (29 festivals; 13 on by default)
  - Eid removed at user's request
  - Checked against Marathi calendars for 2024–2025 and published lists for 2026–2035

## Pending
- Approval of the design review
- Phase 1 onwards
- Festivals screen (Phase 5): edit any date, switch festivals on/off, add own festivals, reset an edit

## Known issues
- Mahalakshmi calendar websites are blocked from the build computer; dates were verified
  by calculation and other published lists. Worth comparing a few dates with the printed calendar.
- Android Studio is not yet installed on the Mac (only needed if building on the Mac).
