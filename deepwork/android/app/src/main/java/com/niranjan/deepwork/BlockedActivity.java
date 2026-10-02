package com.niranjan.deepwork;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

/** Full-screen "stay focused" screen shown when a blocked app is opened during a session. */
public class BlockedActivity extends Activity {

    private final Handler handler = new Handler(Looper.getMainLooper());
    private TextView remaining;

    private final Runnable tick = new Runnable() {
        @Override
        public void run() {
            long left = BlockerState.until(BlockedActivity.this) - System.currentTimeMillis();
            if (left <= 0) {
                finish();
                return;
            }
            long min = (left + 59_999) / 60_000;
            remaining.setText(min == 1 ? "1 minute left in this session" : min + " minutes left in this session");
            handler.postDelayed(this, 5_000);
        }
    };

    private int dp(int v) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, getResources().getDisplayMetrics());
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.parseColor("#0B0B0F"));
        getWindow().setNavigationBarColor(Color.parseColor("#0B0B0F"));

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER);
        root.setBackgroundColor(Color.parseColor("#0B0B0F"));
        root.setPadding(dp(32), dp(32), dp(32), dp(32));

        View ring = new View(this);
        GradientDrawable ringBg = new GradientDrawable();
        ringBg.setShape(GradientDrawable.OVAL);
        ringBg.setStroke(dp(6), Color.parseColor("#7C7CFF"));
        ring.setBackground(ringBg);
        LinearLayout.LayoutParams ringLp = new LinearLayout.LayoutParams(dp(72), dp(72));
        ringLp.bottomMargin = dp(28);
        root.addView(ring, ringLp);

        String label = getIntent().getStringExtra("label");
        TextView title = new TextView(this);
        title.setText("Stay with it");
        title.setTextColor(Color.parseColor("#EDEDF2"));
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 28);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        title.setGravity(Gravity.CENTER);
        root.addView(title);

        TextView body = new TextView(this);
        String task = BlockerState.task(this);
        String text = (label != null ? label : "This app") + " is paused while you focus"
            + (task != null && !task.isEmpty() ? " on “" + task + "”." : ".");
        body.setText(text);
        body.setTextColor(Color.parseColor("#8A8A99"));
        body.setTextSize(TypedValue.COMPLEX_UNIT_SP, 16);
        body.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams bodyLp = new LinearLayout.LayoutParams(-1, -2);
        bodyLp.topMargin = dp(12);
        root.addView(body, bodyLp);

        remaining = new TextView(this);
        remaining.setTextColor(Color.parseColor("#7C7CFF"));
        remaining.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
        remaining.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams remLp = new LinearLayout.LayoutParams(-1, -2);
        remLp.topMargin = dp(20);
        root.addView(remaining, remLp);

        Button back = new Button(this);
        back.setText("Back to Deepwork");
        back.setAllCaps(false);
        back.setTextColor(Color.WHITE);
        back.setTextSize(TypedValue.COMPLEX_UNIT_SP, 16);
        GradientDrawable btnBg = new GradientDrawable();
        btnBg.setColor(Color.parseColor("#7C7CFF"));
        btnBg.setCornerRadius(dp(12));
        back.setBackground(btnBg);
        LinearLayout.LayoutParams backLp = new LinearLayout.LayoutParams(-1, dp(52));
        backLp.topMargin = dp(40);
        root.addView(back, backLp);
        back.setOnClickListener(v -> {
            Intent i = new Intent(this, MainActivity.class);
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            startActivity(i);
            finish();
        });

        Button home = new Button(this);
        home.setText("Go to home screen");
        home.setAllCaps(false);
        home.setTextColor(Color.parseColor("#8A8A99"));
        home.setBackgroundColor(Color.TRANSPARENT);
        LinearLayout.LayoutParams homeLp = new LinearLayout.LayoutParams(-1, dp(48));
        homeLp.topMargin = dp(8);
        root.addView(home, homeLp);
        home.setOnClickListener(v -> goHome());

        setContentView(root);
    }

    private void goHome() {
        Intent i = new Intent(Intent.ACTION_MAIN);
        i.addCategory(Intent.CATEGORY_HOME);
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(i);
        finish();
    }

    @Override
    protected void onResume() {
        super.onResume();
        handler.post(tick);
    }

    @Override
    protected void onPause() {
        super.onPause();
        handler.removeCallbacks(tick);
    }

    @Override
    @SuppressWarnings("deprecation")
    public void onBackPressed() {
        // Back should not reveal the blocked app underneath.
        goHome();
    }
}
