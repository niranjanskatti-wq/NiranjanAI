// Minimal stand-in for androidx.test (Google Maven isn't reachable from the build machine). Test-only.
package androidx.test.internal.runner.lifecycle;
import androidx.test.runner.lifecycle.*;
public final class ApplicationLifecycleMonitorImpl implements ApplicationLifecycleMonitor {
  public ApplicationLifecycleMonitorImpl() {}
  public void signalLifecycleChange(android.app.Application app, ApplicationStage s) {}
}
