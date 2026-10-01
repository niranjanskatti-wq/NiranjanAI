// Minimal stand-in for androidx.test (Google Maven isn't reachable from the build machine). Test-only.
package androidx.test.espresso;
public interface IdlingResource { String getName(); boolean isIdleNow(); void registerIdleTransitionCallback(ResourceCallback c); interface ResourceCallback { void onTransitionToIdle(); } }
