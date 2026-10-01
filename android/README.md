# Essential — *Less, but better.*

An offline-first Android planner, hourly tracker and productivity system for a solo entrepreneur
running several ventures (real estate, astrology, MCX trading, apps, new ideas).

**Install:** copy `release/Essential.apk` to your phone and open it (allow "Install unknown apps"
for your file manager when Android asks). Android 10 or newer. No Play Store, no account, no internet.

## What's inside

| Stage | Features |
|---|---|
| **Explore** | One 90-day Essential Intent (+ up to 2 supporting goals, max 3), milestones, goal pace; Opportunity filter (<90 → Not Now, reviewed monthly); Play & Think Time; monthly Uncommit review |
| **Eliminate** | "No" log + polite decline scripts (English & ಕನ್ನಡ, copy/share); weekly obstacle; distraction counter (Home, widget, Quick Settings tile) |
| **Execute** | Hourly check-ins with one-tap **As planned / Essential / Trivial**, inline **Reply** and **Snooze**; full log sheet (2–3 taps), "Same as last hour", "Log missed hours", offline voice logging with keyword rules; Plan vs Actual; Normal/Max Mode templates with the 24-hour trade-off rule and protected blocks; sprints (≤6 weeks) + recovery week + burnout check; Focus mode (25/50/90, DND, interruption tracking, auto-logged as Essential); habits & streaks; sleep; MCX trading journal with required checklist and revenge-trade guard; buffer/estimate tracking; daily review |
| **Insights** | Essential Hours chart with target, working hours, E/N/T split, plan-follow trend, Golden Hours, time vs ₹ by venture (low-return flag), Daily Score heatmap, off-plan & distraction reasons, Normal vs Max, goal pace; Daily Score (editable weights); rule-based weekly report (<200 words, share as image) |
| **Everywhere** | Exact Doze-proof alarms re-armed after reboot/update/time-zone change; brand-specific battery/autostart help (Xiaomi, Vivo, Oppo, Realme, OnePlus, Samsung, Motorola); permission banner; widgets (small + medium); Quick Settings tiles; app shortcuts; JSON backup/restore, weekly auto-backup to a chosen folder, CSV export; dark (default) + light; IST and 12-hour time; 14 days of sample data with "Clear sample data" |

Screenshots (rendered from the real app by the test-suite) are in `docs/screenshots/`.

## Build & test

```bash
./build.sh   # → release/Essential.apk (signed with keystore/essential.jks)
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
