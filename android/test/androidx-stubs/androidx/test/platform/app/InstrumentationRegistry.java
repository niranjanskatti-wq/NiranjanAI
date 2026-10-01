// Minimal stand-in for androidx.test (Google Maven isn't reachable from the build machine). Test-only.
package androidx.test.platform.app;
import android.app.Instrumentation; import android.os.Bundle;
public final class InstrumentationRegistry {
  private static Instrumentation inst; private static Bundle args = new Bundle();
  public static void registerInstance(Instrumentation i, Bundle b) { inst = i; args = b == null ? new Bundle() : b; }
  public static Instrumentation getInstrumentation() { return inst; }
  public static Bundle getArguments() { return args; }
}
