package com.niranjan.deepwork;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.content.pm.Signature;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.provider.Settings;
import android.util.Base64;
import android.view.WindowManager;

import androidx.activity.result.ActivityResult;
import androidx.biometric.BiometricManager;
import androidx.biometric.BiometricPrompt;
import androidx.core.content.ContextCompat;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.google.android.gms.auth.api.identity.AuthorizationRequest;
import com.google.android.gms.auth.api.identity.AuthorizationResult;
import com.google.android.gms.auth.api.identity.Identity;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.Scope;

import org.json.JSONArray;

import java.io.ByteArrayOutputStream;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/** Native features for the Deepwork Android app. Exposed to the web layer as `Deepwork`. */
@CapacitorPlugin(name = "Deepwork")
public class DeepworkPlugin extends Plugin {

    private static final String DRIVE_FILE_SCOPE = "https://www.googleapis.com/auth/drive.file";

    // ------------------------------------------------------------------ app blocking

    @PluginMethod
    public void blockerStatus(PluginCall call) {
        JSObject r = new JSObject();
        r.put("serviceEnabled", isServiceEnabled());
        r.put("active", BlockerState.active(getContext()));
        call.resolve(r);
    }

    private boolean isServiceEnabled() {
        Context c = getContext();
        String enabled = Settings.Secure.getString(c.getContentResolver(), Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
        if (enabled == null) return false;
        String me = new ComponentName(c, BlockerService.class).flattenToString();
        String meShort = new ComponentName(c, BlockerService.class).flattenToShortString();
        for (String s : enabled.split(":")) if (s.equalsIgnoreCase(me) || s.equalsIgnoreCase(meShort)) return true;
        return false;
    }

    @PluginMethod
    public void openBlockerSettings(PluginCall call) {
        Intent i = new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS);
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        getContext().startActivity(i);
        call.resolve();
    }

    @PluginMethod
    public void getInstalledApps(PluginCall call) {
        new Thread(() -> {
            try {
                PackageManager pm = getContext().getPackageManager();
                Intent launcher = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER);
                List<ResolveInfo> list = pm.queryIntentActivities(launcher, 0);
                Set<String> seen = new HashSet<>();
                List<JSObject> apps = new ArrayList<>();
                for (ResolveInfo ri : list) {
                    String pkg = ri.activityInfo.packageName;
                    if (pkg.equals(getContext().getPackageName()) || !seen.add(pkg)) continue;
                    JSObject o = new JSObject();
                    o.put("packageName", pkg);
                    o.put("label", ri.loadLabel(pm).toString());
                    o.put("icon", iconToBase64(ri.loadIcon(pm)));
                    apps.add(o);
                }
                Collections.sort(apps, (a, b) -> a.getString("label", "").toLowerCase(Locale.ROOT).compareTo(b.getString("label", "").toLowerCase(Locale.ROOT)));
                JSArray arr = new JSArray();
                for (JSObject o : apps) arr.put(o);
                JSObject r = new JSObject();
                r.put("apps", arr);
                call.resolve(r);
            } catch (Exception e) {
                call.reject("Could not list apps: " + e.getMessage());
            }
        }).start();
    }

    private String iconToBase64(Drawable d) {
        try {
            int size = 72;
            Bitmap bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888);
            Canvas canvas = new Canvas(bmp);
            d.setBounds(0, 0, size, size);
            d.draw(canvas);
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            bmp.compress(Bitmap.CompressFormat.PNG, 100, out);
            return "data:image/png;base64," + Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP);
        } catch (Exception e) {
            return "";
        }
    }

    @PluginMethod
    public void startBlocking(PluginCall call) {
        Long until = call.getLong("until", 0L);
        String mode = call.getString("mode", "block");
        String task = call.getString("taskTitle", "");
        JSArray pkgs = call.getArray("packages", new JSArray());
        Set<String> set = new HashSet<>();
        try {
            for (int i = 0; i < pkgs.length(); i++) set.add(pkgs.getString(i));
        } catch (Exception ignored) {
        }
        BlockerState.start(getContext(), until == null ? 0 : until, mode, set, task);
        call.resolve();
    }

    @PluginMethod
    public void stopBlocking(PluginCall call) {
        BlockerState.stop(getContext());
        call.resolve();
    }

    @PluginMethod
    public void takeBlockedAttempts(PluginCall call) {
        JSONArray arr = BlockerState.takeAttempts(getContext());
        JSObject r = new JSObject();
        try {
            r.put("attempts", new JSArray(arr.toString()));
        } catch (Exception e) {
            r.put("attempts", new JSArray());
        }
        call.resolve(r);
    }

    // ------------------------------------------------------------------ keep screen on

    @PluginMethod
    public void setKeepAwake(PluginCall call) {
        boolean on = Boolean.TRUE.equals(call.getBoolean("on", false));
        Activity a = getActivity();
        a.runOnUiThread(() -> {
            if (on) a.getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            else a.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            call.resolve();
        });
    }

    // ------------------------------------------------------------------ biometrics

    @PluginMethod
    public void biometricAvailable(PluginCall call) {
        int res = BiometricManager.from(getContext()).canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK);
        JSObject r = new JSObject();
        r.put("available", res == BiometricManager.BIOMETRIC_SUCCESS);
        call.resolve(r);
    }

    @PluginMethod
    public void authenticate(PluginCall call) {
        String title = call.getString("title", "Unlock Deepwork");
        getActivity().runOnUiThread(() -> {
            BiometricPrompt prompt = new BiometricPrompt(getActivity(), ContextCompat.getMainExecutor(getContext()), new BiometricPrompt.AuthenticationCallback() {
                @Override
                public void onAuthenticationSucceeded(BiometricPrompt.AuthenticationResult result) {
                    JSObject r = new JSObject();
                    r.put("success", true);
                    call.resolve(r);
                }

                @Override
                public void onAuthenticationError(int errorCode, CharSequence errString) {
                    JSObject r = new JSObject();
                    r.put("success", false);
                    r.put("error", errString.toString());
                    call.resolve(r);
                }
            });
            BiometricPrompt.PromptInfo info = new BiometricPrompt.PromptInfo.Builder()
                .setTitle(title)
                .setNegativeButtonText("Use PIN")
                .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_WEAK)
                .build();
            prompt.authenticate(info);
        });
    }

    // ------------------------------------------------------------------ Google Drive authorization

    /**
     * Gets a Drive access token for the drive.file scope. When the user has already granted
     * access this returns silently; otherwise it shows Google's consent screen if `interactive`.
     */
    @PluginMethod
    public void googleAuthorize(PluginCall call) {
        boolean interactive = Boolean.TRUE.equals(call.getBoolean("interactive", true));
        List<Scope> scopes = new ArrayList<>();
        scopes.add(new Scope(DRIVE_FILE_SCOPE));
        AuthorizationRequest req = AuthorizationRequest.builder().setRequestedScopes(scopes).build();
        Identity.getAuthorizationClient(getActivity())
            .authorize(req)
            .addOnSuccessListener(result -> {
                if (result.hasResolution()) {
                    if (!interactive) {
                        call.reject("Google sign-in needed", "NEEDS_CONSENT");
                        return;
                    }
                    PendingIntent pi = result.getPendingIntent();
                    Intent i = new Intent(getContext(), GoogleAuthActivity.class);
                    i.putExtra("pendingIntent", pi);
                    startActivityForResult(call, i, "onGoogleAuthResult");
                } else {
                    resolveToken(call, result);
                }
            })
            .addOnFailureListener(e -> call.reject(friendlyAuthError(e), "AUTH_FAILED"));
    }

    @ActivityCallback
    private void onGoogleAuthResult(PluginCall call, ActivityResult activityResult) {
        if (call == null) return;
        if (activityResult.getResultCode() != Activity.RESULT_OK || activityResult.getData() == null) {
            call.reject("Google sign-in was cancelled.", "CANCELLED");
            return;
        }
        try {
            AuthorizationResult result = Identity.getAuthorizationClient(getActivity()).getAuthorizationResultFromIntent(activityResult.getData());
            resolveToken(call, result);
        } catch (ApiException e) {
            call.reject(friendlyAuthError(e), "AUTH_FAILED");
        }
    }

    private void resolveToken(PluginCall call, AuthorizationResult result) {
        String token = result.getAccessToken();
        if (token == null) {
            call.reject("Google did not return an access token.", "AUTH_FAILED");
            return;
        }
        JSObject r = new JSObject();
        r.put("accessToken", token);
        // Google access tokens last one hour; report slightly less to be safe.
        r.put("expiresIn", 3300);
        call.resolve(r);
    }

    private String friendlyAuthError(Exception e) {
        if (e instanceof ApiException) {
            int code = ((ApiException) e).getStatusCode();
            if (code == 10) {
                return "Google rejected this app (developer error). Add an Android OAuth client for package "
                    + getContext().getPackageName() + " with this app's SHA-1 in Google Cloud Console (see Settings → Backup).";
            }
            return "Google sign-in failed (code " + code + ").";
        }
        return e.getMessage() == null ? "Google sign-in failed." : e.getMessage();
    }

    /** Package name and signing-certificate SHA-1, needed to create the Android OAuth client. */
    @PluginMethod
    public void getSigningInfo(PluginCall call) {
        JSObject r = new JSObject();
        r.put("packageName", getContext().getPackageName());
        try {
            PackageManager pm = getContext().getPackageManager();
            Signature[] sigs;
            if (Build.VERSION.SDK_INT >= 28) {
                PackageInfo info = pm.getPackageInfo(getContext().getPackageName(), PackageManager.GET_SIGNING_CERTIFICATES);
                sigs = info.signingInfo.getApkContentsSigners();
            } else {
                @SuppressWarnings("deprecation")
                PackageInfo info = pm.getPackageInfo(getContext().getPackageName(), PackageManager.GET_SIGNATURES);
                sigs = info.signatures;
            }
            if (sigs != null && sigs.length > 0) {
                MessageDigest md = MessageDigest.getInstance("SHA-1");
                byte[] d = md.digest(sigs[0].toByteArray());
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < d.length; i++) {
                    if (i > 0) sb.append(':');
                    sb.append(String.format(Locale.ROOT, "%02X", d[i]));
                }
                r.put("sha1", sb.toString());
            }
        } catch (Exception e) {
            r.put("sha1", "");
        }
        call.resolve(r);
    }
}
