// 簡單的 SQLite 儲存（app 私有空間 ✓ 不上傳 ✓ 符合隱私版原則）
package com.froggerpro.essential;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import java.util.ArrayList;
import java.util.List;

public class CaptureStore extends SQLiteOpenHelper {

    private static final String DB = "essential.db";
    private static final int V = 1;

    public CaptureStore(Context c) {
        super(c, DB, null, V);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        db.execSQL("CREATE TABLE captures (" +
                "_id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "kind TEXT NOT NULL," +
                "text TEXT NOT NULL," +
                "at INTEGER NOT NULL)");
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int o, int n) {
        db.execSQL("DROP TABLE IF EXISTS captures");
        onCreate(db);
    }

    public long add(String kind, String text) {
        ContentValues v = new ContentValues();
        v.put("kind", kind);
        v.put("text", text);
        v.put("at", System.currentTimeMillis());
        return getWritableDatabase().insert("captures", null, v);
    }

    public void delete(long id) {
        getWritableDatabase().delete("captures", "_id=?",
                new String[]{String.valueOf(id)});
    }

    public List<Capture> all() {
        List<Capture> out = new ArrayList<>();
        Cursor c = getReadableDatabase().rawQuery(
                "SELECT _id, kind, text, at FROM captures ORDER BY at DESC", null);
        try {
            while (c.moveToNext()) {
                out.add(new Capture(c.getLong(0), c.getString(1),
                        c.getString(2), c.getLong(3)));
            }
        } finally {
            c.close();
        }
        return out;
    }
}