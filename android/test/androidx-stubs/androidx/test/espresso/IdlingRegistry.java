// Minimal stand-in for androidx.test (Google Maven isn't reachable from the build machine). Test-only.
package androidx.test.espresso;
import java.util.*;
public final class IdlingRegistry { private static final IdlingRegistry I = new IdlingRegistry();
  public static IdlingRegistry getInstance() { return I; }
  public Collection<android.os.Looper> getLoopers() { return Collections.emptyList(); }
  public Collection<IdlingResource> getResources() { return Collections.emptyList(); } }
