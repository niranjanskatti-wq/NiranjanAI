# Deepwork

Plan, focus, and review what you actually finish. A native Android app built with Flutter.

- **Offline only.** Everything lives in a local database on the phone. No accounts, no AI, no analytics.
- **One network feature:** an optional weekly backup to your own Google Drive (`drive.file` scope, so the
  app can only see the files it created).

## Install on your phone

Open this link on the phone and install the APK:

**https://github.com/niranjanskatti-wq/NiranjanAI/releases/download/deepwork-latest/Deepwork.apk**

Android will ask you to allow "Install unknown apps" for your browser the first time. Every build is
signed with the same key, so a new APK installs as an update and keeps your data.
The APK is built for 64-bit ARM phones (practically every Android phone from 2017 on).

Each build is also published on its own as `deepwork-build-N` under
[Releases](https://github.com/niranjanskatti-wq/NiranjanAI/releases).

## What's inside

| Screen | What it does |
| --- | --- |
| Today | Top priorities, time blocks (drag tasks onto the timeline), daily summary, streak, review prompts, backup status |
| Focus | Progress ring, distraction log, pause/end, ambient sounds (white, brown, rain, cafe), screen kept awake, app blocking |
| Session close | Done / partly / stuck, a note, and next steps when stuck |
| Breaks | Short and long breaks with their own timer |
| Tasks | Projects, estimates, due dates, subtasks, flags |
| Reviews | Evening review (2 minutes) and weekly review (10 minutes) |
| Insights | Charts and rule-based cards: best focus time, completion rate, distractions, heatmap |
| Settings | Features on/off, per-module customization, appearance, notifications, PIN and fingerprint lock, backup, data export/import/demo/delete |

Timers use wall-clock timestamps, so a session keeps counting correctly when the app is closed or
the phone sleeps. An exact alarm notifies you when it ends.

## Blocking apps during focus (like Forest)

Deepwork can stop you from opening distracting apps while a session runs. It uses an Android
Accessibility service that only watches which app comes to the front; it reads nothing on screen.

1. Settings → **App blocking** → choose a mode: block a list of apps, or allow only a list.
2. Tap **Open Accessibility settings** → Downloaded apps (or Installed apps) →
   **Deepwork focus blocking** → On.
3. On Android 13+ a sideloaded app's Accessibility switch is greyed out at first. Tap **App info**,
   then ⋮ (top right) → **Allow restricted settings**, and repeat step 2.

When you open a blocked app, a "Stay with it" screen appears. Deepwork itself, the phone dialer,
the launcher, and keyboards are never blocked. Blocked attempts are logged as distractions.

## Google Drive backup (one-time setup)

Backups go to a "Deepwork Backups" folder in your Drive once a week (or whenever you tap
**Back up now**). Google requires an OAuth client tied to the app's signing key:

1. Open the [Google Cloud console](https://console.cloud.google.com/) and create a project.
2. **APIs & Services → Library** → enable **Google Drive API**.
3. **OAuth consent screen**: choose External, fill in the app name and your email, add the scope
   `.../auth/drive.file`, and add your own Google account under **Test users**.
4. **Credentials → Create credentials → OAuth client ID → Android**:
   - Package name: `com.niranjan.deepwork`
   - SHA-1 certificate fingerprint: shown in the app under Settings → Backup → One-time Google Cloud setup (tap to copy), and in
     each release's notes.
5. In the app: Settings → Backup → **Connect Google Drive**.

You don't need a client ID or secret in the app; Android matches the package name and the
signing key.

Backups use the same JSON format as the web version (`app: "deepwork"`, `schema_version: 1`), so a
file exported from either one imports into the other.

## Build it yourself

Requires Flutter 3.47 or newer and the Android SDK.

```bash
cd deepwork
flutter pub get
flutter analyze
flutter test --exclude-tags screenshots
flutter build apk --release --target-platform android-arm64
```

Without `android/key.properties`, the release APK is signed with the debug key, so it won't
install over the published builds.

- `flutter test --tags screenshots --update-goldens` renders every screen in light, dark, and
  tablet layouts to `test/screens/` for a visual check.
- `python3 tool/generate_sounds.py` regenerates the ambient sound loops in `assets/sounds/`.
- After changing tables in `lib/data/database.dart`, run
  `dart run build_runner build --delete-conflicting-outputs`.

The GitHub Actions workflow `.github/workflows/deepwork-android.yml` analyzes, tests, builds, signs,
and publishes the APK on every push that touches `deepwork/`.

## Project layout

```
lib/
  app.dart            routes, shell (bottom tabs or sidebar on wide screens), lock gate
  core/               settings model, stats and streak rules, review timing, theme tokens
  data/               drift database, repository, providers, backup format, demo data
  services/           notifications, audio, lock (PIN + biometrics), Google Drive, native bridge
  features/           today, focus, tasks, insights, review, settings, backup, lock
  ui/                 shared widgets, charts, task picker
android/app/src/main/kotlin/com/niranjan/deepwork/
  MainActivity.kt     method channel: blocking, installed apps, keep awake, signing info
  BlockerService.kt   accessibility service that sends blocked apps to the "Stay with it" screen
  BlockedActivity.kt  the "Stay with it" screen
```

Fonts: Inter, Geist, and Source Serif 4 (SIL Open Font License, see `assets/fonts/`).
