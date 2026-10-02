# Deepwork

A personal, offline-first productivity app for a single user. It connects daily planning, focused work sessions, distraction tracking, and reviews, and it measures what you actually finish rather than only how long you worked.

- No accounts, no sign-up, no analytics, no AI, no cloud database.
- All data lives on your device in IndexedDB (via Dexie).
- Works fully offline after the first load (installable PWA with a precaching service worker).
- The only network feature is an optional weekly backup to **your own** Google Drive.

Stack: React 19, TypeScript, Vite, Tailwind CSS v4, shadcn/ui-style components (Radix primitives), Framer Motion, Recharts, Dexie, dnd-kit, and vite-plugin-pwa (Workbox). Fonts (Inter, Geist, Source Serif 4) and icons (Lucide) are bundled. The ambient sounds (rain, café, white noise, brown noise) and the chimes are synthesized on-device with the Web Audio API, so the app downloads no audio files.

---

## Android app

Deepwork is packaged as a native Android app with [Capacitor](https://capacitorjs.com). The project is in `android/`, and the native code is in `android/app/src/main/java/com/niranjan/deepwork/`. The Android app adds:

- **App blocking during focus sessions.** Pick apps to pause, or allow only the apps you pick. Opening a paused app shows a full-screen "Stay with it" screen with the time left. Pausing or ending the session lifts the block. Your home screen, phone/dialer and keyboard are never blocked. Each attempt can be logged as a "Blocked app" distraction.
- **Real notifications.** Session-complete and break-over alerts are scheduled with Android, so they fire on time even when the app is closed. Morning, evening and weekly reminders are planned a week ahead.
- **Fingerprint or face unlock** with the system biometric prompt, keep-screen-on during sessions, and the Android back button.
- **Automatic Drive backup without prompts.** After you connect once, Android hands out fresh tokens silently, so the weekly backup runs on its own whenever you open the app.
- **Sharing exports.** JSON and CSV exports go to the Android share sheet, so you can save them to Files, Drive or email.

### Install
Every push that changes `deepwork/` runs the **Deepwork Android build** GitHub Action. It builds a signed APK and publishes it as a GitHub release.

- Always the newest build: <https://github.com/niranjanskatti-wq/NiranjanAI/releases/download/deepwork-latest/Deepwork.apk>
- All builds: <https://github.com/niranjanskatti-wq/NiranjanAI/releases>

Open the link on your phone, download the APK, and allow "Install unknown apps" for your browser when Android asks. New builds install as updates and keep your data, because every build is signed with the same key, which is saved in the repository's Actions cache.

### Turn on app blocking
1. In Deepwork, go to **Settings → App blocking → Open Accessibility settings**.
2. Choose **Deepwork focus blocking** (it may be listed under "Installed apps" or "Downloaded apps") and switch it on.
   - On Android 13 and later, sideloaded apps may show "Restricted setting". If you see that, open Android **Settings → Apps → Deepwork → ⋮ → Allow restricted settings**, then repeat step 2.
3. Back in Deepwork, pick the apps to pause, or switch to "Allow only chosen apps".

The permission is used only to see which app comes to the foreground during a session. Deepwork never reads screen content, and nothing leaves your phone.

### Google Drive backup on Android
On Android, Google recognises the app by its **package name and signing certificate**, so you don't need to paste a Client ID. You need one extra OAuth client:

1. Do steps 1–3 of the web setup below (project, Drive API, consent screen with the `drive.file` scope, and yourself as a test user).
2. Go to **Credentials → Create credentials → OAuth client ID → Android**.
3. Package name: `com.niranjan.deepwork`.
4. SHA-1 certificate fingerprint: copy it from **Deepwork → Settings → Backup** (tap to copy), or from the release notes of any build.
5. **Create**. Then, in Deepwork, tap **Connect Google Drive**.

If Google reports a "developer error", the package name or SHA-1 doesn't match the Android client.

### Build it yourself
You need Node 20+, JDK 21 and the Android SDK (platform 36):

```bash
npm install
npm run build
npx cap sync android
cd android && ./gradlew assembleDebug     # app/build/outputs/apk/debug/app-debug.apk
```

Or open `android/` in Android Studio.

---

## Run it (web / desktop browser)

Requirements: Node.js 20+ and npm.

```bash
cd deepwork
npm install
npm run dev          # http://localhost:5173 (service worker disabled in dev)
```

Production build (this is the one that works offline):

```bash
npm run build        # type-checks, then builds to dist/ and generates the service worker
npm run preview      # serves dist/ at http://localhost:4173
```

`dist/` is a static site. You can host it anywhere that serves static files over **HTTPS**, for example Netlify, Vercel, Cloudflare Pages, GitHub Pages, or your own server. Configure the host to send unknown paths to `index.html` (SPA fallback). Service workers, biometrics, wake lock, and Google sign-in all need HTTPS, except on `localhost`.

### Smoke test (optional)

`scripts/e2e-smoke.mjs` drives the production build in Chromium through the main flows: focus session, distractions, session close, breaks, interrupted sessions, tasks, demo data, insights, reviews, every settings page, all modules switched off, the PIN lock, and an offline reload. It needs the `playwright` package and a Chromium:

```bash
npm run build && npm run preview &
npm i -D playwright && npx playwright install chromium
node scripts/e2e-smoke.mjs     # screenshots go to ./e2e-shots
```

---

## Install as an app (PWA)

Open the deployed HTTPS URL once while online. The service worker then caches the whole app.

- **iPhone / iPad (Safari):** Share → **Add to Home Screen**. Notifications on iOS only work for Home Screen apps (iOS 16.4+).
- **Android (Chrome):** menu ⋮ → **Install app** (or **Add to Home screen**).
- **Desktop (Chrome / Edge):** click the install icon in the address bar, or use **Settings → About → Install** inside Deepwork.

To check that it works offline, turn on airplane mode and open the app. Everything works except Google Drive backup, which waits until you are back online and then retries on its own.

**Settings → About → Persistent storage** asks the browser not to evict your data when the device runs low on space. Installed apps usually get this automatically.

---

## Google Drive backup setup

Deepwork backs up to your Drive with an OAuth client that **you** own. It uses the narrow `drive.file` scope, so the app can only see files it created itself. Backups go to a folder named **Deepwork Backups** as `deepwork-backup-YYYY-MM-DD.json`.

### 1. Create a Google Cloud project
1. Go to <https://console.cloud.google.com/> and sign in.
2. Use the project picker at the top → **New project** → name it, for example, `Deepwork` → **Create**. Make sure the new project is selected.

### 2. Enable the Google Drive API
1. Open **APIs & Services → Library**.
2. Search for **Google Drive API** → open it → **Enable**.

### 3. Configure the OAuth consent screen
1. Open **APIs & Services → OAuth consent screen**. In newer consoles this is under **Google Auth Platform → Branding / Audience / Data access**.
2. User type: **External** → **Create**.
3. App name `Deepwork`, your email as the support and developer contact → **Save**.
4. **Scopes / Data access:** add `https://www.googleapis.com/auth/drive.file` (search "drive.file").
5. **Test users / Audience:** add your own Google account. While the app is in "Testing" mode, only listed test users can sign in. That is fine for personal use. Note that Google expires testing-mode grants after about 7 days, so you may occasionally see the "reconnect" prompt. To avoid that, you can **Publish app**. For the non-sensitive `drive.file` scope this does not require Google verification. You will see an "unverified app" notice that you can click through.

### 4. Create the OAuth Client ID
1. Open **APIs & Services → Credentials → Create credentials → OAuth client ID**.
2. Application type: **Web application**.
3. **Authorized JavaScript origins:** add every origin you will open Deepwork from, for example:
   - `http://localhost:5173` (dev)
   - `http://localhost:4173` (preview)
   - `https://your-deployed-domain.example`
   
   No redirect URIs are needed, because the app uses the Google Identity Services token popup.
4. **Create**, then copy the **Client ID** (it looks like `1234567890-abc...apps.googleusercontent.com`). You do **not** need the client secret. Never put a secret in a browser app.

### 5. Paste it into Deepwork
Open **`src/config/google.ts`** and paste the ID:

```ts
export const GOOGLE_CLIENT_ID = '1234567890-abc123.apps.googleusercontent.com'
```

(Alternatively, create `.env.local` containing `VITE_GOOGLE_CLIENT_ID=...`.) Rebuild and redeploy.

### 6. Connect
In the app, go to **Settings → Backup → Connect Google Drive**, sign in, and allow access. The first backup runs immediately.

### How the schedule works
- Backups run **once a week** on the day you choose (default: Sunday). You can also tap **Back up now** at any time. The backup status on Today also works as a "back up now" button.
- A web app can't run reliably in the background, so the weekly backup runs **the next time you open Deepwork** after it becomes due, as long as you're online. If you're offline, it retries silently on a later open.
- Google issues browser tokens that last about an hour. If the token has expired when a backup is due, Deepwork shows a small "reconnect" prompt, which takes one tap. The prompt never blocks the app.
- Deepwork keeps the newest **N** backups (default 8) and deletes older ones that the app created.
- **Restore from Google Drive** lists your backups, previews their date and record counts, and asks you to confirm before it replaces local data.
- **Disconnect** revokes and removes the stored token. Backups already in Drive stay there.
- Backups never include your PIN hash, biometric registration, or Google token.

---

## Features at a glance

| Area | What you can do |
|---|---|
| **Today** | Greeting and date, top priorities (drag to reorder, tap to focus, carry over yesterday's unfinished ones), hourly time blocks (drag tasks onto the timeline, tap a slot or block to edit or focus), Start focus, daily summary and goal progress, streak, evening/weekly review cards when due, backup status. Sections can be reordered and hidden. |
| **Focus** | Choose a task (or an untitled session, if allowed) and a preset or custom duration. Full-screen ring timer in countdown or count-up mode. Log distractions with reasons and an optional note while the timer keeps running. Pause, resume, end early with a reason. Ambient sounds with volume. Screen wake lock. Timing is timestamp-based and is restored if you close or reopen the app. |
| **Session close** | Done / Partly done / Stuck, a "What did I get done?" note, a smallest-next-step prompt for Stuck that creates tasks, and an option to mark the task complete. |
| **Breaks** | Suggested short or long break (long after every X sessions), a break timer, a break-over alert, and an optional auto-start of the next session. |
| **Tasks** | Projects with colors, session estimates and sessions spent, due dates, priority flag, status, checklist subtasks, filters (Today / Upcoming / All open / Completed / by project), quick add, move to today, delete. |
| **Reviews** | Evening review (planned vs. done, stats, editable questions, tomorrow's priorities) and weekly review (charts, best focus time, editable questions), with full history. |
| **Insights** | Focus hours, distractions by reason, completion rate, a weekday × hour heatmap, sessions by project, and rule-based insight cards. Ranges: 7 / 14 / 30 / 90 days or all time. |
| **Settings** | Module toggles, per-module customization with reset, appearance (theme, accent, font, text size, density, home layout, animations), notifications with quiet hours, PIN and biometric lock with auto-lock, Drive backup, data export/import/demo/delete, and About. |

### Notes on platform limits
- **Notifications** (morning planning, evening and weekly review, break over, session complete) fire while Deepwork is open or running in the background. Browsers don't let web apps schedule notifications for when they are fully closed.
- **Biometric unlock** uses WebAuthn with your device's platform authenticator (Face ID, Touch ID, Windows Hello, or Android fingerprint) purely as a local presence check. Your PIN always works as a fallback.

---

## Data model

Stored in IndexedDB database `deepwork`:

- `settings`: one record holding module toggles, customization, appearance, notifications, lock, and backup state
- `projects` (id, name, color, order)
- `tasks` (id, title, project_id, estimate_sessions, due_date, status, flagged, is_priority, priority_date, priority_order, order, created_at, completed_at)
- `subtasks` (id, task_id, title, done, order)
- `timeBlocks` (id, date, start_time, end_time, task_id, label)
- `sessions` (id, task_id, planned_duration, actual_duration, started_at, ended_at, result, note). Durations are in seconds; result is done, partly, stuck, or interrupted.
- `distractions` (id, session_id, timestamp, reason, note)
- `distractionReasons` (id, label, order)
- `reviews` (id, type, date, answers, next_priorities, stats, created_at)

Backup and export files are JSON with `app: "deepwork"` and a `schema_version`. When the schema changes, add a migration step to `migrateBackup()` in `src/lib/data.ts` so older files can still be restored.

## Project layout

```
src/
  config/google.ts        ← paste your OAuth Client ID here
  db/                     Dexie schema and record types
  lib/                    settings, stats and insights rules, audio, notifications, lock, Drive, backup, export, demo data
  state/                  settings provider and the focus-session engine
  components/ui/          shadcn-style primitives (button, dialog, switch, slider, …)
  features/               today, focus, tasks, review, insights, settings, lock
```
