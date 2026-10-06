# Love Bombing (Android)

A native, 100% offline Android app that helps a husband keep the romance alive:
daily messages, a "today's move", reminders, gift ideas and a calendar.

- Kotlin + Jetpack Compose, Room (SQLite) for all user data, AlarmManager for reminders.
- Android 8.0+ (minSdk 26), target SDK 35.
- **No INTERNET permission** (it is explicitly stripped from the merged manifest, and CI fails if it ever appears).
  No accounts, analytics, ads, Firebase or network code. WhatsApp sharing is a plain `ACTION_SEND` intent.

## Install on your phone

Every push that touches this folder builds a signed APK in GitHub Actions
(`.github/workflows/love-bombing-android.yml`) and publishes it as a pre-release
named **Love Bombing 1.0.N** on the repository's Releases page. Open that page on
the phone, download `LoveBombing-1.0.N.apk`, and allow "install unknown apps" for
your browser when asked. Later builds install as updates (same signing key).

## Build locally

Requires JDK 17 and the Android SDK (platform 35).

```bash
cd love-bombing-android
./gradlew assembleRelease
# -> app/build/outputs/apk/release/app-release.apk
```

### Signing

`keystore/love-bombing.jks` (password/alias `lovebombing`) is checked in so that
any build can produce an installable, updatable APK for personal sideloading. For
anything beyond that, create your own key and either set `LB_KEYSTORE_PATH`,
`LB_KEYSTORE_PASSWORD`, `LB_KEY_ALIAS`, `LB_KEY_PASSWORD` locally, or add the
GitHub secrets `LB_KEYSTORE_BASE64` (base64 of the .jks), `LB_KEYSTORE_PASSWORD`,
`LB_KEY_ALIAS`, `LB_KEY_PASSWORD`. Note an APK signed with a different key can't
update one signed with the bundled key (uninstall first; export a backup before).

## Content

All content is bundled in `app/src/main/assets/` and generated from the plain-text
sources in `tools/content/`:

| File | What | Count |
|---|---|---|
| `messages/*.txt` | Messages per category (`{name}` = her saved name) | 1000 |
| `moves.txt` | Daily action ideas | 100 |
| `gifts.txt` | `title|description|budget|occasions|kind` | 150 |
| `festivals_computed.json` | Lunar festival dates 2026–2030 | — |

After editing a source file run `python3 tools/build_content.py` (it validates the
counts; CI fails if assets are out of sync).

Festival dates were computed with `tools/compute_festivals.py` (PyEphem; Lahiri
ayanamsa, amanta months, tithi at the customary observance time, Ujjain) and
spot-checked against published panchangs. Regional calendars can differ by a day.
Fixed dates (New Year, Valentine's, Women's Day, Christmas, New Year's Eve) are added
by `build_content.py`.

## How reminders work

`notify/ReminderScheduler.kt` computes every reminder (daily good morning / mid-day /
good night, birthday and anniversary at 7 days, 1 day and on the day, festivals 3 days
before, plans 15 minutes before plus 1 day before for date nights and gifts) and keeps
a single exact alarm armed for the next one. When it fires it posts what's due and
arms the next. `BootReceiver` re-arms after reboot, app update, time/timezone change,
or when exact-alarm permission changes. Tapping a daily reminder opens the app with a
suggested message ready to share.
