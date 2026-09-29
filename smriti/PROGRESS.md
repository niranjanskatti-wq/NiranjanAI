# Smriti — Progress

Platform: Android only (installed as an APK, no Play Store).
Design review: `docs/design-review.html` · Screenshots: `test/screenshots/`

## Current status
Building all phases in a row (your choice), testing everything on the phone at the end.
**Phase 2 · Call, Share, Send wishes to, wish history** — built.

## Done
### Phase 0 · Design (approved)
- Screen list, data model, design system
- Festival dates 2026–2036 in the Mahalakshmi (Marathi almanac) convention, Eid removed
  (`tools/festival_dates.py`, `tools/build_festivals.py` → `assets/festivals/festivals.json`)

### Phase 1 · People, events, countdown
- Welcome screen: your name, your birthday and anniversary
- Home: live countdown card for the next event (animated digits), "Turning 60!" and milestone
  badges, filter chips (Today / This week / This month / All · People / Important dates),
  upcoming list with stars and days left, confetti and a Today banner on the day
- People: list sorted by name, stars or next date; filters by relationship and stars
- Person profile: photo, nickname, relationship, stars, events, gift ideas (with "purchased"),
  numbers, birth year, time zone, notes, likes, dislikes, clothing size, favourite sweets
- Add / edit person: "Pick from contacts" (name, photo, numbers, birthday and anniversary filled in),
  choose call and WhatsApp numbers when a contact has several, link to a different contact, unlink
- Add many people from contacts at once, then add their dates in one list
- Import birthdays and anniversaries saved in contacts, with duplicate detection
- Contact sync: when a number changes in your contacts, Smriti updates it (or tells you, if you
  typed that number yourself) and shows a small notice on Home
- Events: person, couple (two people) and important dates (insurance, vehicle service, passport,
  licence, bill, policy, rent, subscription, other) · repeat yearly, monthly or once · own stars
  · 29 Feb choice (28 Feb or 1 Mar) · notes
- Calendar: month grid with coloured dots; tap a day to see its events
- Search by name, nickname, relationship, event title or notes
- Archive and restore people; delete people and events
- Settings: your details, light / dark / phone setting, contacts tools
- Automatic tests (28): dates, 29 Feb, 31st-of-month, one-time events, milestones,
  phone numbers with or without +91 / 0 / spaces, couples, archiving, first launch, home screen
- App icon, charcoal splash screen, GitHub build that publishes the APK as a release

### Phase 2 · Call, Share, wish history
- Call button: dials directly (asks once for permission; falls back to the dialler)
- Share sheet: message preview, Change message, Edit (with "Save for this event"), language choice,
  WhatsApp (asks WhatsApp or WhatsApp Business once if both are installed), Text message, Copy,
  and More: WhatsApp group, Telegram, Email, other apps
- Call and Share on the home hero card, every upcoming row, the Today banner, event pages,
  person profiles and the "Not wished" list
- "Send wishes to" per event (under More options): Call and Share use that person's number,
  while the message still uses the event person's name
- Couple events: choose which of the two to call or message
- Every call and share is logged; a small "Mark … as wished?" chip appears afterwards (never blocks)
- "Wished" switch on each event page · "Missed this week" section on Home with belated wishes
- Wish history on each profile (swipe to delete an entry) · "Not wished in 12+ months" list
- Message engine with placeholders {name} {nickname} {age} {age_th} {relation} {years_married}
  {years_th} {couple_names} {festival} {my_name}; avoids repeating messages already sent
- Starter English messages (full library comes in Phase 4) · 39 automatic tests

## Pending
- Phase 3: Reminders and alarms · Phase 4: Messages · Phase 5: Festivals & Wish Mode
- Phase 6: Excel, backup, cards, photo memories · Phase 7: Widget, gifts planner, groups, lock
- Phase 8: Polish and full phone test
- Festivals screen (Phase 5): edit any date, switch festivals on/off, add your own, reset an edit

## Known issues
- Call and Share buttons are not in this build yet (Phase 2); the hero card says so.
- The two signing secrets must be added on GitHub before the build you keep using. A build made
  without them uses a temporary key, and switching keys later means uninstalling the app once.
- Mahalakshmi calendar websites were blocked from the build computer; festival dates were verified
  by calculation and other published lists. Worth comparing a few with the printed calendar.

## How to install on your phone
1. On your Android phone, open
   https://github.com/niranjanskatti-wq/NiranjanAI/releases
2. Open the newest "Smriti · build N" and tap the `.apk` file under **Assets**.
3. When the download finishes, tap it. If asked, allow your browser to "Install unknown apps".
4. Tap **Install**, then **Open**.
For later builds, repeat the same steps; Android updates the app and keeps your data.
