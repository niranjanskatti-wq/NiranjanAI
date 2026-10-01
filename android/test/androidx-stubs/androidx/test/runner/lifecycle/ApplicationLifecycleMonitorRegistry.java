// Minimal stand-in for androidx.test (Google Maven isn't reachable from the build machine). Test-only.
package androidx.test.runner.lifecycle;
public final class ApplicationLifecycleMonitorRegistry {
  private static ApplicationLifecycleMonitor m;
  public static ApplicationLifecycleMonitor getInstance() { return m; }
  public static void registerInstance(ApplicationLifecycleMonitor x) { m = x; }
}
