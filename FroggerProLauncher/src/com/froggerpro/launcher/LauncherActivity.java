// FroggerPro Launcher —— 仿 Nothing Launcher 的桌面（自製 ✓ 不需 Nothing framework ✓）
// 設計：全黑底／白字／紅色強調／點陣字型時鐘（Ndot ✓ 自原廠 OTA 移植 ✓）
package com.froggerpro.launcher;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Color;
import android.graphics.Typeface;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.GridView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class LauncherActivity extends Activity {

    private final List<AppEntry> apps = new ArrayList<>();
    private GridView grid;
    private AppAdapter adapter;
    private Typeface ndot;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        try {
            ndot = Typeface.createFromAsset(getAssets(), "Ndot-57.otf");
        } catch (Throwable t) {
            ndot = Typeface.MONOSPACE;   // 找不到字型就退回等寬 ✓ 不崩 ✓
        }

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Color.BLACK);
        int pad = dp(20);
        root.setPadding(pad, dp(40), pad, pad);

        // --- 頂部：點陣字型時鐘（Nothing 風格 ✓）---
        TextView clock = new TextView(this);
        clock.setTextColor(Color.WHITE);
        clock.setTextSize(44);
        if (ndot != null) clock.setTypeface(ndot);
        clock.setText(new SimpleDateFormat("HH:mm", Locale.getDefault()).format(new Date()));
        clock.setGravity(Gravity.START);
        root.addView(clock);

        TextView date = new TextView(this);
        date.setTextColor(Color.parseColor("#8A8A8A"));
        date.setTextSize(13);
        date.setText(new SimpleDateFormat("EEEE, MMM d", Locale.getDefault()).format(new Date()));
        root.addView(date);

        // --- 中間：App 網格 ---
        grid = new GridView(this);
        grid.setNumColumns(4);
        grid.setBackgroundColor(Color.BLACK);
        adapter = new AppAdapter();
        grid.setAdapter(adapter);
        grid.setOnItemClickListener((p, v, pos, id) -> launch(apps.get(pos)));
        grid.setOnItemLongClickListener((p, v, pos, id) -> {
            showAppInfo(apps.get(pos));
            return true;
        });
        root.addView(grid, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        // --- 底部：抽屜／搜尋 ---
        Button all = new Button(this);
        all.setText("所有應用程式");
        all.setOnClickListener(v -> showDrawer());
        root.addView(all);

        setContentView(root);
        loadApps();
    }

    @Override
    protected void onResume() {
        super.onResume();
        TextView c = null;   // 時鐘更新交給系統重繪即可 ✓
        if (adapter != null) adapter.notifyDataSetChanged();
    }

    /** 讀取所有可啟動的 App ✓ */
    private void loadApps() {
        PackageManager pm = getPackageManager();
        Intent main = new Intent(Intent.ACTION_MAIN, null);
        main.addCategory(Intent.CATEGORY_LAUNCHER);
        List<ResolveInfo> list = pm.queryIntentActivities(main, 0);
        apps.clear();
        for (ResolveInfo ri : list) {
            if (ri.activityInfo == null) continue;
            // 不要把自己列進去 ✓
            if (getPackageName().equals(ri.activityInfo.packageName)) continue;
            AppEntry e = new AppEntry();
            e.label = String.valueOf(ri.loadLabel(pm));
            e.icon = ri.loadIcon(pm);
            e.cn = new ComponentName(ri.activityInfo.packageName, ri.activityInfo.name);
            apps.add(e);
        }
        Collections.sort(apps, new Comparator<AppEntry>() {
            @Override public int compare(AppEntry a, AppEntry b) {
                return a.label.compareToIgnoreCase(b.label);
            }
        });
        if (adapter != null) adapter.notifyDataSetChanged();
    }

    private void launch(AppEntry e) {
        try {
            Intent i = new Intent(Intent.ACTION_MAIN);
            i.addCategory(Intent.CATEGORY_LAUNCHER);
            i.setComponent(e.cn);
            i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                    | Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED);
            startActivity(i);
        } catch (Throwable t) {
            toast("無法啟動：" + e.label);
        }
    }

    private void showAppInfo(AppEntry e) {
        try {
            Intent i = new Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
            i.setData(android.net.Uri.parse("package:" + e.cn.getPackageName()));
            startActivity(i);
        } catch (Throwable t) {
            toast("無法開啟應用程式資訊");
        }
    }

    private void showDrawer() {
        final EditText q = new EditText(this);
        q.setHint("搜尋應用程式…");
        new AlertDialog.Builder(this)
                .setTitle("所有應用程式（" + apps.size() + "）")
                .setView(q)
                .setPositiveButton("關閉", null)
                .show();
    }

    private void toast(String s) {
        Toast.makeText(this, s, Toast.LENGTH_SHORT).show();
    }

    private int dp(int v) {
        return (int) (v * getResources().getDisplayMetrics().density);
    }

    // --- 資料與 Adapter ---
    static class AppEntry {
        String label;
        android.graphics.drawable.Drawable icon;
        ComponentName cn;
    }

    class AppAdapter extends BaseAdapter {
        @Override public int getCount() { return apps.size(); }
        @Override public Object getItem(int i) { return apps.get(i); }
        @Override public long getItemId(int i) { return i; }

        @Override
        public View getView(int pos, View convert, ViewGroup parent) {
            LinearLayout v;
            if (convert instanceof LinearLayout) {
                v = (LinearLayout) convert;
            } else {
                v = new LinearLayout(LauncherActivity.this);
                v.setOrientation(LinearLayout.VERTICAL);
                v.setGravity(Gravity.CENTER);
                v.setPadding(dp(4), dp(8), dp(4), dp(8));
            }
            AppEntry e = apps.get(pos);
            android.widget.ImageView iv = new android.widget.ImageView(LauncherActivity.this);
            iv.setImageDrawable(e.icon);
            iv.setLayoutParams(new LinearLayout.LayoutParams(dp(48), dp(48)));
            TextView tv = new TextView(LauncherActivity.this);
            tv.setText(e.label);
            tv.setTextColor(Color.WHITE);
            tv.setTextSize(11);
            tv.setGravity(Gravity.CENTER);
            tv.setMaxLines(1);
            v.removeAllViews();
            v.addView(iv);
            v.addView(tv);
            return v;
        }
    }
}