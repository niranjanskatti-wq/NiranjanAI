package com.niranjan.deepwork;

import android.accessibilityservice.AccessibilityService;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.view.accessibility.AccessibilityEvent;
import android.view.inputmethod.InputMethodInfo;
import android.view.inputmethod.InputMethodManager;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Watches which app comes to the foreground. During a focus session, opening a blocked app
 * shows the "stay focused" screen instead. Nothing is recorded or sent anywhere except the
 * attempt log that Deepwork itself reads back as a distraction.
 */
public class BlockerService extends AccessibilityService {

    private final Set<String> alwaysAllowed = new HashSet<>();

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        refreshAlwaysAllowed();
    }

    private void refreshAlwaysAllowed() {
        alwaysAllowed.clear();
        alwaysAllowed.add(getPackageName());
        alwaysAllowed.add("com.android.systemui");
        alwaysAllowed.add("android");
        PackageManager pm = getPackageManager();
        // Home screens / launchers.
        Intent home = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME);
        for (ResolveInfo ri : pm.queryIntentActivities(home, 0)) alwaysAllowed.add(ri.activityInfo.packageName);
        // Phone / dialer, so calls (including emergency calls) always work.
        Intent dial = new Intent(Intent.ACTION_DIAL);
        for (ResolveInfo ri : pm.queryIntentActivities(dial, 0)) alwaysAllowed.add(ri.activityInfo.packageName);
        // Keyboards.
        InputMethodManager imm = (InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);
        if (imm != null) {
            List<InputMethodInfo> list = imm.getEnabledInputMethodList();
            for (InputMethodInfo info : list) alwaysAllowed.add(info.getPackageName());
        }
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        if (event == null || event.getEventType() != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return;
        CharSequence pkgSeq = event.getPackageName();
        if (pkgSeq == null) return;
        String pkg = pkgSeq.toString();
        if (!BlockerState.active(this)) return;
        if (alwaysAllowed.isEmpty()) refreshAlwaysAllowed();
        if (alwaysAllowed.contains(pkg)) return;

        Set<String> list = BlockerState.packages(this);
        boolean allowMode = "allow".equals(BlockerState.mode(this));
        boolean blocked = allowMode ? !list.contains(pkg) && isUserFacingApp(pkg) : list.contains(pkg);
        if (!blocked) return;

        String label = labelFor(pkg);
        BlockerState.recordAttempt(this, pkg, label);
        Intent i = new Intent(this, BlockedActivity.class);
        i.putExtra("label", label);
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NO_ANIMATION);
        startActivity(i);
    }

    /** In allow-list mode only block real apps with a launcher icon, not system overlays. */
    private boolean isUserFacingApp(String pkg) {
        return getPackageManager().getLaunchIntentForPackage(pkg) != null;
    }

    private String labelFor(String pkg) {
        try {
            PackageManager pm = getPackageManager();
            ApplicationInfo ai = pm.getApplicationInfo(pkg, 0);
            return pm.getApplicationLabel(ai).toString();
        } catch (Exception e) {
            return pkg;
        }
    }

    @Override
    public void onInterrupt() {}
}
