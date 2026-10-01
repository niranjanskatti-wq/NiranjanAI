// Minimal stand-in for androidx.test (Google Maven isn't reachable from the build machine). Test-only.
package androidx.test.runner.intent;
public final class IntentMonitorRegistry { private static IntentMonitor m; public static void registerInstance(IntentMonitor x) { m = x; } public static IntentMonitor getInstance() { return m; } }
