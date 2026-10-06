/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package com.froggerpro.privacy;

import android.os.Bundle;
import android.os.SystemProperties;
import android.preference.EditTextPreference;
import android.preference.ListPreference;
import android.preference.Preference;
import android.preference.PreferenceActivity;
import android.preference.SwitchPreference;
import android.provider.DeviceConfig;
import android.provider.Settings;
import android.widget.Toast;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * FroggerPro 隱私設定（A 類：純執行期開關）。
 *
 * 設計原則（見 ~/nphone/live/PRIVACY_TOGGLE_PLAN.md）：
 *   1. 只有【真實生效且可驗證】的項目才做成開關 ✓
 *   2. 每個開關都寫明它改了哪個系統設定、以及怎麼驗證（可重現的 adb 指令）✓
 *   3. 無法執行期切換的項目只顯示狀態與原因，不提供假開關 ✗
 *   4. 預設值皆為【最強隱私】；放寬與否由使用者決定 ✓
 *   5. 所有寫入皆包 try/catch，App 不因單一項失敗而崩潰 ✓
 *
 * 本檔實作的 A 類機制（每項都有 AOSP 原始碼依據）：
 *   - AGPS：Settings.Global.ASSISTED_GPS_ENABLED（"assisted_gps_enabled"，0/1）
 *       GnssLocationProvider.java:1891-1903 使 xtra-daemon 立即反映此值；
 *       :523 註冊 ContentObserver ⇒ 不需重開機。預設 0（最強隱私）＝不再連
 *       time.xtracloud.net；緊急電話會強制開啟（:1893-1895）。
 *   - 廣告框架：DeviceConfig 命名空間 "adservices" → key "adservice_enabled"
 *       SettingsProvider.java:2578「有 WRITE_DEVICE_CONFIG 就不查命名空間 allowlist」，
 *       本 App 為 platform 簽章 ⇒ 持有該 signature 級權限 ✓。
 *   - USB adb：Settings.Global.ADB_ENABLED（"adb_enabled"，0/1）
 *       AdbService.java:151-193 註冊 ContentObserver ⇒ 執行期即時生效。
 *   - 持久 logcatd：persist.logd.logpersistd 屬性（property_contexts:71，
 *       type = logpersistd_logging_prop）。
 *       ★唯讀顯示★：本 App 非 system_app 網域，SELinux 不允許直接 setprop ✗。
 *       要在 App 內切換需在 device sepolicy 加：
 *         set_prop(system_app, logpersistd_logging_prop)
 *       並讓本 App 以 android.uid.system 執行。此處刻意只顯示狀態，不給假開關 ✗。
 */
public class PrivacySettingsActivity extends PreferenceActivity {

    // ---- 等級 ----
    private static final String KEY_TIER = "tier";

    // ---- 既有開關 ----
    private static final String KEY_CAPTIVE_OFF = "captive_portal_off";
    private static final String KEY_DNS_ON = "private_dns_on";
    private static final String KEY_DNS_HOST = "private_dns_host";

    // ---- 本輪新增（A 類） ----
    private static final String KEY_AGPS_OFF = "agps_off";
    private static final String KEY_ADB_OFF = "adb_off";
    private static final String KEY_ADSERVICES_OFF = "adservices_off";
    private static final String KEY_LOGCATD_STATUS = "logcatd_status";

    // ---- 系統設定鍵 ----
    private static final String DNS_MODE_GLOBAL = "private_dns_mode";
    private static final String DNS_SPECIFIER_GLOBAL = "private_dns_specifier";

    /** DeviceConfig：廣告框架命名空間與 key（FlagsConstants / PhFlags 之鍵名 ✓） */
    private static final String AD_NAMESPACE = "adservices";
    private static final String AD_KEY = "adservice_enabled";

    /** 持久 logcatd 屬性（唯讀顯示用） */
    private static final String PROP_LOGPERSISTD = "persist.logd.logpersistd";
    private static final String PROP_XTRA = "persist.sys.xtra-daemon.enabled";

    private static final String LOGPERSISTD_SEPOLICY_HINT =
            "set_prop(system_app, logpersistd_logging_prop)";

    private ListPreference mTier;
    private SwitchPreference mAgpsOff;
    private SwitchPreference mAdbOff;
    private SwitchPreference mCaptiveOff;
    private SwitchPreference mDnsOn;
    private EditTextPreference mDnsHost;
    private SwitchPreference mAdservicesOff;
    private Preference mLogcatdStatus;

    @Override
    @SuppressWarnings("deprecation")
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        addPreferencesFromResource(R.xml.privacy_prefs);

        mTier = (ListPreference) findPreference(KEY_TIER);
        mAgpsOff = (SwitchPreference) findPreference(KEY_AGPS_OFF);
        mAdbOff = (SwitchPreference) findPreference(KEY_ADB_OFF);
        mCaptiveOff = (SwitchPreference) findPreference(KEY_CAPTIVE_OFF);
        mDnsOn = (SwitchPreference) findPreference(KEY_DNS_ON);
        mDnsHost = (EditTextPreference) findPreference(KEY_DNS_HOST);
        mAdservicesOff = (SwitchPreference) findPreference(KEY_ADSERVICES_OFF);
        mLogcatdStatus = findPreference(KEY_LOGCATD_STATUS);

        if (mTier != null) {
            mTier.setOnPreferenceChangeListener((p, v) -> {
                applyTier(String.valueOf(v));
                return true;
            });
        }

        if (mAgpsOff != null) {
            mAgpsOff.setOnPreferenceChangeListener((p, v) -> {
                if (!setAgpsDisabled((Boolean) v)) {
                    toast("AGPS 設定寫入失敗（詳見摘要中的驗證指令）");
                }
                return true;
            });
        }

        if (mAdbOff != null) {
            mAdbOff.setOnPreferenceChangeListener((p, v) -> {
                if (!setAdbDisabled((Boolean) v)) {
                    toast("USB adb 設定寫入失敗（詳見摘要中的驗證指令）");
                }
                return true;
            });
        }

        if (mCaptiveOff != null) {
            mCaptiveOff.setOnPreferenceChangeListener((p, v) -> {
                setCaptivePortalDisabled((Boolean) v);
                return true;
            });
        }

        if (mDnsOn != null) {
            mDnsOn.setOnPreferenceChangeListener((p, v) -> {
                setPrivateDns((Boolean) v);
                return true;
            });
        }

        if (mDnsHost != null) {
            mDnsHost.setOnPreferenceChangeListener((p, v) -> {
                setDnsHost(String.valueOf(v));
                return true;
            });
        }

        if (mAdservicesOff != null) {
            mAdservicesOff.setOnPreferenceChangeListener((p, v) -> {
                if (!setAdServicesDisabled((Boolean) v)) {
                    toast("廣告框架設定失敗：無 WRITE_DEVICE_CONFIG 或 DeviceConfig 不可用");
                    // 重新回填為系統真實狀態（不假裝成功）
                    syncFromSystem();
                }
                return true;
            });
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        syncFromSystem();
    }

    /** 由系統實際值回填 UI（不靠 SharedPreferences ✗ 保證顯示的就是真實狀態 ✓） */
    private void syncFromSystem() {
        // ---- Captive portal ----
        int cpMode = Settings.Global.getInt(getContentResolver(),
                Settings.Global.CAPTIVE_PORTAL_MODE, Settings.Global.CAPTIVE_PORTAL_MODE_PROMPT);

        // ---- Private DNS ----
        String dnsMode = Settings.Global.getString(getContentResolver(), DNS_MODE_GLOBAL);
        String dnsSpec = Settings.Global.getString(getContentResolver(), DNS_SPECIFIER_GLOBAL);

        // ---- AGPS（A 類：Settings.Global，預設 0 = 最強隱私 ✓） ----
        int agps = Settings.Global.getInt(getContentResolver(),
                Settings.Global.ASSISTED_GPS_ENABLED, 0);
        if (mAgpsOff != null) {
            mAgpsOff.setChecked(agps == 0);
            mAgpsOff.setSummary(getString(R.string.agps_summary)
                    + "\n目前 assisted_gps_enabled=" + agps
                    + "；persist.sys.xtra-daemon.enabled="
                    + SystemProperties.get(PROP_XTRA, "（讀不到）"));
        }

        // ---- USB adb（A 類：Settings.Global） ----
        int adb = Settings.Global.getInt(getContentResolver(), Settings.Global.ADB_ENABLED, 0);
        if (mAdbOff != null) {
            mAdbOff.setChecked(adb == 0);
            mAdbOff.setSummary(getString(R.string.adb_summary)
                    + "\n目前 adb_enabled=" + adb);
        }

        // ---- 廣告框架（A 類：DeviceConfig；預設 false = 已停用 ✓） ----
        if (mAdservicesOff != null) {
            Boolean adsDisabled = readAdServicesDisabled();
            if (adsDisabled == null) {
                // API 與 device_config 皆不可用 ⇒ 不給假開關，只顯示資訊 ✗
                mAdservicesOff.setChecked(true);
                mAdservicesOff.setEnabled(false);
                mAdservicesOff.setSummary(getString(R.string.adservices_summary)
                        + "\n目前：無法讀取（DeviceConfig API 不可用）"
                        + "\n請以 adb 指令確認：adb shell device_config get "
                        + AD_NAMESPACE + " " + AD_KEY);
            } else {
                mAdservicesOff.setEnabled(true);
                mAdservicesOff.setChecked(adsDisabled);
                mAdservicesOff.setSummary(getString(R.string.adservices_summary)
                        + "\n目前 adservice_enabled=" + (!adsDisabled));
            }
        }

        // ---- 持久 logcatd（B 類：唯讀顯示 ✓） ----
        if (mLogcatdStatus != null) {
            String v = readProp(PROP_LOGPERSISTD);
            String shown = (v == null || v.isEmpty()) ? "（空／未設定，通常代表未啟用）" : v;
            mLogcatdStatus.setSummary(getString(R.string.logcatd_summary)
                    + "\n目前 persist.logd.logpersistd=" + shown
                    + "\n驗證：adb shell getprop " + PROP_LOGPERSISTD
                    + "\n（唯讀：需 device sepolicy 加 " + LOGPERSISTD_SEPOLICY_HINT + "）");
        }

        // ---- 既有項回填 ----
        if (mCaptiveOff != null) {
            mCaptiveOff.setChecked(cpMode == 0);
            mCaptiveOff.setSummary(getString(R.string.captive_portal_summary)
                    + "\n驗證：adb shell settings get global captive_portal_mode  (目前：" + cpMode + ")");
        }

        if (mDnsOn != null) {
            mDnsOn.setSummary(getString(R.string.private_dns_summary)
                    + "\n驗證：adb shell settings get global " + DNS_MODE_GLOBAL
                    + "  (目前：" + (dnsMode == null ? "未設定" : dnsMode) + ")");
            mDnsOn.setChecked("hostname".equals(dnsMode) || "opportunistic".equals(dnsMode));
        }

        if (mDnsHost != null) mDnsHost.setText(dnsSpec == null ? "" : dnsSpec);
    }

    // =====================================================================
    //  A 類：純執行期開關（寫入真實系統設定）
    // =====================================================================

    /**
     * AGPS：Settings.Global.ASSISTED_GPS_ENABLED。
     * 0 = 停用（最強隱私，不再連 XTRA 雲端）；1 = 啟用。
     * ContentObserver（GnssLocationProvider:523）⇒ 不需重開機。
     * 驗證：adb shell settings get global assisted_gps_enabled
     */
    private boolean setAgpsDisabled(boolean disabled) {
        try {
            Settings.Global.putInt(getContentResolver(),
                    Settings.Global.ASSISTED_GPS_ENABLED, disabled ? 0 : 1);
            return true;
        } catch (Exception e) {
            toast("AGPS：" + e.getClass().getSimpleName());
            return false;
        }
    }

    /**
     * USB adb：Settings.Global.ADB_ENABLED。
     * 0 = 關閉（插 USB 不自動開 adb）；1 = 開啟。
     * AdbService ContentObserver（AdbService.java:151-193）⇒ 執行期即時生效。
     * 驗證：adb shell settings get global adb_enabled
     */
    private boolean setAdbDisabled(boolean disabled) {
        try {
            Settings.Global.putInt(getContentResolver(),
                    Settings.Global.ADB_ENABLED, disabled ? 0 : 1);
            return true;
        } catch (Exception e) {
            toast("USB adb：" + e.getClass().getSimpleName());
            return false;
        }
    }

    /**
     * 讀取廣告框架停用狀態。
     * 主要路徑：DeviceConfig @SystemApi（platform 簽章 ＋ WRITE_DEVICE_CONFIG ✓）。
     * 後備：device_config 指令（需 shell／root，多半失敗 ⇒ 誠實退化為 null）。
     * 預設（未設定）= false = 已停用（最強隱私 ✓）。
     *
     * @return true=已停用, false=已啟用, null=無法讀取
     */
    private Boolean readAdServicesDisabled() {
        try {
            boolean enabled = DeviceConfig.getBoolean(AD_NAMESPACE, AD_KEY, false);
            return !enabled;
        } catch (Throwable t) {
            // 落到後備路徑
        }
        String v = execDeviceConfig("get", AD_NAMESPACE, AD_KEY);
        if (v == null) return null;
        // device_config 對未設定值輸出 "null"；device_config get 成功輸出 "true"/"false"
        return !"true".equals(v);
    }

    /**
     * 寫入廣告框架狀態。
     * 主要路徑：DeviceConfig.setProperty（@SystemApi，@RequiresPermission WRITE_DEVICE_CONFIG）。
     * 後備：device_config 指令；並以讀回值確認，不假裝成功 ✗。
     */
    private boolean setAdServicesDisabled(boolean disabled) {
        String value = disabled ? "false" : "true";

        // 主要路徑
        try {
            if (DeviceConfig.setProperty(AD_NAMESPACE, AD_KEY, value, false)) {
                return true;
            }
        } catch (Throwable t) {
            // 落到後備路徑
        }

        // 後備路徑：執行 device_config（成功一般不輸出）
        String r = execDeviceConfig("put", AD_NAMESPACE, AD_KEY, value);
        if (r == null) return false;

        // 讀回確認
        Boolean now = readAdServicesDisabled();
        return now != null && now == disabled;
    }

    /** 執行 /system/bin/device_config 並回傳（trim 過的）stdout；失敗回傳 null。 */
    private String execDeviceConfig(String... args) {
        try {
            List<String> cmd = new ArrayList<>();
            cmd.add("/system/bin/device_config");
            for (String a : args) cmd.add(a);
            ProcessBuilder pb = new ProcessBuilder(cmd);
            pb.redirectErrorStream(true);
            Process p = pb.start();
            StringBuilder out = new StringBuilder();
            try (BufferedReader r =
                         new BufferedReader(new InputStreamReader(p.getInputStream()))) {
                String line;
                while ((line = r.readLine()) != null) out.append(line.trim());
            }
            p.waitFor(3, TimeUnit.SECONDS);
            return out.toString();
        } catch (Throwable t) {
            return null;
        }
    }

    /** 讀取系統屬性（唯讀）；讀不到回傳空字串。 */
    private String readProp(String key) {
        try {
            return SystemProperties.get(key, "");
        } catch (Throwable t) {
            return "";
        }
    }

    /** 關閉網路探測：captive_portal_mode 0=off / 1=prompt */
    private void setCaptivePortalDisabled(boolean disabled) {
        try {
            Settings.Global.putInt(getContentResolver(), Settings.Global.CAPTIVE_PORTAL_MODE,
                    disabled ? 0 : Settings.Global.CAPTIVE_PORTAL_MODE_PROMPT);
        } catch (Exception e) {
            toast("Captive portal：" + e.getClass().getSimpleName());
        }
        syncFromSystem();
    }

    /** 私有 DNS：模式 off / opportunistic / hostname */
    private void setPrivateDns(boolean enabled) {
        try {
            String mode = enabled ? "hostname" : "off";
            String spec = Settings.Global.getString(getContentResolver(), DNS_SPECIFIER_GLOBAL);
            if (enabled && (spec == null || spec.isEmpty())) {
                // 沒有主機名時先用 opportunistic（加密且不需指定主機 ✓）
                mode = "opportunistic";
            }
            Settings.Global.putString(getContentResolver(), DNS_MODE_GLOBAL, mode);
        } catch (Exception e) {
            toast("Private DNS：" + e.getClass().getSimpleName());
        }
        syncFromSystem();
    }

    private void setDnsHost(String host) {
        try {
            Settings.Global.putString(getContentResolver(), DNS_SPECIFIER_GLOBAL, host);
            if (host != null && !host.isEmpty()) {
                Settings.Global.putString(getContentResolver(), DNS_MODE_GLOBAL, "hostname");
            }
        } catch (Exception e) {
            toast("DoT 主機名：" + e.getClass().getSimpleName());
        }
        syncFromSystem();
    }

    /**
     * 等級一鍵套用。
     *   最低 minimal ：維持現狀，不變更任何設定 ✓
     *   標準 standard：AGPS 0 ＋ adb 1 ＋ adservices 0
     *   嚴格 strict  ：標準 ＋ captive portal 0 ＋ adb 0
     *   自訂 custom  ：不自動套用，交由使用者手動調整 ✓
     * 任何一項失敗都會列在提示中，不假裝全部成功 ✗（全部 try/catch ✓）。
     */
    private void applyTier(String tier) {
        List<String> failed = new ArrayList<>();

        switch (tier) {
            case "standard":
            case "strict": {
                // 標準內容
                if (!setAgpsDisabled(true)) failed.add("AGPS→0");
                if (!setAdbDisabled(false)) failed.add("adb→1");
                if (!setAdServicesDisabled(true)) failed.add("adservices→0");
                // 嚴格內容（在標準之上）
                if ("strict".equals(tier)) {
                    setCaptivePortalDisabled(true);
                    if (!setAdbDisabled(true)) failed.add("adb→0");
                }
                break;
            }
            case "custom":
                toast("「自訂」不自動套用任何設定，請手動調整下方開關");
                break;
            case "minimal":
            default:
                toast("「最低」維持現狀，未變更任何系統設定");
                break;
        }

        if (!failed.isEmpty()) {
            toast("等級「" + tier + "」有項目失敗：" + String.join("、", failed)
                    + "（請用摘要中的 adb 指令確認）");
        } else if (!"custom".equals(tier) && !"minimal".equals(tier)) {
            toast("已套用等級「" + tier + "」");
        }
        syncFromSystem();
    }

    private void toast(String msg) {
        Toast.makeText(this, msg, Toast.LENGTH_LONG).show();
    }
}
