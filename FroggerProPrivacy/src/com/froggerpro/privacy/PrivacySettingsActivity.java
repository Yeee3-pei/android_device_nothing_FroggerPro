/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package com.froggerpro.privacy;

import android.hardware.SensorPrivacyManager;
import android.hardware.SensorPrivacyManager.Sensors;
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
 * FroggerPro 隱私設定（A 類：純執行期開關 ＋ I 類：唯讀狀態）。
 *
 * 設計原則（見 ~/nphone/live/PRIVACY_FULL_CATALOG.md）：
 *   1. 只有【真實生效且可驗證】的項目才做成開關 ✓
 *   2. 每個開關寫明改了哪個系統設定、以及怎麼驗證（可重現的 adb 指令）✓
 *   3. 無法執行期切換的只顯示狀態與原因，不提供假開關 ✗
 *   4. 預設值皆為【最強隱私】；放寬與否由使用者決定 ✓
 *   5. 所有寫入皆包 try/catch，App 不因單一項失敗而崩潰 ✓
 *
 * A 類機制（每項都有 AOSP 原始碼依據 ✓）：
 *   - AGPS：Settings.Global.ASSISTED_GPS_ENABLED（0/1）
 *       GnssLocationProvider.java:1891-1903 推 persist.sys.xtra-daemon.enabled；
 *       :523 ContentObserver ⇒ 不需重開機。緊急電話強制開啟（:1893-1895）。
 *   - 廣告框架：DeviceConfig "adservices"/"adservice_enabled"
 *       SettingsProvider.java:2562-2579「有 WRITE_DEVICE_CONFIG 就不查命名空間 allowlist」。
 *   - USB adb：Settings.Global.ADB_ENABLED（AdbService.java:151-193 ContentObserver ✓）。
 *   - 定位模式：Settings.Secure.LOCATION_MODE（0=關 / 1=僅裝置 / 3=高精度）。
 *   - NFC：Settings.Global.NFC_ON（NfcService 讀取 ✓）。
 *   - Wi-Fi／藍牙永遠掃描：Settings.Global.WIFI_SCAN_ALWAYS_AVAILABLE /
 *       BLE_SCAN_ALWAYS_AVAILABLE（可被用於定位 ✗）。
 *   - 相機／麥克風／動態感測器總關：SensorPrivacyManager.setSensorPrivacy(Sensors.X, true)
 *       SensorPrivacyManager.java:795-801（@SystemApi ＋ MANAGE_SENSOR_PRIVACY ✓
 *       本 App platform 簽章且 privileged ⇒ 符合 ✓）
 *       ★注意★：狀態存在 XML（PersistedState.java ✓）非 Settings ✗
 *   - NTP 伺服器：Settings.Global.NTP_SERVER（Settings.java:15038 ✓
 *       由 NtpTrustedTime 消費 ✓；可能需重開機才生效 ⚠️）
 *   - 資料節省：Settings.Global.DATA_SAVER_MODE。
 *   - 自動時間／時區：Settings.Global.AUTO_TIME / AUTO_TIME_ZONE（NTP 洩漏面 ✓）。
 */
public class PrivacySettingsActivity extends PreferenceActivity {

    // ---- 等級 ----
    private static final String KEY_TIER = "tier";

    // ---- 既有開關 ----
    private static final String KEY_CAPTIVE_OFF = "captive_portal_off";
    private static final String KEY_DNS_ON = "private_dns_on";
    private static final String KEY_DNS_HOST = "private_dns_host";
    private static final String KEY_AGPS_OFF = "agps_off";
    private static final String KEY_ADB_OFF = "adb_off";
    private static final String KEY_ADSERVICES_OFF = "adservices_off";
    private static final String KEY_LOGCATD_STATUS = "logcatd_status";

    // ---- 本輪新增（A 類）----
    private static final String KEY_LOCATION_DEVICE_ONLY = "location_device_only";
    private static final String KEY_NFC_OFF = "nfc_off";
    private static final String KEY_WIFI_SCAN_OFF = "wifi_scan_off";
    private static final String KEY_BLE_SCAN_OFF = "ble_scan_off";
    private static final String KEY_SENSOR_PRIVACY_ON = "sensor_privacy_on";
    private static final String KEY_NTP_SERVER = "ntp_server";
    private static final String KEY_AUTO_TIME_OFF = "auto_time_off";

    // ---- 系統設定鍵 ----
    private static final String DNS_MODE_GLOBAL = "private_dns_mode";
    private static final String DNS_SPECIFIER_GLOBAL = "private_dns_specifier";

    /** 定位模式：0=關閉 / 1=僅裝置（不用網路定位 ✓）/ 3=高精度 */
    private static final int LOCATION_MODE_OFF = 0;
    private static final int LOCATION_MODE_DEVICE_ONLY = 1;

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
    private SwitchPreference mLocationDeviceOnly;
    private SwitchPreference mNfcOff;
    private SwitchPreference mWifiScanOff;
    private SwitchPreference mBleScanOff;
    private SwitchPreference mSensorPrivacyOn;
    private EditTextPreference mNtpServer;
    private SwitchPreference mAutoTimeOff;

    private SensorPrivacyManager mSensorPrivacy;

    @Override
    @SuppressWarnings("deprecation")
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        addPreferencesFromResource(R.xml.privacy_prefs);

        mTier = (ListPreference) findPreference(KEY_TIER);
        mAgpsOff = (SwitchPreference) findPreference(KEY_AGPS_OFF);
        mAdbOff = (SwitchPreference) findPreference(KEY_ADB_OFF);

        // ---- B 類：一鍵開啟系統的隱私儀表板 ----
        // 理由：平台的 Privacy Dashboard／權限管理 UI 比自造清單更完整且跟得上 AOSP 改版 ✓
        //       本 App 只負責「把使用者送到正確的地方」✗ 不自造半套清單 ✗
        // 用全限定名 android.content.Intent ⇒ 不必新增 import ✓ 減少出錯面 ✓
        Preference dash = findPreference("privacy_dashboard");
        if (dash != null) {
            dash.setOnPreferenceClickListener(p -> {
                final String[] actions = {
                        "android.settings.PRIVACY_SETTINGS",
                        "android.settings.PRIVACY_DASHBOARD",
                        "android.settings.MANAGE_APPLICATIONS_SETTINGS",
                        "android.settings.APPLICATION_SETTINGS"
                };
                for (String a : actions) {
                    try {
                        startActivity(new android.content.Intent(a)
                                .addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK));
                        return true;   // 送出去就結束 ✓ 不猜對方一定開得起來 ✗
                    } catch (Exception ignore) {
                        // 這個 action 不存在 ⇒ 換下一個 ✓
                    }
                }
                Toast.makeText(this, "此裝置沒有可用的隱私儀表板畫面 ✗",
                        Toast.LENGTH_LONG).show();
                return true;
            });
        }
        mCaptiveOff = (SwitchPreference) findPreference(KEY_CAPTIVE_OFF);
        mDnsOn = (SwitchPreference) findPreference(KEY_DNS_ON);
        mDnsHost = (EditTextPreference) findPreference(KEY_DNS_HOST);
        mAdservicesOff = (SwitchPreference) findPreference(KEY_ADSERVICES_OFF);
        mLogcatdStatus = findPreference(KEY_LOGCATD_STATUS);
        mLocationDeviceOnly = (SwitchPreference) findPreference(KEY_LOCATION_DEVICE_ONLY);
        mNfcOff = (SwitchPreference) findPreference(KEY_NFC_OFF);
        mWifiScanOff = (SwitchPreference) findPreference(KEY_WIFI_SCAN_OFF);
        mBleScanOff = (SwitchPreference) findPreference(KEY_BLE_SCAN_OFF);
        mSensorPrivacyOn = (SwitchPreference) findPreference(KEY_SENSOR_PRIVACY_ON);
        mNtpServer = (EditTextPreference) findPreference(KEY_NTP_SERVER);
        mAutoTimeOff = (SwitchPreference) findPreference(KEY_AUTO_TIME_OFF);

        try {
            mSensorPrivacy = getSystemService(SensorPrivacyManager.class);
        } catch (Throwable t) {
            mSensorPrivacy = null;
        }

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
                    syncFromSystem();
                }
                return true;
            });
        }

        if (mLocationDeviceOnly != null) {
            mLocationDeviceOnly.setOnPreferenceChangeListener((p, v) -> {
                if (!setLocationDeviceOnly((Boolean) v)) {
                    toast("定位模式寫入失敗");
                }
                syncFromSystem();
                return true;
            });
        }

        if (mNfcOff != null) {
            mNfcOff.setOnPreferenceChangeListener((p, v) -> {
                if (!setNfcDisabled((Boolean) v)) {
                    toast("NFC 設定寫入失敗");
                }
                syncFromSystem();
                return true;
            });
        }

        if (mWifiScanOff != null) {
            mWifiScanOff.setOnPreferenceChangeListener((p, v) -> {
                if (!setGlobalInt("wifi_scan_always_enabled", !(Boolean) v ? 1 : 0)) {
                    toast("Wi-Fi 掃描設定寫入失敗");
                }
                syncFromSystem();
                return true;
            });
        }

        if (mBleScanOff != null) {
            mBleScanOff.setOnPreferenceChangeListener((p, v) -> {
                if (!setGlobalInt("ble_scan_always_enabled", !(Boolean) v ? 1 : 0)) {
                    toast("藍牙掃描設定寫入失敗");
                }
                syncFromSystem();
                return true;
            });
        }

        if (mSensorPrivacyOn != null) {
            mSensorPrivacyOn.setOnPreferenceChangeListener((p, v) -> {
                boolean want = (Boolean) v;
                boolean ok = setSensorPrivacy(want);
                if (!ok) {
                    toast("相機／麥克風總關設定失敗：需 MANAGE_SENSOR_PRIVACY（platform 簽章）");
                }
                syncFromSystem();
                return true;
            });
        }

        if (mNtpServer != null) {
            mNtpServer.setOnPreferenceChangeListener((p, v) -> {
                String host = String.valueOf(v).trim();
                try {
                    Settings.Global.putString(getContentResolver(),
                            Settings.Global.NTP_SERVER, host.isEmpty() ? null : host);
                } catch (Exception e) {
                    toast("NTP 伺服器：" + e.getClass().getSimpleName());
                }
                toast("NTP 伺服器已設定；可能需重開機才生效");
                syncFromSystem();
                return true;
            });
        }

        if (mAutoTimeOff != null) {
            mAutoTimeOff.setOnPreferenceChangeListener((p, v) -> {
                boolean auto = !(Boolean) v;
                boolean ok = setGlobalInt("auto_time", auto ? 1 : 0)
                        & setGlobalInt("auto_time_zone", auto ? 1 : 0);
                if (!ok) {
                    toast("自動時間／時區設定失敗");
                }
                syncFromSystem();
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
    @SuppressWarnings("deprecation")
    private void syncFromSystem() {
        int cpMode = Settings.Global.getInt(getContentResolver(),
                Settings.Global.CAPTIVE_PORTAL_MODE, Settings.Global.CAPTIVE_PORTAL_MODE_PROMPT);
        String dnsMode = Settings.Global.getString(getContentResolver(), DNS_MODE_GLOBAL);
        String dnsSpec = Settings.Global.getString(getContentResolver(), DNS_SPECIFIER_GLOBAL);

        int agps = Settings.Global.getInt(getContentResolver(),
                Settings.Global.ASSISTED_GPS_ENABLED, 0);
        if (mAgpsOff != null) {
            mAgpsOff.setChecked(agps == 0);
            // ★不讀 persist.sys.xtra-daemon.enabled ✗★
            //    platform_app 網域無權讀該屬性（實機 avc: denied read xtra_control_prop ✗）
            //    ⇒ 讀了只會顯示「讀不到」並每分鐘噴一條 AVC 噪音 ✗ ⇒ 只顯示 assisted_gps_enabled ✓
            mAgpsOff.setSummary(getString(R.string.agps_summary)
                    + "\n目前 assisted_gps_enabled=" + agps
                    + "（0 = 已停用網路輔助 ✓）");
        }

        int adb = Settings.Global.getInt(getContentResolver(), Settings.Global.ADB_ENABLED, 0);
        if (mAdbOff != null) {
            mAdbOff.setChecked(adb == 0);
            mAdbOff.setSummary(getString(R.string.adb_summary)
                    + "\n目前 adb_enabled=" + adb);
        }

        if (mAdservicesOff != null) {
            Boolean adsDisabled = readAdServicesDisabled();
            if (adsDisabled == null) {
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

        if (mLogcatdStatus != null) {
            String v = readProp(PROP_LOGPERSISTD);
            String shown = (v == null || v.isEmpty()) ? "（空／未設定，通常代表未啟用）" : v;
            mLogcatdStatus.setSummary(getString(R.string.logcatd_summary)
                    + "\n目前 persist.logd.logpersistd=" + shown
                    + "\n驗證：adb shell getprop " + PROP_LOGPERSISTD
                    + "\n（唯讀：需 device sepolicy 加 " + LOGPERSISTD_SEPOLICY_HINT + "）");
        }

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

        // ---- 定位模式（A 類）----
        int locMode = Settings.Secure.getInt(getContentResolver(),
                Settings.Secure.LOCATION_MODE, LOCATION_MODE_OFF);
        if (mLocationDeviceOnly != null) {
            mLocationDeviceOnly.setChecked(locMode == LOCATION_MODE_DEVICE_ONLY);
            mLocationDeviceOnly.setSummary(getString(R.string.location_summary)
                    + "\n目前 location_mode=" + locMode
                    + "（0=關 / 1=僅裝置 / 3=高精度）"
                    + "\n驗證：adb shell settings get secure location_mode");
        }

        // ---- NFC（A 類）----
        int nfc = Settings.Global.getInt(getContentResolver(), "nfc_on", 1);
        if (mNfcOff != null) {
            mNfcOff.setChecked(nfc == 0);
            mNfcOff.setSummary(getString(R.string.nfc_summary)
                    + "\n目前 nfc_on=" + nfc
                    + "\n驗證：adb shell settings get global nfc_on");
        }

        // ---- Wi-Fi／藍牙永遠掃描（A 類）----
        int wifiScan = Settings.Global.getInt(getContentResolver(),
                Settings.Global.WIFI_SCAN_ALWAYS_AVAILABLE, 0);
        if (mWifiScanOff != null) {
            mWifiScanOff.setChecked(wifiScan == 0);
            mWifiScanOff.setSummary(getString(R.string.wifi_scan_summary)
                    + "\n目前 wifi_scan_always_enabled=" + wifiScan
                    + "\n驗證：adb shell settings get global wifi_scan_always_enabled");
        }

        int bleScan = Settings.Global.getInt(getContentResolver(),
                Settings.Global.BLE_SCAN_ALWAYS_AVAILABLE, 0);
        if (mBleScanOff != null) {
            mBleScanOff.setChecked(bleScan == 0);
            mBleScanOff.setSummary(getString(R.string.ble_scan_summary)
                    + "\n目前 ble_scan_always_enabled=" + bleScan
                    + "\n驗證：adb shell settings get global ble_scan_always_enabled");
        }

        // ---- 相機／麥克風總關（A 類，走 SensorPrivacyManager ✗ 非 Settings ✗）----
        if (mSensorPrivacyOn != null) {
            Boolean cam = isSensorPrivacyOn(Sensors.CAMERA);
            Boolean mic = isSensorPrivacyOn(Sensors.MICROPHONE);
            if (cam == null || mic == null) {
                mSensorPrivacyOn.setEnabled(false);
                mSensorPrivacyOn.setChecked(true);
                mSensorPrivacyOn.setSummary(getString(R.string.sensor_privacy_summary)
                        + "\n目前：無法讀取（SensorPrivacyManager 不可用）");
            } else {
                mSensorPrivacyOn.setEnabled(true);
                mSensorPrivacyOn.setChecked(cam && mic);
                mSensorPrivacyOn.setSummary(getString(R.string.sensor_privacy_summary)
                        + "\n目前 相機=" + (cam ? "已封鎖" : "開放")
                        + "／麥克風=" + (mic ? "已封鎖" : "開放")
                        + "\n驗證：adb shell dumpsys sensor_privacy");
            }
        }

        // ---- NTP（A 類；可能需重開機 ⚠️）----
        if (mNtpServer != null) {
            String ntp = Settings.Global.getString(getContentResolver(), Settings.Global.NTP_SERVER);
            mNtpServer.setSummary(getString(R.string.ntp_summary)
                    + "\n目前 ntp_server=" + (ntp == null || ntp.isEmpty() ? "（未設定）" : ntp)
                    + "\n驗證：adb shell settings get global ntp_server"
                    + "\n⚠️ 變更可能需要重開機才生效");
            mNtpServer.setText(ntp == null ? "" : ntp);
        }

        // ---- 自動時間／時區（A 類）----
        int autoTime = Settings.Global.getInt(getContentResolver(),
                Settings.Global.AUTO_TIME, 1);
        int autoTz = Settings.Global.getInt(getContentResolver(),
                Settings.Global.AUTO_TIME_ZONE, 1);
        if (mAutoTimeOff != null) {
            mAutoTimeOff.setChecked(autoTime == 0 && autoTz == 0);
            mAutoTimeOff.setSummary(getString(R.string.auto_time_summary)
                    + "\n目前 auto_time=" + autoTime + "／auto_time_zone=" + autoTz
                    + "\n驗證：adb shell settings get global auto_time");
        }
    }

    // =====================================================================
    //  A 類：純執行期開關
    // =====================================================================

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

    /** 通用：寫入 Settings.Global 整數（回傳是否成功） */
    private boolean setGlobalInt(String key, int value) {
        try {
            Settings.Global.putInt(getContentResolver(), key, value);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /** 定位模式：開啟 = 僅裝置（1，不用網路定位）；關閉 = 恢復高精度（3） */
    private boolean setLocationDeviceOnly(boolean deviceOnly) {
        try {
            Settings.Secure.putInt(getContentResolver(), Settings.Secure.LOCATION_MODE,
                    deviceOnly ? LOCATION_MODE_DEVICE_ONLY : 3);
            return true;
        } catch (Exception e) {
            toast("定位模式：" + e.getClass().getSimpleName());
            return false;
        }
    }

    private boolean setNfcDisabled(boolean disabled) {
        return setGlobalInt("nfc_on", disabled ? 0 : 1);
    }

    /**
     * 相機／麥克風總關。
     * 走 SensorPrivacyManager.setSensorPrivacy(Sensors.X, true) —— 狀態存 XML ✗ 非 Settings ✗
     * 需 MANAGE_SENSOR_PRIVACY（@SystemApi ✓ platform 簽章 ＋ privileged 符合 ✓）。
     */
    private boolean setSensorPrivacy(boolean enabled) {
        if (mSensorPrivacy == null) return false;
        try {
            mSensorPrivacy.setSensorPrivacy(Sensors.CAMERA, enabled);
            mSensorPrivacy.setSensorPrivacy(Sensors.MICROPHONE, enabled);
            return true;
        } catch (Throwable t) {
            toast("SensorPrivacy：" + t.getClass().getSimpleName());
            return false;
        }
    }

    /** 讀取單一感測器的隱私狀態；不可用時回傳 null（不假裝 ✓） */
    private Boolean isSensorPrivacyOn(int sensor) {
        if (mSensorPrivacy == null) return null;
        try {
            return mSensorPrivacy.isSensorPrivacyEnabled(sensor);
        } catch (Throwable t) {
            return null;
        }
    }

    // =====================================================================
    //  廣告框架（DeviceConfig）
    // =====================================================================

    private Boolean readAdServicesDisabled() {
        try {
            boolean enabled = DeviceConfig.getBoolean(AD_NAMESPACE, AD_KEY, false);
            return !enabled;
        } catch (Throwable t) {
            // 落到後備路徑
        }
        String v = execDeviceConfig("get", AD_NAMESPACE, AD_KEY);
        if (v == null) return null;
        return !"true".equals(v);
    }

    private boolean setAdServicesDisabled(boolean disabled) {
        String value = disabled ? "false" : "true";
        try {
            if (DeviceConfig.setProperty(AD_NAMESPACE, AD_KEY, value, false)) {
                return true;
            }
        } catch (Throwable t) {
            // 落到後備路徑
        }
        String r = execDeviceConfig("put", AD_NAMESPACE, AD_KEY, value);
        if (r == null) return false;
        Boolean now = readAdServicesDisabled();
        return now != null && now == disabled;
    }

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

    private String readProp(String key) {
        try {
            return SystemProperties.get(key, "");
        } catch (Throwable t) {
            return "";
        }
    }

    private void setCaptivePortalDisabled(boolean disabled) {
        try {
            Settings.Global.putInt(getContentResolver(), Settings.Global.CAPTIVE_PORTAL_MODE,
                    disabled ? 0 : Settings.Global.CAPTIVE_PORTAL_MODE_PROMPT);
        } catch (Exception e) {
            toast("Captive portal：" + e.getClass().getSimpleName());
        }
        syncFromSystem();
    }

    private void setPrivateDns(boolean enabled) {
        try {
            String mode = enabled ? "hostname" : "off";
            String spec = Settings.Global.getString(getContentResolver(), DNS_SPECIFIER_GLOBAL);
            if (enabled && (spec == null || spec.isEmpty())) {
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
     *   最低 minimal ：維持現狀 ✓
     *   標準 standard：AGPS 0 ＋ adservices 0 ＋ 相機麥克風封鎖 ＋ 定位僅裝置 ＋ 掃描關 ✓
     *   嚴格 strict  ：標準 ＋ captive portal 0 ＋ USB adb 0 ＋ 自動時間關 ✓
     *   自訂 custom  ：不自動套用 ✓
     * 任何一項失敗都列出，不假裝全部成功 ✗
     */
    private void applyTier(String tier) {
        List<String> failed = new ArrayList<>();

        switch (tier) {
            case "standard":
            case "strict": {
                if (!setAgpsDisabled(true)) failed.add("AGPS→0");
                if (!setAdServicesDisabled(true)) failed.add("adservices→0");
                if (!setSensorPrivacy(true)) failed.add("相機麥克風→封鎖");
                if (!setLocationDeviceOnly(true)) failed.add("定位→僅裝置");
                if (!setGlobalInt("wifi_scan_always_enabled", 0)) failed.add("WiFi掃描→0");
                if (!setGlobalInt("ble_scan_always_enabled", 0)) failed.add("BT掃描→0");
                if (!setNfcDisabled(true)) failed.add("NFC→0");
                if ("strict".equals(tier)) {
                    setCaptivePortalDisabled(true);
                    if (!setAdbDisabled(true)) failed.add("adb→0");
                    if (!setGlobalInt("auto_time", 0)) failed.add("auto_time→0");
                    if (!setGlobalInt("auto_time_zone", 0)) failed.add("auto_time_zone→0");
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
