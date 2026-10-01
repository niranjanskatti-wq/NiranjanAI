// Minimal stand-in for androidx.test (Google Maven isn't reachable from the build machine). Test-only.
package androidx.test.runner.lifecycle;
public interface ActivityLifecycleCallback { void onActivityLifecycleChanged(android.app.Activity a, Stage s); }
