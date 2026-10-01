// Minimal stand-in for androidx.test (Google Maven isn't reachable from the build machine). Test-only.
package androidx.test.runner.intent;
public interface IntentStubber { android.app.Instrumentation.ActivityResult getActivityResultForIntent(android.content.Intent i); }
