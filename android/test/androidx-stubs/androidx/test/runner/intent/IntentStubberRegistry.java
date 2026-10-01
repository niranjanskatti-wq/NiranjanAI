// Minimal stand-in for androidx.test (Google Maven isn't reachable from the build machine). Test-only.
package androidx.test.runner.intent;
public final class IntentStubberRegistry { public static IntentStubber getInstance() { return null; } public static boolean isLoaded() { return false; } }
