# Abhyasa (अभ्यास) — *Less, but better.*

*Abhyāsa*: steady, repeated practice (Yoga Sutra 1.12–1.14) — the essential thing, done daily until it becomes effortless.

An offline-first Android planner, hourly tracker, habit-chain tracker and productivity system.
Nothing is pre-filled with names: you add your own activities and habits — as many as you like.

**Personal use only — not for commercial purposes.** Built for one person's own phone; not published
on any store. (Bundled Inter font is under the SIL Open Font License; see `app/src/main/assets/fonts/OFL.txt`.)

**Install:** copy `release/Abhyasa.apk` (the app installs as **Abhyasa**) to your phone and open it (allow "Install unknown apps"
for your file manager when Android asks). Android 10 or newer. No Play Store, no account, no internet.

## What's inside

| Stage | Features |
|---|---|
| **Explore** | One 90-day Essential Intent (+ up to 2 supporting goals, max 3), milestones, goal pace; Opportunity filter (<90 → Not Now, reviewed monthly); Play & Think Time; monthly Uncommit review |
| **Eliminate** | "No" log + polite decline scripts (English & ಕನ್ನಡ, copy/share); weekly obstacle; distraction counter (Home, widget, Quick Settings tile) |
| **Habits** | Its own tab: add, rename, recolour, reorder, pause or delete any habit (Walking and Meditation to start, plus one-tap ideas). Tick today with one tap; each habit shows a chain of the last 14 days and a month calendar where unbroken days join into one continuous chain and missed days stay empty. Current chain, best chain, days done, monthly % |
| **Execute** | Hourly check-ins with one-tap **As planned / Essential / Trivial**, inline **Reply** and **Snooze**; full log sheet (2–3 taps), "Same as last hour", "Log missed hours", offline voice logging with keyword rules; Plan vs Actual; Normal/Max Mode templates with the 24-hour trade-off rule and protected blocks; sprints (≤6 weeks) + recovery week + burnout check; Focus mode (25/50/90, DND, interruption tracking, auto-logged as Essential); habits & streaks; sleep; buffer/estimate tracking; daily review |
| **Insights** | Essential Hours chart with target, working hours, E/N/T split, plan-follow trend, Golden Hours, time vs ₹ by venture (low-return flag), Daily Score heatmap, off-plan & distraction reasons, Normal vs Max, goal pace; Daily Score (editable weights); rule-based weekly report (<200 words, share as image) |
| **Everywhere** | Exact Doze-proof alarms re-armed after reboot/update/time-zone change; brand-specific battery/autostart help (Xiaomi, Vivo, Oppo, Realme, OnePlus, Samsung, Motorola); permission banner; widgets (small + medium); Quick Settings tiles; app shortcuts; JSON backup/restore, weekly auto-backup to a chosen folder, CSV export (hour logs, reviews, habits, sleep); dark (default) + light; IST and 12-hour time; 14 days of sample data with "Clear sample data" |

Screenshots (rendered from the real app by the test-suite) are in `docs/screenshots/`.

For updating this app years from now, see **MAINTENANCE.md**.

## Build & test

```bash
./build.sh   # → release/Abhyasa.apk (signed with keystore/essential.jks)
./test.sh    # 46 JVM tests: pure logic + Robolectric (real app on simulated Android 14)
```

`build.sh` needs no Android SDK manager or Gradle: it uses Ubuntu's `aapt2`, `dx`, `zipalign`,
`apksigner`, the Android 14 framework jar from Maven Central, and Kotlin 1.9.24.
The folder is also a standard Gradle project (`settings.gradle.kts`) for Android Studio.

The sideload keystore is committed on purpose so every build can update the installed app
without losing data. Keep using it (or the same replacement) for future versions.

## Architecture

- `data/` — SQLite schema (every table has `updated_at` / `is_sample`), `Repo`, typed `Settings`, defaults (`Seed`)
- `core/` — pure logic: time & day boundary, timeline/trade-off rule, metrics & Daily Score, insights,
  weekly report (`Coach`), voice classifier (`ActivityParser`), focus, logging, backup, sample data
- `notify/` — channels, notifications, `Planner` (all reminders) + `Alarms` (always arms only the next one)
- `ui/` — single activity, hand-built Material 3 components, charts, screens; `widget/` — widgets & tiles

**Future online features** (not built): cloud sync implements `sync.SyncProvider`; an AI coach implements
`core.Coach`; AI voice parsing implements `core.ActivityParser`. Defaults are local-only and the
app has no `INTERNET` permission, so it always works fully offline.

## Changes in 1.1.0

- Trading removed completely (journal, checklist, guard, hard-stop reminder, P&L in reports, "Log trade" shortcut,
  Trading venture, habit and keyword rule). The evening trading blocks became **Astrology consultations** and
  **family time** (editable in Templates). Installing over 1.0 migrates the data automatically.

## Changes in 1.2.0

- Renamed to **Abhyasa** (same package, so it installs over the old version and keeps your data).
- No pre-filled names: default activities, keyword rules and commitments are gone; template blocks are generic.
  Add as many **activities** as you like (Tools → My activities, or "+ Add activity" right in the log sheet).
- New **Habits** tab with daily ticks, chain strips and a calendar per habit; fully customisable.
- **Bottom tabs** can be shown or hidden in Settings (Settings itself always stays).

## Changes in 1.2.1

- Renamed to **Abhyasa** (अभ्यास, steady daily practice). Installs over earlier versions and keeps your data.

## Changes in 1.2.2

- Setup is fully optional: **Skip setup** on every step, a **Choose your tabs** step, and the main goal is optional.
- Sample data is off by default.

## Changes in 1.3.0

- Habits can count an amount (optional): **minutes**, **pages** (linked to your books), a **count**, or **your own unit** (rounds, km, glasses…), with an optional daily target.
- **Books**: add each book with total pages; pages you log move it forward and show pages left; finished books are marked automatically.
- **Totals** per habit (optional): today, week, month, year, all time, average, and a monthly chart (hours per month for minutes).
- Starter habits: Walking, Meditation, Reading, Pranayam, Full breathing (fast) at night. All editable, deletable, and you can add any others.
- CSV export adds habit_amounts.csv and books.csv.
