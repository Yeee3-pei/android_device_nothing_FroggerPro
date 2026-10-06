// 擷取資料模型
package com.froggerpro.essential;

public class Capture {
    public final long id;
    public final String kind;   // note / voice / shot
    public final String text;
    public final long at;

    public Capture(long id, String kind, String text, long at) {
        this.id = id;
        this.kind = kind;
        this.text = text;
        this.at = at;
    }
}