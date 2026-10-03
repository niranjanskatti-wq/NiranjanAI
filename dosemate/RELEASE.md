# Building a signed release APK

A release APK is smaller and faster than a debug build, and Android keeps updating it in
place as long as you sign every version with **the same key**.

## 1. Create a signing key (one time)

`keytool` comes with the JDK (Android Studio's own JDK is at
`<Android Studio>/jbr/bin/keytool`).

```bash
cd dosemate
keytool -genkeypair -v \
  -keystore dosemate-release.jks \
  -alias dosemate \
  -keyalg RSA -keysize 4096 -validity 10000
```

`keytool` asks for a password and a name. **Back up `dosemate-release.jks` and the passwords
somewhere safe.** If you lose them, you can't update the installed app. You'd have to
uninstall it, which deletes its data unless you made a backup first.

Alternative in Android Studio: **Build → Generate Signed App Bundle / APK… → APK → Create
new…**

## 2. Tell Gradle about the key

Create `dosemate/keystore.properties` (it is git-ignored, so it is never committed):

```properties
storeFile=dosemate-release.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=dosemate
keyPassword=YOUR_KEY_PASSWORD
```

`storeFile` is relative to the `dosemate/` folder.

## 3. Build

```bash
cd dosemate
./gradlew :app:assembleRelease
```

The signed APK is written to:

```
app/build/outputs/apk/release/app-release.apk
```

The release build runs R8 (code shrinking) and resource shrinking. If `keystore.properties`
is missing, Gradle builds `app-release-unsigned.apk`, which Android refuses to install.

Optional check:

```bash
$ANDROID_HOME/build-tools/<version>/apksigner verify --print-certs app/build/outputs/apk/release/app-release.apk
```

## 4. Install on your phone

**USB:** turn on *Developer options → USB debugging*, connect the phone and run:

```bash
adb install -r app/build/outputs/apk/release/app-release.apk
```

**Without a computer:** copy the APK to the phone (USB, cloud drive or messaging app) and
tap it in the Files app. Allow *Install unknown apps* for that app when Android asks.

## 5. Updating later

1. Increase `versionCode` (and `versionName`) in `app/build.gradle.kts`.
2. Rebuild with the same keystore.
3. Install over the existing app. Your data stays.

As an extra precaution before big updates, use **Settings → Back up to a file**.

## Signing in GitHub Actions (optional)

The CI workflow builds an unsigned release APK. To get signed APKs from CI, store the
keystore as a base64 repository secret and write `keystore.properties` in a workflow step
before `assembleRelease`. Never commit the keystore or the passwords.
