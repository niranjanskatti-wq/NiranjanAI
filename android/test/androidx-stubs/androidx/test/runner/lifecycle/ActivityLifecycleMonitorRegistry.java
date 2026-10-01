// Minimal stand-in for androidx.test (Google Maven isn't reachable from the build machine). Test-only.
package androidx.test.runner.lifecycle;
public final class ActivityLifecycleMonitorRegistry {
  private static ActivityLifecycleMonitor m;
  public static ActivityLifecycleMonitor getInstance() { return m; }
  public static void registerInstance(ActivityLifecycleMonitor x) { m = x; }
}
