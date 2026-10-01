# Keeping Abhyasa up to date (years from now)

Everything needed to rebuild and update the app lives in this `android/` folder.

## The 3 things that must never be lost

1. **This repository** (`niranjanskatti-wq/NiranjanAI`): the full source code.
2. **`keystore/essential.jks`** (password `essential-sideload`, alias `essential`): the signing key.
   Android only lets a new version install *over* the old one if it is signed with the same key.
   Lose it and every update means uninstalling, which **deletes all your data**. Keep an extra copy
   (e.g. Google Drive or email it to yourself).
3. **Your data backups**: Settings → Backup & restore → Export backup (or turn on weekly auto-backup).
   The file is plain JSON and can be restored into any future version.

## Updating in the future

Ask Claude Code (or any Android developer):

> "Open niranjanskatti-wq/NiranjanAI, folder `android/`. Read README.md and MAINTENANCE.md.
> Update the Abhyasa app to the latest Android version (targetSdk), keep the package name
> `com.essential.app` and the signing key `keystore/essential.jks`, increase versionCode,
> keep the database migrations, run the tests, and give me the new APK."

Rules for whoever updates it:

- Keep `applicationId` = `com.essential.app` and sign with `keystore/essential.jks`.
- Always **increase** `VERSION_CODE` (in `build.sh` and `app/build.gradle.kts`).
- Database changes: bump `Db.VERSION` and add an `if (oldVersion < N)` step in `Db.onUpgrade`.
  Never drop user tables. Backups restore across versions (`core/Backup.kt`).
- Run `./test.sh` (JVM + Robolectric tests) before shipping.
- Build: `./build.sh` (no Gradle needed), or open the folder in Android Studio (Gradle files included).
  If the tool versions in `build.sh` are no longer downloadable, Android Studio's normal build works.

## Before installing any update on your phone

1. Export a backup (Settings → Backup & restore).
2. Install the new APK **over** the old one. Do not uninstall first.
3. If anything looks wrong, Restore backup.

## Why it should keep working

- No internet, no servers, no accounts, no paid services: nothing external can shut down.
- No third-party libraries to go stale; only the Android framework and the Kotlin standard library.
- Targets Android 16 (API 36) and supports Android 10+. New Android versions usually keep running
  older apps; if a future Android blocks it, an update following the steps above fixes it.
