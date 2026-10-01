// Minimal stand-in for androidx.test (Google Maven isn't reachable from the build machine). Test-only.
package androidx.test.internal.runner.intent;
public final class IntentMonitorImpl implements androidx.test.runner.intent.IntentMonitor { public IntentMonitorImpl() {} public void signalIntent(android.content.Intent i) {} }
