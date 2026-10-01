#!/usr/bin/env bash
# Runs the JVM test-suite: pure unit tests + Robolectric tests that boot the real app
# (activities, SQLite, alarms, notifications, receivers, widgets) on a simulated Android 14.
# Requires ./build.sh to have run (uses build/classes and build/base.apk).
set -euo pipefail
cd "$(dirname "$0")"
TOOLS=${TOOLS:-/opt/essential-tools}
KV=1.9.24
ANDROID_ALL=$TOOLS/android-all-14-robolectric-10818077.jar
LIB=$TOOLS/testlib
if [ ! -d "$LIB" ]; then (cd test && mvn -q -B dependency:copy-dependencies -DoutputDirectory="$LIB"); fi
[ -d build/classes ] || ./build.sh
T=build/test
rm -rf $T && mkdir -p $T/classes $T/res/com/android/tools
# Robolectric reads the app's resources/manifest from this file (normally written by the Android Gradle plugin).
cat > $T/res/com/android/tools/test_config.properties <<CFG
android_merged_manifest=$PWD/build/AndroidManifest.xml
android_merged_assets=$PWD/app/src/main/assets
android_resource_apk=$PWD/build/base.apk
android_custom_package=com.essential.app
CFG
TESTCP=$(ls $LIB/*.jar | tr '\n' ':')
KCP="$TOOLS/kotlin-compiler-embeddable-$KV.jar:$TOOLS/kotlin-stdlib-$KV.jar:$TOOLS/kotlin-script-runtime-$KV.jar:$TOOLS/kotlin-reflect-$KV.jar:$TOOLS/kotlin-daemon-embeddable-$KV.jar:$TOOLS/trove4j-1.0.20200330.jar:$TOOLS/kotlinx-coroutines-core-jvm-1.8.0.jar:$TOOLS/annotations-13.0.jar"
echo "• Compiling tests"
# androidx.test stand-ins live outside app/src so they never shadow the real ones in an Android Studio build.
JAVA_SRC=$(find test/androidx-stubs app/src/test/java -name '*.java')
[ -n "$JAVA_SRC" ] && JAVA_TOOL_OPTIONS="" javac -nowarn -source 8 -target 8 -cp "build/classes:$ANDROID_ALL:$TESTCP" -d $T/classes $JAVA_SRC 2>&1 | grep -vE "warning|^Picked up" || true
JAVA_TOOL_OPTIONS="" java -Xmx3g -cp "$KCP" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler -no-reflect -no-stdlib -jvm-target 1.8 -nowarn \
  -classpath "$T/classes:build/classes:$ANDROID_ALL:$TOOLS/kotlin-stdlib-$KV.jar:$TESTCP" -d $T/classes $(find app/src/test/java -name '*.kt')
echo "• Running"
CLASSES=$(cd $T/classes && find . -name '*Test.class' | sed 's|^\./||; s|\.class$||; s|/|.|g' | sort)
java -Xmx3g -Drobolectric.enabledSdks=34 \
  -cp "$T/classes:$T/res:app/src/test/resources:build/classes:$TOOLS/kotlin-stdlib-$KV.jar:$TESTCP:$ANDROID_ALL" \
  org.junit.runner.JUnitCore $CLASSES
