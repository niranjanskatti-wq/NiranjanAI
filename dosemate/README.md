# DoseMate

A personal medicine and skin-care reminder app for Android, with real alarms. Built with
Kotlin, Jetpack Compose, Material 3, Room and Hilt.

- Android 8.0 (API 26) through Android 16 (API 36)
- Everything stays on the phone: there is no login and no account, and the app has no
  `INTERNET` permission
- No ads, no tracking, no analytics

## Features

| Area | What you get |
|---|---|
| **Today** | Timeline grouped by Morning / Afternoon / Evening / Night, big tap-to-mark-taken cards, a live countdown to the next dose, a daily progress ring, a missed-dose summary, the one-time Forcan banner and the diet note |
| **Medicines** | Course progress bars ("Day 5 of 21"), days remaining, low-stock, paused and linked badges, archived courses |
| **Medicine editor** | Name, type, colour, icon, private photo, dose and unit, food timing, instructions, notes, warning, one-time banner. Schedules: daily, specific weekdays, every X days, weekly, X times a day, or custom times. Course length: end date, number of days, number of doses, or ongoing. Linked gap rule, per-medicine and per-dose-time alert style, tone, vibration, flashlight, dismiss method, pre-alarm, repeat interval and limit, stock and refill threshold |
| **Alerts** | Notification only, notification + sound, or full alarm. Taken / Snooze / Skip-with-reason actions, escalating re-reminders, quiet hours, an option to hide medicine names |
| **Alarm mode** | Full-screen alarm over the lock screen that wakes the display, a looping sound on the alarm stream with a gradual volume ramp, an optional Do Not Disturb bypass, slide-to-dismiss or solve-a-sum, built-in / phone / music-file / recorded voice tones, vibration patterns, flashlight blink, auto-repeat, pre-alarm, and "Remind me after I eat" (15/30/45 min) |
| **Calendar** | Monthly adherence colours (taken / late / skipped / missed). Tap a day to see or edit its doses |
| **Insights** | Adherence % per medicine, current and best streaks, most-missed times, missed doses by part of day, and a 14-day trend |
| **Skin journal** | Weekly photo (private app storage, never in the gallery), itch score 0–10, notes, itch trend chart, side-by-side compare of any two dates, weekly photo reminder |
| **Doctor report** | A clean A4 PDF with the medicine list, adherence history, missed doses, itch scores and the photos you select. Share it through any app |
| **Settings** | Light, dark or AMOLED theme, 6 accent colours, English and ಕನ್ನಡ (Kannada), 12/24-hour time, large text, default snooze and alert style, alarm volume and ramp, PIN or biometric app lock, backup and restore to a local `.zip`, reset |
| **Widgets** | Small: next dose with a live countdown. Large: today's checklist, tap a dose to mark it taken |
| **Setup wizard** | Walks through the notification, exact-alarm, full-screen and battery-optimisation settings, with step-by-step guides for Samsung, Xiaomi/Redmi, Vivo, Oppo, Realme and OnePlus, plus a test alarm |

The prescribed plan (HHzole, Pacroma 1%, Cetaphil, Teczine M and Forcan-150, Dr. Vijendran
Pragasam, 30-09-2026) loads on first launch with today as the start date. Every field can be
edited or deleted.

## How reliability works

- Every state change (taken, snooze, skip, edit, reboot…) recomputes **the whole alarm plan**
  from the database with a pure function (`core/scheduling` → `ReminderPlanner`), then
  re-registers it. Alarms can't drift out of sync.
- Alarm-mode doses use `AlarmManager.setAlarmClock()`: it has the highest priority, is exempt
  from Doze and shows the alarm icon in the status bar. Notification doses use
  `setExactAndAllowWhileIdle()`. If the exact-alarm permission is revoked, the app falls back
  to inexact alarms instead of silently dropping reminders.
- The app declares both `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM`.
- A foreground service (`AlarmService`, type `systemExempted` or `mediaPlayback`) keeps the
  alarm ringing and posts the full-screen notification.
- `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `TIME_SET`, `TIMEZONE_CHANGED` and exact-alarm
  permission changes all trigger a full re-plan. A daily 3 AM safety-net alarm does the same.
- Times are stored as wall-clock times, so a 9 PM dose stays at 9 PM local time after you
  travel or the clocks change. A time that falls in a daylight-saving gap moves forward.
- A snoozed or re-reminding dose is saved in the database (`active_alerts`), so it survives a
  reboot. A dose whose alarm should have rung within the last 15 minutes (for example, while
  the phone was off) still rings.
- Doses nobody answered are recorded as missed after a grace period you can set. You get a
  summary notification, which you'll see the next time you unlock the phone.

## Project layout

```
dosemate/
├── core/scheduling/        Pure Kotlin (JVM) scheduling engine + unit tests
│   └── ScheduleEngine, ReminderPlanner, LinkedDoseRule, QuietHours, AlertPolicy, Adherence
└── app/                    Android app (MVVM + Hilt)
    ├── data/db             Room entities, DAOs, database
    ├── data/repo           Repositories, settings, seeding, backup, photo storage, dose queries
    ├── alarm               AlarmScheduler, ReminderEngine, receivers, AlarmService, AlarmActivity,
    │                       notifications, tones (synthesised built-ins, voice recorder)
    ├── widget              Next-dose (RemoteViews + Chronometer) and Today (Glance) widgets
    ├── report              PDF generator
    └── ui                  Compose screens, one ViewModel per screen
```

## Build

Requirements: **JDK 17** (or newer) and the **Android SDK** with API 36. The easiest way to get
both is to install [Android Studio](https://developer.android.com/studio), which includes a
JDK and the SDK manager.

### With Android Studio

1. **File → Open…** and select the `dosemate` folder (not the repository root).
2. Wait for the Gradle sync to finish. Install the SDK components if Android Studio asks.
3. Plug in your phone with USB debugging on, then press **Run ▶**.

### From the command line

```bash
cd dosemate
# Tell Gradle where the SDK is (or set ANDROID_HOME):
echo "sdk.dir=$HOME/Android/Sdk" > local.properties

./gradlew :core:scheduling:test :app:testDebugUnitTest   # unit tests
./gradlew :app:assembleDebug                             # debug APK
# → app/build/outputs/apk/debug/app-debug.apk
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

The debug build installs as `com.dosemate.app.debug`, next to any release build.

### Continuous integration

`.github/workflows/dosemate-android.yml` runs both test suites and builds the debug and
release APKs on every push that touches `dosemate/`. Download the APKs from the run's
**Artifacts** section.

## Signed release APK

See **[RELEASE.md](RELEASE.md)** for step-by-step instructions: create a keystore, configure
signing, build, and install on your phone.

## After installing: make alarms bulletproof

1. Finish the setup wizard. It opens automatically on first launch; you can reopen it from
   **Settings → Setup and permissions**.
2. Allow notifications, exact alarms and full-screen alarms, and turn off battery
   optimisation.
3. Follow the guide for your phone brand. This matters most on Xiaomi, Vivo, Oppo, Realme
   and OnePlus.
4. Tap **Test alarm now** on any medicine and lock the phone. The alarm should wake the
   screen.

## Privacy

DoseMate has no internet permission, so it cannot send anything anywhere. Android cloud
backup is disabled. Photos and voice notes live in the app's private storage and never
appear in the gallery. Data leaves the phone only when you export a backup or share a PDF
yourself.

DoseMate is a reminder tool. Always follow your doctor's or pharmacist's instructions.
