#!/usr/bin/env bash
# Builds a signed, installable Essential APK without Gradle or the Android SDK manager.
# Toolchain (all offline once fetched):
#   aapt2, dx (dalvik-exchange), zipalign, apksigner  -> Ubuntu packages
#   Android framework jar (API 34, with resources)    -> Maven Central (org.robolectric:android-all)
#   Kotlin compiler + stdlib                          -> Maven Central
# Usage: ./build.sh            (output: release/Abhyasa.apk)
set -euo pipefail
cd "$(dirname "$0")"
TOOLS=${TOOLS:-/opt/essential-tools}
KV=1.9.24
ANDROID_ALL=$TOOLS/android-all-14-robolectric-10818077.jar
VERSION_CODE=${VERSION_CODE:-7}
VERSION_NAME=${VERSION_NAME:-1.4.0}
export JAVA_TOOL_OPTIONS=""

fetch() { # url dest
  [ -f "$2" ] && return 0
  for i in 1 2 3 4 5; do curl -sSfL -o "$2.tmp" "$1" && mv "$2.tmp" "$2" && return 0; sleep $((i*8)); done
  echo "Failed to fetch $1" >&2; exit 1
}

setup() {
  mkdir -p "$TOOLS"
  command -v aapt2 >/dev/null && command -v dalvik-exchange >/dev/null && command -v apksigner >/dev/null && command -v zipalign >/dev/null || \
    sudo apt-get install -y aapt dalvik-exchange apksigner zipalign
  local M=https://repo1.maven.org/maven2
  fetch $M/org/robolectric/android-all/14-robolectric-10818077/android-all-14-robolectric-10818077.jar "$ANDROID_ALL"
  for a in kotlin-compiler-embeddable kotlin-stdlib kotlin-script-runtime kotlin-reflect kotlin-daemon-embeddable; do
    fetch $M/org/jetbrains/kotlin/$a/$KV/$a-$KV.jar "$TOOLS/$a-$KV.jar"
  done
  fetch $M/org/jetbrains/intellij/deps/trove4j/1.0.20200330/trove4j-1.0.20200330.jar "$TOOLS/trove4j-1.0.20200330.jar"
  fetch $M/org/jetbrains/kotlinx/kotlinx-coroutines-core-jvm/1.8.0/kotlinx-coroutines-core-jvm-1.8.0.jar "$TOOLS/kotlinx-coroutines-core-jvm-1.8.0.jar"
  fetch $M/org/jetbrains/annotations/13.0/annotations-13.0.jar "$TOOLS/annotations-13.0.jar"
  if [ ! -f "$TOOLS/kotlin-stdlib-dex-$KV.jar" ]; then   # dx can't read Java 9 module-info; strip it
    rm -rf "$TOOLS/stdlib-x" && mkdir "$TOOLS/stdlib-x" && (cd "$TOOLS/stdlib-x" && unzip -q "../kotlin-stdlib-$KV.jar" && rm -rf META-INF/versions && zip -qr ../kotlin-stdlib-dex-$KV.jar .)
  fi
}

setup
B=build
rm -rf $B && mkdir -p $B/gen $B/classes $B/dex release
SRC=app/src/main

echo "• Resources"
# The source manifest uses Gradle-style namespacing (no package attribute); aapt2 needs it inline.
sed 's|<manifest xmlns:android="http://schemas.android.com/apk/res/android">|<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.essential.app">|' \
  $SRC/AndroidManifest.xml > $B/AndroidManifest.xml
aapt2 compile --dir $SRC/res -o $B/res.zip
aapt2 link -I "$ANDROID_ALL" --manifest $B/AndroidManifest.xml --min-sdk-version 29 --target-sdk-version 36 \
  --version-code "$VERSION_CODE" --version-name "$VERSION_NAME" -A $SRC/assets --java $B/gen -o $B/base.apk $B/res.zip

echo "• Kotlin"
KCP="$TOOLS/kotlin-compiler-embeddable-$KV.jar:$TOOLS/kotlin-stdlib-$KV.jar:$TOOLS/kotlin-script-runtime-$KV.jar:$TOOLS/kotlin-reflect-$KV.jar:$TOOLS/kotlin-daemon-embeddable-$KV.jar:$TOOLS/trove4j-1.0.20200330.jar:$TOOLS/kotlinx-coroutines-core-jvm-1.8.0.jar:$TOOLS/annotations-13.0.jar"
java -Xmx3g -cp "$KCP" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler -no-reflect -no-stdlib -jvm-target 1.8 -Xlambdas=class -Xsam-conversions=class -Xstring-concat=inline -nowarn \
  -classpath "$ANDROID_ALL:$TOOLS/kotlin-stdlib-$KV.jar" -d $B/classes $(find $SRC/java -name '*.kt') $(find $B/gen -name '*.java')
# R.java is compiled by kotlinc only as a reference; compile it for real with javac.
javac -nowarn -source 8 -target 8 -cp "$ANDROID_ALL" -d $B/classes $(find $B/gen -name '*.java') 2>&1 | grep -v "warning" || true

echo "• Checking bytecode is Android-safe (no invokedynamic lambdas)"
BAD=$(cd $B/classes && find . -name '*.class' | sed 's|^\./||; s|\.class$||' | xargs javap -c -p -cp . 2>/dev/null | \
  grep -E "invokedynamic|ComparisonsKt.(compareBy:\(\[|nullsFirst|nullsLast|then:|thenDescending)|kotlin/streams/" || true)
if [ -n "$BAD" ]; then echo "$BAD" | head; echo "ERROR: bytecode needs desugaring (not supported by dx)"; exit 1; fi

echo "• Dex"
dalvik-exchange --dex --min-sdk-version=26 --output=$B/dex/classes.dex $B/classes "$TOOLS/kotlin-stdlib-dex-$KV.jar"

echo "• Package & sign"
cp $B/base.apk $B/unsigned.apk
(cd $B/dex && zip -q ../unsigned.apk classes*.dex)
zipalign -f -p 4 $B/unsigned.apk $B/aligned.apk
apksigner sign --ks keystore/essential.jks --ks-pass pass:essential-sideload --key-pass pass:essential-sideload \
  --v2-signing-enabled true --v3-signing-enabled true --out release/Abhyasa.apk $B/aligned.apk
apksigner verify release/Abhyasa.apk
ls -la release/Abhyasa.apk
