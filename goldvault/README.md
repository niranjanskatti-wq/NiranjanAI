# GoldVault

An offline-first Android app for a family's gold, silver and other ornaments kept in bank lockers and at home. Built with Flutter.

Everything (inventory, lockers, visits, reminders, exports) works without internet. The network is used only for **Google Sheets sync** and the **Google Drive backup**.

## Features

| Area | What you get |
|---|---|
| **Security** | 4-digit PIN plus fingerprint/face unlock. Auto-lock after 1 minute in the background, with 30-second lock-outs after 5 wrong PINs. SQLCipher-encrypted database. AES-GCM-encrypted photos and backups. "Tap to show" on locker no., key no., prices, values and HUID. Screenshots blocked through `FLAG_SECURE` (whole app by default, or only on sensitive screens). Android system backup disabled. |
| **Lockers & places** | SBI Locker, HDFC Locker and Home (Almirah / Safe / Drawer) are pre-created. **+ Add Locker** has every field: bank, branch, address, locker no., size, key no., opened date, holders, joint holders, nominee, rent and due date, contact, notes. Each locker gets its own calendar colour. **Close locker** moves the items out first and keeps the history. Each card shows item count, gold and silver weight, and estimated value. |
| **Ornaments** | Serial numbers assigned automatically (GV-0001…). Four add flows: **Quick add** (fill details later), **Newly purchased** (shop, bill, rate, making charges, GST, total calculator, bill photo), **Full details**, and **Duplicate** (copies the photos too). Up to 5 photos per item. Nine statuses; sold/exchanged/gifted items stay in history instead of being deleted. Search by name, serial, owner, location, tag or HUID. Filter by status, category, location or owner, and sort by weight, name, date and more. |
| **Visit log** | Log the locker, date, time in/out, who visited and the purpose. Pick the items **deposited** and **withdrawn**, and their locations update automatically. Full movement history per item ("Kept in SBI Bank Locker · 12 Mar 2026, 11:30 AM"). Month/week calendar colour-coded per locker; tap a day to see what moved. Planned visits. A **"Where is my ornament?"** screen. |
| **Reminders** | Locker rent due (configurable lead time, plus "mark paid" which rolls the date forward a year), items not returned after X days, planned visits, and custom reminders. Local notifications come from a background job that needs no internet. |
| **Dashboard** | Total gold, silver and item count. Breakdown by location, owner and category. Manual 24K gold, silver and platinum rates per gram give an estimated value adjusted for purity. Recent movements and upcoming reminders. |
| **Google Sheets** | One-way push (the app is the master copy) to an auto-created "GoldVault Inventory" sheet. Tabs: Inventory, Lockers, Locker Visits, Movement History, Locations, plus **one tab per active locker**. Manual "Sync now" and background auto-sync when online. **Share Sheet** gives chosen emails view-only or edit access. |
| **Export** | Excel (.xlsx, same tabs) and a PDF report, both shareable via WhatsApp or email. Both work offline. |
| **Drive backup** | Weekly on the day and time you choose (WorkManager), optionally Wi-Fi only, and retried when connectivity returns. The full database and all photos are encrypted with a backup password into a "GoldVault Backups" folder. The last 8 are kept, you get a notification after each one, and "Last backup" appears in settings. **Restore on a new phone** with the backup password. |
| **Design** | Dark navy with gold, Playfair Display and Lato fonts (bundled, so they work offline), large touch targets, animated cards and transitions. **English and Kannada (ಕನ್ನಡ)**. Indian number format and ₹. |

## Build the APK

### Option A: GitHub Actions (no local setup)

`.github/workflows/goldvault-apk.yml` analyses, tests and builds `app-release.apk` on every push that touches `goldvault/`. Download it from the run's **Artifacts** (`GoldVault-apk`).

Optional repository secrets:

| Secret | Purpose |
|---|---|
| `GOOGLE_SERVER_CLIENT_ID` | Enables Google Sign-In (Sheets + Drive). See below. |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | Real release signing. Without them the APK is signed with a debug key. It still installs, but **keep the same key for updates**. |

### Option B: Locally

Requires Flutter 3.47+ and the Android SDK.

```bash
cd goldvault
flutter pub get
flutter test
flutter build apk --release --dart-define=GOOGLE_SERVER_CLIENT_ID=XXXX.apps.googleusercontent.com
# → build/app/outputs/flutter-apk/app-release.apk
```

For release signing, create `android/key.properties` (git-ignored):

```
storeFile=/absolute/path/goldvault.jks
storePassword=...
keyAlias=goldvault
keyPassword=...
```

## Google Sign-In setup (only for Sheets and Drive)

1. In [Google Cloud Console](https://console.cloud.google.com/), create a project and enable the **Google Sheets API** and **Google Drive API**.
2. Under **OAuth consent screen**, add the scopes `drive.file` and `spreadsheets`, and add your family's Google accounts as test users. Alternatively, publish the app.
3. Under **Credentials**, create:
   - an **Android** OAuth client with package `com.goldvault.goldvault` and the SHA-1 of your signing key (`keytool -list -v -keystore goldvault.jks`);
   - a **Web application** OAuth client. Its client ID is `GOOGLE_SERVER_CLIENT_ID`.
4. Build with `--dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>`.

The app asks only for `drive.file`, so it can see only the files it created itself (the sheet and the backups folder), not the rest of your Drive.

## Security design

- **Database:** SQLCipher (AES-256). A random 256-bit key is generated on first run and stored in Android Keystore–backed secure storage (`resetOnError: false`, so keys are never silently wiped).
- **Photos:** each file is AES-256-GCM encrypted with a separate random photo key and decrypted only in memory for display.
- **PIN:** salted PBKDF2-SHA256 (30k iterations), constant-time comparison, escalating lock-out.
- **Backups:** a streamed container (`GVB1`) of 1 MiB AES-256-GCM chunks. The key is PBKDF2-SHA256 (120k iterations) of the backup password. Chunk index and last-chunk flag are authenticated, so reordering or truncation is detected. Inside: every database row (JSON), the photo key, and the encrypted photos. Without the password the backup cannot be opened, so **write the password down**.
- **Screens:** `FLAG_SECURE` through a small platform channel (`MainActivity.kt`). The recent-apps preview is also blanked.
- `android:allowBackup="false"` and data-extraction rules exclude all app data from Android's own backups.

## Offline / airplane-mode testing

`flutter test` runs fully offline:

- `test/offline_test.dart` installs an `HttpOverrides` that throws on any network connection. It then runs the whole Stage 1 flow (add locker and sub-location, quick/purchase/duplicate add, visit with deposits, dashboard totals, search, calendar data, reminders, Excel export). It asserts **zero** network attempts, and that Sheets sync fails gracefully and stays queued.
- `test/app_flow_test.dart` drives the real UI: PIN setup, quick add, all tabs, switching to Kannada, and auto-lock.
- `test/repository_test.dart` and `test/services_test.dart` cover serials, visits and movements, closing lockers, totals and values, search, reminders, the weekly schedule, crypto, backup→restore on a "new phone", wrong-password rejection, and the Excel/PDF output.
- `test/strings_test.dart` checks that every UI string exists in English and Kannada with matching placeholders.

On a device: enable airplane mode and use every Stage 1 screen. Nothing needs the network. Sync and backup show "No internet" and catch up later.

## Project layout

```
lib/
  core/       theme, strings (en/kn), crypto, secure storage, app lock, services locator
  data/       schema, models, repository (all SQL), option lists
  services/   reminders, Google auth, Sheets sync, Excel/PDF export, Drive backup, WorkManager jobs, notifications, encrypted photo store
  ui/         screens and widgets
android/      FLAG_SECURE channel, adaptive icon, manifest hardening, signing
test/         offline, UI flow, repository, services, strings
```

## Known limitations

- The PDF report uses Latin fonts. Names typed in Kannada show correctly in the app, Excel and Sheets, but not in the PDF.
- Restore replaces all data on the phone. Merging two phones is not supported.
- Sheets sync is one-way. Edits made in the sheet are overwritten on the next sync.
