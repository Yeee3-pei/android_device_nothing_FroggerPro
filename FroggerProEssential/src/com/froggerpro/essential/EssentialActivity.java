// FroggerPro Essential —— 仿 Nothing Essential Space，專門對應左側 Essential Key
// 觸發：左側鍵 ⇒ key 250 ⇒ ASSIST intent ⇒ 本 App 接住
package com.froggerpro.essential;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.List;

/**
 * Essential Space 主畫面：擷取清單 ＋ 快速新增。
 * 由左側 Essential Key（ASSIST intent）喚起。
 */
public class EssentialActivity extends Activity {

    private CaptureStore store;
    private ArrayAdapter<String> adapter;
    private final List<Capture> items = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        store = new CaptureStore(this);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        int pad = (int) (16 * getResources().getDisplayMetrics().density);
        root.setPadding(pad, pad, pad, pad);

        TextView title = new TextView(this);
        title.setText("Essential Space");
        title.setTextSize(22);
        root.addView(title);

        TextView hint = new TextView(this);
        hint.setText("按左側鍵隨時開啟。這裡是你的快速擷取空間。");
        hint.setTextSize(13);
        root.addView(hint);

        Button add = new Button(this);
        add.setText("＋ 新增擷取");
        add.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { showAddDialog(); }
        });
        root.addView(add);

        ListView list = new ListView(this);
        adapter = new ArrayAdapter<>(this, android.R.layout.simple_list_item_1, new ArrayList<String>());
        list.setAdapter(adapter);
        list.setOnItemLongClickListener((parent, view, pos, id) -> {
            confirmDelete(pos);
            return true;
        });
        root.addView(list, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        setContentView(root);
        reload();
    }

    /** 從 ASSIST 意圖進來時，直接跳到新增（＝按鍵即擷取 ✓） */
    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        if (intent != null && Intent.ACTION_ASSIST.equals(intent.getAction())) {
            showAddDialog();
        }
    }

    private void reload() {
        items.clear();
        items.addAll(store.all());
        adapter.clear();
        for (Capture c : items) {
            adapter.add("[" + c.kind + "] " + c.text);
        }
        adapter.notifyDataSetChanged();
    }

    private void showAddDialog() {
        final EditText input = new EditText(this);
        input.setHint("隨手記一句…");
        new AlertDialog.Builder(this)
                .setTitle("新增擷取")
                .setView(input)
                .setPositiveButton("存成筆記", (d, w) -> {
                    String t = input.getText().toString().trim();
                    if (t.isEmpty()) { toast("沒有內容"); return; }
                    store.add("note", t);
                    reload();
                    toast("已儲存 ✓");
                })
                .setNegativeButton("取消", null)
                .show();
    }

    private void confirmDelete(final int pos) {
        if (pos < 0 || pos >= items.size()) return;
        final Capture c = items.get(pos);
        new AlertDialog.Builder(this)
                .setTitle("刪除這則擷取？")
                .setMessage(c.text)
                .setPositiveButton("刪除", (d, w) -> { store.delete(c.id); reload(); })
                .setNegativeButton("取消", null)
                .show();
    }

    private void toast(String s) {
        Toast.makeText(this, s, Toast.LENGTH_SHORT).show();
    }
}