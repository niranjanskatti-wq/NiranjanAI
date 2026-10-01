// Minimal stand-in for androidx.test (Google Maven isn't reachable from the build machine). Test-only.
package androidx.test.runner.lifecycle;
public enum Stage { PRE_ON_CREATE, CREATED, STARTED, RESUMED, PAUSED, STOPPED, RESTARTED, DESTROYED }
