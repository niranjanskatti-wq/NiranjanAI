# Smriti — Progress

Platform: Android only (installed as an APK, no Play Store).
Design review: `docs/design-review.html` · Screenshots: `test/screenshots/` · Card designs: `docs/screens/cards.png`

## Current status
Building all phases in a row (your choice), testing everything on the phone at the end.
**All 8 phases built.** Next: your test on the phone.

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

### Phase 3 · Reminders & alarms
- Reminders page per event (one page, simple switches and times): midnight alarm, morning
  reminder, another time on the day, any number of days-before reminders (each with its own time),
  gift reminder, belated nudge, sound. Shortcuts: "Apply these reminders to…" (everyone or chosen
  people with the same kind of event) and "Copy reminders from another person"
- Midnight alarm: full screen even on the lock screen at 11:59:50 PM with a 10-second tick-tock and
  a chime at 12:00, confetti, big Call and Send wish, Snooze 10 min / 1 hour / morning, Dismiss.
  The app only shows over the lock screen for the alarm itself.
- Time zones: "My midnight" or "their midnight" for people abroad (daylight saving handled)
- Original sounds (made for Smriti, royalty-free): tick-tock, soft bell, temple bell, chime,
  birthday tune, vibration only — with a preview
- Notification buttons: Call and Send Wish (open the app straight into the call or share sheet),
  Snooze on the midnight alarm
- Belated nudge the next morning when an event wasn't marked as wished
- Monthly summary on the 1st at 9 AM listing that month's dates; tap opens the calendar
- Defaults for new events in Settings (morning reminder for people; 7 and 1 days before for
  important dates) · morning time setting · monthly summary switch · test alarm in 1 minute
- Reliability: exact alarms, reschedule after restart and app updates, background refresh twice a
  day, up to 450 alarms kept scheduled a year ahead · "Make alarms reliable" guide with steps for
  Xiaomi, Samsung, Vivo, Oppo, Realme, OnePlus, Motorola, Pixel, Honor and Huawei
- Bell icon on events with reminders · banner on Home if notifications are turned off
- 49 automatic tests (includes 11 for alarm timing, time zones, belated nudge, monthly summary, limits)

### Phase 4 · Message library
- 655 messages: 352 English, 151 Hindi, 152 Kannada, in `assets/messages/en.json`, `hi.json`, `kn.json`
  (editable). Organised by occasion (birthday, milestone birthday, anniversary, couple anniversary,
  work anniversary, engagement, congratulations, belated, festival, thank you, general), relationship
  family, tone (emotional, funny, short & sweet, formal, poetic, blessing) and language
- At least 15 birthday messages for every relationship family and 10+ for every festival that is on
  by default. Hindi and Kannada written in everyday texting style, gender-neutral where the sender
  or receiver could be anyone
- Messages tab: filter by occasion, relationship, tone, favourites, my messages; search; copy;
  favourite; edit (your edited copy replaces the original everywhere); "Write my own" with
  tap-to-insert placeholders and a live preview
- Prepared message per event (event page): pick from suggestions, "Surprise me", edit, save —
  Share uses it automatically on the day
- "Surprise me" in the Share sheet: a fitting message not yet sent to that person
- Your birthday: a banner on Home opens ready thank-you replies in English, Hindi or Kannada to send
  by WhatsApp, SMS or Copy
- 55 automatic tests (message coverage per relationship, occasion, language and festival)

### Phase 5 · Festivals & Wish Mode
- Festivals screen (Settings › Festivals): all 29 festivals with an on/off switch and next date;
  "Add my own festival" (same date every year, or dates that change each year)
- Festival page: next date, "Start Wish Mode", switch on/off, rename, change the date for any year
  (changed dates in bold, "Reset" puts back the calendar date), who to suggest in Wish Mode
  (e.g. siblings for Raksha Bandhan), delete your own festivals
- Switched-on festivals appear on Home with a countdown (and a Festivals filter), in the calendar and
  in search; festival reminder on the morning of the day (and optionally the evening before)
- Wish Mode for festivals: choose who (suggested relations, by stars, everyone, or pick people),
  then one person at a time with photo, name and a ready message in your language; WhatsApp, Text,
  Copy, Call, Change, Edit, Skip, Next; "12 of 40 wished" progress; Pause and continue from Home
- Wish Mode for today: "Start Wish Mode" on the Today banner goes through everyone celebrating today
- Sending from Wish Mode counts as wished straight away
- 61 automatic tests (festival dates, edits and resets, your own festivals, festival reminders,
  pausing and continuing Wish Mode)

### Phase 6 · Excel, backup, greeting cards, photo memories
- Export to Excel (Settings › Export, or the button on Calendar): one file with four sheets:
  All Events, By Month, People, Important Dates. Bold gold header row that stays in place,
  dd-mm-yyyy dates, filters on every column. Choose everyone, some people or by stars, a month or
  an event type, and leave out phone numbers or notes before sharing. Save to Downloads or share
- Import from Excel: add many people and dates at once, or move everything to a new phone from a
  Smriti export. Shows a preview first (ready / already in Smriti / problems, with the row number)
  and saves nothing until you confirm. A blank template with examples is one tap away
- Backup & restore: one .zip with everything (all data and photos) in Download › Smriti Backups.
  Automatic once a week; the newest 4 are kept. Share a backup to Google Drive for safe keeping.
  Restore from the list or from any file; a safety backup of the current data is made first
- Greeting cards: 28 designs (charcoal & gold, minimal, floral, rose, balloons, cake, confetti,
  watercolour, golden number and laurel for milestones, two rings and art deco for anniversaries,
  rangoli, marigold toran, temple arch, lotus, diyas, fireworks, Holi colours, kites, rakhi,
  dandiya, new sunrise, tiranga, Kannada colours, Christmas). The right designs come first for the
  day (kites for Sankranti, diyas for Diwali…). Tap to change the words; Hindi and Kannada work.
  Share as a picture or save to the Gallery. Open from the Share sheet or the event page
- Photo memories on each profile: add photos (several at once) under a year, see them year by year
  ("2025 · turned 61"), swipe through full screen, add captions, change the year, delete
- 69 automatic tests (Excel round trip, filters, template, backup/restore, card choices)

### Phase 7 · Groups, gift planner, widget, lock, phone calendar
- Groups (People › ⋮ › Groups, or Settings): Family, Office, College friends… with a colour. Add
  people from the group or from a profile ("Groups" card). Filter the People list by group, pick a
  group in Wish Mode, export one group to Excel; groups come back when importing a Smriti export
- Gift planner (People › ⋮ › Gift planner, or Settings): each idea can have a budget (₹) and the
  occasion it is for. The planner shows the next 30/60/90 days with the plan for each occasion
  ("No gift idea yet" when there is none), planned vs bought totals, and everything still to buy
- Home-screen widget (Settings › Home-screen widget, or long-press the home screen › Widgets):
  the next date large with days left, then the three after it. It counts the days itself, so it
  stays right even if Smriti isn't opened for a while. Tap it to open Smriti
- Fingerprint lock (Settings › Privacy & extras): your fingerprint or the phone's PIN opens Smriti.
  It locks again after 30 seconds away. The midnight alarm always shows, even when locked
- Phone calendar (Settings › Phone calendar): optionally copies birthdays, anniversaries and
  important dates into Google Calendar (or any calendar on the phone), repeating every year or month.
  Changes are copied over by themselves; switching off can remove them again
- 74 automatic tests (groups, gifts, widget dates, calendar items, upgrading an old database)

### Phase 8 · Polish and checks
- Speed check with 600 people and 900 dates: data loads in about 60 ms, the countdown list in
  under 20 ms, alarm planning under 0.2 s, a full Excel export under 0.3 s; screens scroll smoothly
- Search builds results as you scroll, so one-letter searches stay quick with hundreds of people
- Screenshots of every main screen in `test/screenshots/`; all 28 card designs in `docs/screens/`
- 76 automatic tests

## Phone test checklist (do these once the app is on your phone)
1. Open Smriti, enter your name, allow notifications and contacts when asked.
2. Settings › Reminders: follow "Make alarms reliable" for your phone brand (battery settings).
3. Add 5–10 people from contacts (People › ⋮ › Add many from contacts) and their birthdays.
4. Settings › Test the midnight alarm: lock the phone and wait 1 minute. It should ring with the
   full-screen alert. Try Snooze and Call.
5. Tap Share on someone: send a WhatsApp message, a text message, and a Greeting card picture.
6. Check the Diwali date in Festivals against your printed Mahalakshmi calendar.
7. Settings › Home-screen widget: add it and check the days left.
8. Settings › Fingerprint lock: switch on, leave the app for a minute, come back.
9. Settings › Backup & restore: tap "Back up now", then share the file to Google Drive.
10. Settings › Export to Excel: save the file and open it in Excel or Google Sheets.
Tell me anything that looks wrong or that you want changed; changes are easy from here.

## Pending
- Your phone test (checklist above), then any changes you want

## Known issues
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
