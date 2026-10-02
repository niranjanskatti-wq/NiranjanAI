package com.niranjan.deepwork;

import android.app.PendingIntent;
import android.content.Intent;
import android.os.Bundle;

import androidx.activity.ComponentActivity;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.IntentSenderRequest;
import androidx.activity.result.contract.ActivityResultContracts;

/** Hosts Google's consent screen (a PendingIntent) and hands the result back to the plugin. */
public class GoogleAuthActivity extends ComponentActivity {

    private ActivityResultLauncher<IntentSenderRequest> launcher;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        launcher = registerForActivityResult(new ActivityResultContracts.StartIntentSenderForResult(), result -> {
            setResult(result.getResultCode(), result.getData());
            finish();
        });
        if (savedInstanceState != null) return;
        PendingIntent pi = getIntent().getParcelableExtra("pendingIntent");
        if (pi == null) {
            setResult(RESULT_CANCELED);
            finish();
            return;
        }
        launcher.launch(new IntentSenderRequest.Builder(pi.getIntentSender()).build());
    }
}
