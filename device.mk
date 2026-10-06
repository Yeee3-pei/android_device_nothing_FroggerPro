#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

$(call inherit-product, hardware/qcom-caf/common/common.mk)
$(call inherit-product, vendor/nothing/FroggerPro/FroggerPro-vendor.mk)
# 補漏：EvoX 映像有、我方 vendor 建置未安裝的 150 個 blob（2026-09-30 產生；
# 來源 = 與 EvoX vendor 映像逐檔比對，排除設計上禁止 COPY 的 vintf 碎片）。
$(call inherit-product-if-exists, vendor/nothing/FroggerPro/extra_vendor_blobs.mk)
# 補漏（第二批）：我方 vendor 映像缺少、但在 out/soong/installs-*.mk 已有安裝規則的 128 個模組
# ⇒ 以 PRODUCT_PACKAGES 安裝（不能用 PRODUCT_COPY_FILES，目標已由 Soong 定義會撞）。
$(call inherit-product-if-exists, vendor/nothing/FroggerPro/extra_product_packages.mk)
# 補漏（第四批，V12）：以 <module>.vendor 建置 vendor 變體 ⇒ 才會打進 vendor 映像（實測 staging 有、file_list.txt 無 ✗）
$(call inherit-product-if-exists, vendor/nothing/FroggerPro/extra_vendor_variant.mk)

# C228（2026-10-03）：★全面補齊原廠 vendor 檔案★
#   契機：使用者質疑「你要不要全面比對一下看看都缺什麼」✓ 完全正確 ✓
#   方法錯誤的糾正：之前拿【我們自己的 v11 OTA】當基準 ✗ ⇒ 只看到差集 ✗
#     正確基準線＝【原廠 OTA】✓ ⇒ 實測缺 1,398 檔 ✗✗（不是 38 檔 ✗）
#   產生器：~/nphone/bootrec/gen_vendor_fill.py ✓（可重複執行 ✓ --fetch 會從 OTA 抽檔 ✓）
#
#   ⚠️⚠️ C236 實測：補 1,030 檔後【卡 Nothing logo ＋ 完全沒有 adb】✗（死在 adbd 之前 ✓）
#     ⇒ 與 C216/C222 同一類症狀 ✗ ⇒ 某個補進去的檔會在極早期弄死開機 ✗
#     ⇒ 為確保有可用手機 ✓ 先停用 ✓（研究與產生器都保留 ✓ 之後可二分定位 ✓）
#   二分計畫（下次）：把補檔分成幾類，逐一排除後建置測試 ✓
#     A 組 apex/ + etc/init/ + bin/hw/  ← 最可疑（極早期 ✓）
#     B 組 etc/permissions/ + etc/display/
#     C 組 其餘（lib64 等）
#
# $(call inherit-product-if-exists, vendor/nothing/FroggerPro/extra_vendor_fill.mk)
# $(call inherit-product-if-exists, vendor/nothing/FroggerPro/extra_vendor_fill_pkgs.mk)
# ★★★ C240 定案（實測二分 ✓ 永久生效 ✓）★★★
#   只 inherit 【copy 規則】✓；【絕不】inherit Soong 模組清單 ✗
#   實測：C236（1,030 copy + 61 模組）⇒ 卡 logo ✗／B1（−apex）⇒ 卡 logo ✗／
#         B2（1,029 copy + 0 模組）⇒ ✓✓✓ 開機成功 T+33s ✓✓✓
#   機制：module-info.json 只說「該路徑有模組」✗ 加進 PRODUCT_PACKAGES 會讓
#         Soong 從原始碼重編 ✗ ⇒ 不同二進位／缺依賴庫／拉進編不過的 QTI 原始碼 ✗
# ★ 2026-10-03 暫停（取得可用基準用）：使用者實測 B2（＝v7 ＋ 這份補檔）指紋／音量不能用 ✗
#   證據＝B2−v7 的差異就是這份 mk 的 1,029 條 ✓（43 條 .rc／19 條 bin/hw／72 條音訊 ✗）
#   ⇒ 先停用 ✓ 事後再【二分】加回 ✓（計畫見 ~/nphone/live/BISECT_PLAN.md ✓）
# $(call inherit-product-if-exists, vendor/nothing/FroggerPro/extra_vendor_fill.mk)
# 研究用（✓ 已產生但不要 inherit ✗）：extra_vendor_fill_pkgs.mk
# $(call inherit-product-if-exists, vendor/nothing/FroggerPro/extra_vendor_fill_pkgs.mk)
# 顯示／GPU 堆疊改用原廠 blob（2026-10-02 C182；由 regen_display_prebuilts.py 產生）
# 真因：我方建置無 blob copy 規則 ⇒ vendor 映像內是 source 版顯示堆疊 ⇒
#   libsdmcore 的 DispLayerStack::Clear() 在 free() 送出被截斷標籤的指標 ⇒ composer SIGABRT
#   ⇒ SurfaceFlinger 被殺 ⇒ 黑屏開機迴圈（v8/v10/v11 ✗）。v7 能用是因為增量殘留了 blob 版 ✓。
# 修法：以 prefer: true 的 prebuilt 模組（= 原廠 blob）取代 source 版 ✓ 無 duplicate-output 衝突 ✓
$(call inherit-product-if-exists, vendor/nothing/FroggerPro/display_prebuilts.mk)
# /vendor/lib64 頂層三個 Adreno 名稱改回原廠的 symlink 佈局
# （規則放在本目錄的 Android.mk：$(TARGET_OUT_VENDOR) 在 product 設定檔內尚未定義 ✗，實測會誤成 /lib64/… ✗）
# （V9 路線已廢 ✗ 2026-09-30：以 PRODUCT_COPY_FILES 加入那 88 個 lib64 會被 kati 擋下 ——
#   目標已由 Soong 定義，且我方建置產出的檔名不同 ⇒ 該路線不可行。已移除 inherit。）
# VINTF 碎片改走正確機制：BoardConfig.mk 的 DEVICE_MANIFEST_FILE（V10 ✓）

# A/B
# 本機（FroggerPro）修正（C80）：移除 virtual A/B ✓
#
# 證據（以原始 lpdump 比對 super 的 metadata）：
#   原廠 twrprecure/super.img : Metadata version 10.0 / slot count 2 / Header flags: none ✓
#   9/26 superH7（能開機 ✓）  : Metadata version 10.0 / slot count 2 ✓
#   我們 9/28（卡 logo、USB 全無 ✗）: Metadata version 10.2 / slot count 3 /
#                                    Header flags: virtual_ab_device ✗
# ⇒ 我們的 super 把自己標成 virtual A/B 裝置，而原廠與唯一能開機的版本都不是 ✗。
#   build_super_image.py:35-36 顯示 --virtual-ab 由 virtual_ab 決定 ✓，
#   而這行 inherit 的 vabc_features.mk 正是開啟它的來源 ✓。
# ⇒ 判斷：bootloader 讀到不認識的 header flag ⇒ 無法建立邏輯分區 ⇒ 沒有 system
#   ⇒ 卡 logo 且 USB 完全不列舉 ✓（與症狀一致 ✓，但仍待實機驗證 ✗）。
#
# 上游原值（2e9ef80, Alexander Koskovich 2026-05-07）：
#   $(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/vabc_features.mk)
# 已移除 ✓；裝置仍為 A/B（AB_OTA_PARTITIONS ✓），只是不再採用 virtual A/B ✓。

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=erofs \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=erofs \
    POSTINSTALL_OPTIONAL_vendor=true

PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script

# 本機（FroggerPro）修正（C80）：移除 PRODUCT_VIRTUAL_AB_COMPRESSION_METHOD := lz4 ✓
# 理由：裝置不再採用 virtual A/B ✓（見上方 A/B 段落），此設定已無作用 ✓。
# 上游原值：PRODUCT_VIRTUAL_AB_COMPRESSION_METHOD := lz4

# API
PRODUCT_SHIPPING_API_LEVEL := 36
# ★ C100 註：這個變數**不能移除** ✓ —— 它會決定 hardware/lineage/compat 的 vendorcompat
#   模組命名（移除後 soong 會出現 "module ... already defined" 而建置失敗 ✗，已實測 ✗）。
#   因此 retrofit 旗標改放到 BoardConfig.mk（在 config.mk 的守衛之後才被讀取 ✓，見該檔註解 ✓）。

# ART
PRODUCT_ENABLE_UFFD_GC := true

# Adreno
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute-0.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level-1.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version-1_1.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_3.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version-1_3.xml \
    frameworks/native/data/etc/android.software.opengles.deqp.level-2023-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.opengles.deqp.level.xml \
    frameworks/native/data/etc/android.software.vulkan.deqp.level-2023-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level.xml

# Audio
PRODUCT_PACKAGES += \
    audio.bluetooth.default \
    audio.r_submix.default \
    audio.usbv2.default \
    libhapticgenerator \
    qtiaudiohalvendorextn \
    qti-audio-types-aidl-V1-ndk.vendor

PRODUCT_PACKAGES += \
    android.hardware.soundtrigger3-V1-ndk.vendor \
    android.hardware.audio.effect-V2-ndk.vendor \
    android.media.audio.common.types-V3-ndk.vendor \
    android.hardware.audio.common-V1-ndk.vendor \
    android.hardware.audio.core-V2-ndk.vendor \
    android.hardware.audio.core.sounddose-V3-ndk.vendor \
    android.hardware.audio.core.sounddose-V1-ndk.vendor \
    libalsautilsv2.vendor \
    libaudioaidlcommon.vendor \
    libaudioutils_shim \
    libmediautils_vendor.vendor \
    libmemunreachable.vendor

AUDIO_HAL_DIR := hardware/qcom-caf/sm8750/audio/primary-hal
CONFIG_HAL_SRC_DIR := $(AUDIO_HAL_DIR)/configs/sun
CONFIG_PAL_SRC_DIR := $(AUDIO_HAL_DIR)/../pal/configs/sun

# ══════════════════════════════════════════════════════════════════════
# C306（2026-10-06 ★發布阻擋級修正★）：audio_policy_configuration.xml 放錯層級 ✗
#   實機症狀 ✓：STREAM_MUSIC／STREAM_VOICE_CALL／STREAM_SYSTEM 的 Max = 0 ✗
#              ⇒ 音量完全無法調整 ✗（`cmd media_session volume --get` 回
#                 「volume is 0 in range [0..0]」✗；調大反而變 0 ✗）
#   真因 ✓：原廠有兩份 ——
#     ① /vendor/etc/audio_policy_configuration.xml（16,971 B ✓ 完整版）
#        內含 <xi:include href="audio_policy_volumes.xml"/> ✓
#            <xi:include href="default_volume_tables.xml"/> ✓ ← 音量表本體 ✓
#     ② /vendor/etc/audio/sku_kera/audio_policy_configuration.xml（9,999 B ✓ SKU 精簡版）
#   我方原本把 ② 放到 ① 的位置 ✗ ⇒ 音量表從未被 include ⇒ Max 全算成 0 ✗✗
#   修法 ✓：① 改用原廠完整版逐字複製（vendor/nothing/FroggerPro/etc/audio_policy_configuration.xml）
#           ② 位置與內容不動 ✓
# ══════════════════════════════════════════════════════════════════════
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/conf/audio/audio_module_config_primary.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/audio_module_config_primary.xml \
    $(LOCAL_PATH)/conf/audio/mixer_paths_kera_qrd.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/mixer_paths_kera_qrd.xml \
    $(LOCAL_PATH)/conf/audio/resourcemanager_kera_qrd.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/resourcemanager_kera_qrd.xml \
    $(LOCAL_PATH)/conf/audio/quasar_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/quasar_config.xml \
    $(LOCAL_PATH)/conf/audio/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/default_volume_tables.xml \
    $(LOCAL_PATH)/conf/audio/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    $(LOCAL_PATH)/conf/audio/usecaseKvManager.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usecaseKvManager.xml \
    $(LOCAL_PATH)/conf/audio/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/audio_policy_volumes.xml \
    $(LOCAL_PATH)/conf/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/audio_policy_configuration.xml \
    vendor/nothing/FroggerPro/etc/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    $(LOCAL_PATH)/conf/audio/audio_effects.conf:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/audio_effects.conf \
    $(LOCAL_PATH)/conf/audio/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/audio_effects.xml \
    $(LOCAL_PATH)/conf/audio/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects.xml \
    $(LOCAL_PATH)/conf/audio/audio_effects_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/audio_effects_config.xml \
    $(LOCAL_PATH)/conf/audio/backend_conf.xml:$(TARGET_COPY_OUT_VENDOR)/etc/backend_conf.xml

PRODUCT_COPY_FILES += \
    $(CONFIG_HAL_SRC_DIR)/mem_logger_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mem_logger_config.xml \
    $(CONFIG_HAL_SRC_DIR)/microphone_characteristics.xml:$(TARGET_COPY_OUT_VENDOR)/etc/microphone_characteristics.xml \
    $(CONFIG_HAL_SRC_DIR)/vendor_audio_interfaces.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/vendor_audio_interfaces.xml \
    $(CONFIG_PAL_SRC_DIR)/Hapticsconfig.xml:$(TARGET_COPY_OUT_VENDOR)/etc/Hapticsconfig.xml \
    $(CONFIG_PAL_SRC_DIR)/card-defs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/card-defs.xml

PRODUCT_COPY_FILES += \
    frameworks/av/services/audiopolicy/config/stub_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/stub_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/a2dp_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/a2dp_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_kera/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml
    
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.hardware.audio.pro.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.pro.xml \
    frameworks/native/data/etc/android.hardware.sensor.dynamic.head_tracker.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.dynamic.head_tracker.xml \
    frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml

# AxionFX
$(call inherit-product-if-exists, packages/apps/AxionFx/config.mk)

# Bluetooth
PRODUCT_PACKAGES += \
    android.hardware.bluetooth.audio-impl \
    android.hardware.bluetooth.audio-V4-ndk.vendor

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml

# Biometrics
PRODUCT_PACKAGES += \
    android.hardware.biometrics.fingerprint-service.nothing

$(call soong_config_set_bool,nothing_fingerprint,use_lhbm,true)

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.fingerprint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.fingerprint.xml

# Boot Control
PRODUCT_PACKAGES += \
    android.hardware.boot-service.qti \
    android.hardware.boot-service.qti.recovery

# Camera
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.camera.concurrent.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.concurrent.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.full.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.full.xml \
    frameworks/native/data/etc/android.hardware.camera.raw.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.raw.xml

PRODUCT_PACKAGES += \
    vendor.qti.hardware.display.config-V2-ndk.vendor

# DRM
PRODUCT_PACKAGES += \
    android.hardware.drm-service.clearkey

# Dalvik
$(call inherit-product, frameworks/native/build/phone-xhdpi-6144-dalvik-heap.mk)

# DeviceExtras
PRODUCT_PACKAGES += \
    DeviceExtras

# Display
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/conf/display/display_id_4630947050240568210.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_id_4630947050240568210.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    hardware/qcom-caf/sm8750/display/core/config/sdm_display_resolution_extn.xml:$(TARGET_COPY_OUT_VENDOR)/etc/display/sdm_display_resolution_extn.xml \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/camera_alignments.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/camera_alignments.json \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/cpu_alignments.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/cpu_alignments.json \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/default_alignments.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/default_alignments.json \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/display_alignments.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/display_alignments.json \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/formats.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/formats.json \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/graphics_alignments.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/graphics_alignments.json \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/ubwc_alignments.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/ubwc_alignments.json \
    hardware/qcom-caf/sm8750/display/core/snapalloc/resources/video_alignments.json:$(TARGET_COPY_OUT_VENDOR)/etc/display/video_alignments.json

PRODUCT_PACKAGES += \
    android.hardware.graphics.mapper@4.0-impl-qti-display \
    init.qti.display_boot.rc \
    init.qti.display_boot.sh \
    libqdMetaData \
    vendor.qti.hardware.display.allocator-service \
    vendor.qti.hardware.display.composer-service \
    vendor.qti.hardware.display.demura-service \
    vendor.qti.hardware.display.snapalloc-impl \
    vendor.qti.hardware.memtrack-service

# eUICC
$(foreach sku, EEA JPN ROW TUR, \
    $(eval PRODUCT_COPY_FILES += \
        frameworks/native/data/etc/android.hardware.telephony.euicc.xml:$(TARGET_COPY_OUT_ODM)/etc/permissions/sku_$(sku)/android.hardware.telephony.euicc.xml))

PRODUCT_PACKAGES += \
    EuiccPolicy \
    NothingEsimSwitcher

# Fastboot
PRODUCT_PACKAGES += \
    fastbootd

# FeliCa
PRODUCT_PACKAGES += \
    NothingFelicaDisabler

# GPS
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.location.gps.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.location.gps.xml

# Graphics
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator-V1-ndk.vendor
    
# Glyph
PRODUCT_PACKAGES += \
    HieroGlyphFroggerPro

# HIDL
PRODUCT_HIDL_ENABLED := true

PRODUCT_PACKAGES += \
    android.hidl.allocator@1.0-service \
    android.hidl.memory@1.0-impl \
    hwservicemanager

# Handheld
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/handheld_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/handheld_core_hardware.xml

# Health
PRODUCT_PACKAGES += \
    android.hardware.health-service.qti \
    android.hardware.health-service.qti_recovery

# IPA
PRODUCT_PACKAGES += \
    IPACM_Filter_cfg.xml \
    IPACM_cfg.xml \
    ipacm

# Init
#
# 本機修正（C77）：fstab 必須放在 vendor ramdisk 的 first_stage_ramdisk/ 之下，
# 否則 first-stage init 找不到 /super 的 fstab，就掛不上 /super（症狀：卡 Nothing logo、USB 完全不列舉）。
# 對照：原廠 vendor_boot ramdisk 內是 first_stage_ramdisk/fstab.default + fstab.emmc，
#       而我們的產物是 system/etc/fstab.default（位置錯誤）。
# AOSP 現成範例：device/google/trout/aosp_trout_common.mk 也是用
#   <src>:$(TARGET_COPY_OUT_...)/first_stage_ramdisk/fstab.<name>
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init/fstab.default:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.default

PRODUCT_PACKAGES += \
    fstab.default \
    fstab.default.vendor_ramdisk \
    fstab.zram.4g \
    init.class_main.sh \
    init.froggerpro.rc \
    init.qcom.early_boot.sh \
    init.qcom.post_boot.sh \
    init.qcom.rc \
    init.qcom.recovery.rc \
    init.qcom.sh \
    init.target.rc \
    ueventd.froggerpro.rc \
    ueventd.qcom.rc

# Keylayout
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/conf/keylayout/gpio-keys.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/gpio-keys.kl

# Keymint
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.keystore.app_attest_key.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.keystore.app_attest_key.xml \
    frameworks/native/data/etc/android.software.device_id_attestation.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_id_attestation.xml

PRODUCT_PACKAGES += \
    android.hardware.hardware_keystore_V3.xml

PRODUCT_PACKAGES += \
    vendor.lineage.health-service.default

# LiveDisplay
$(call soong_config_set_bool,livedisplay_sdm,enable_dm,false)

PRODUCT_PACKAGES += \
    vendor.lineage.livedisplay-service.sdm

# Media
PRODUCT_COPY_FILES += \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_video.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_telephony.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_telephony.xml

# NFC
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.nfc.hcef.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hcef.xml \
    frameworks/native/data/etc/android.hardware.nfc.hce.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hce.xml \
    frameworks/native/data/etc/android.hardware.nfc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.xml \
    frameworks/native/data/etc/com.android.nfc_extras.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/com.android.nfc_extras.xml \
    frameworks/native/data/etc/com.nxp.mifare.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/com.nxp.mifare.xml

PRODUCT_PACKAGES += \
    android.hardware.nfc-service.st

# Overlays
PRODUCT_ENFORCE_RRO_TARGETS := *

DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlay-lineage

PRODUCT_PACKAGES += \
    FroggerProApertureDevOverlay \
    FroggerProApertureOverlay \
    FroggerProEuiccOverlay \
    FroggerProFrameworksOverlay \
    FroggerProSettingsOverlay \
    FroggerProSettingsProviderOverlay \
    FroggerProSystemUIOverlay \
    FroggerProTelecommOverlay \
    FroggerProTelephonyOverlay \
    FroggerProWifiOverlay

# Page Size
PRODUCT_CHECK_PREBUILT_MAX_PAGE_SIZE := false

# Partitions
PRODUCT_BUILD_RECOVERY_IMAGE := true
PRODUCT_USE_DYNAMIC_PARTITIONS := true


PRODUCT_PACKAGES += \
    vendor_bt_firmware_mountpoint \
    vendor_dsp_mountpoint \
    vendor_firmware_mnt_mountpoint

# Power
PRODUCT_PACKAGES += \
    android.hardware.power-service.lineage-libperfmgr \
    libqti-perfd-client

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/conf/powerhint.json:$(TARGET_COPY_OUT_VENDOR)/etc/powerhint.json

# Properties
TARGET_ODM_PROP += $(DEVICE_PATH)/odm.prop
TARGET_PRODUCT_PROP += $(DEVICE_PATH)/product.prop
TARGET_SYSTEM_EXT_PROP += $(DEVICE_PATH)/system_ext.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Project ID Quota
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# QSPA
PRODUCT_PACKAGES += \
    qspa_vendor.rc \
    vendor.qti.qspa-service

# Ramdisk
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)

# Secure Element
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.nfc.ese.xml:$(TARGET_COPY_OUT_ODM)/etc/permissions/sku_JPN/android.hardware.nfc.ese.xml \
    frameworks/native/data/etc/android.hardware.se.omapi.ese.xml:$(TARGET_COPY_OUT_ODM)/etc/permissions/sku_JPN/android.hardware.se.omapi.ese.xml \
    frameworks/native/data/etc/android.hardware.se.omapi.uicc.xml:$(TARGET_COPY_OUT_ODM)/etc/permissions/sku_JPN/android.hardware.se.omapi.uicc.xml

# Security
BOOT_SECURITY_PATCH := 2026-09-01
INIT_BOOT_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
ODM_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
SYSTEM_DLKM_SECURITY_PATCH := $(BOOT_SECURITY_PATCH)
VENDOR_DLKM_SECURITY_PATCH := 2026-03-05
VENDOR_SECURITY_PATCH := 2026-05-01

# Sensors
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.dynamic.head_tracker.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.dynamic.head_tracker.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepcounter.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.stepcounter.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepdetector.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.stepdetector.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sku_kera/android.hardware.sensor.gyroscope.xml

TP_SYSFS_PATH := /sys/devices/platform/soc/8c0000.qcom,qupv3_2_geni_se/880000.spi/spi_master/spi8/spi8.0

$(call soong_config_set,nothing_sensors,tp_single_tap_path,$(TP_SYSFS_PATH)/fts_gesture_single_tap_pressed)
$(call soong_config_set,nothing_sensors,tp_single_tap_enabled_path,$(TP_SYSFS_PATH)/fts_gesture_single_tap_enabled)
$(call soong_config_set,nothing_sensors,tp_single_tap_coords_path,/proc/touchpanel/gesture_code)

$(call soong_config_set,nothing_sensors,tp_udfps_path,$(TP_SYSFS_PATH)/fts_fod_pressed)

PRODUCT_PACKAGES += \
    sensors.nothing \
    sensors.dynamic_sensor_hal

# SKUs
$(foreach sku, EEA JPN IND TUR, \
    $(eval PRODUCT_COPY_FILES += \
        $(LOCAL_PATH)/sku/build_$(sku).prop:$(TARGET_COPY_OUT_ODM)/etc/build_$(sku).prop))
        
# Soong
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH) \
    hardware/google/interfaces \
    hardware/google/pixel \
    hardware/lineage/interfaces/power-libperfmgr \
    hardware/qcom-caf/common/libqti-perfd-client \
    vendor/nothing/FroggerPro \
    vendor/nothing/NanoGlyph \
    packages/apps/HieroGlyph \
    packages/apps/GlyphBridge

# Storage
PRODUCT_CHARACTERISTICS := nosdcard

# Telephony
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.telephony.cdma.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.cdma.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.telephony.ims.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.ims.xml \
    frameworks/native/data/etc/android.hardware.telephony.mbms.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.mbms.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.sip.voip.xml

PRODUCT_PACKAGES += \
    extphonelib \
    extphonelib-product \
    extphonelib.xml \
    extphonelib_product.xml \
    ims-ext-common \
    ims_ext_common.xml \
    qti-telephony-hidl-wrapper \
    qti-telephony-hidl-wrapper-prd \
    qti-telephony-utils \
    qti_telephony_hidl_wrapper.xml \
    qti_telephony_hidl_wrapper_prd.xml \
    qti_telephony_utils.xml \
    telephony-ext

PRODUCT_BOOT_JARS += \
    telephony-ext

# Thermal
PRODUCT_PACKAGES += \
    android.hardware.thermal-service.qti

# USB
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml

PRODUCT_PACKAGES += \
    android.hardware.usb.gadget-service.qti \
    android.hardware.usb-service.qti \
    init.qcom.usb.rc \
    init.qcom.usb.sh

PRODUCT_SOONG_NAMESPACES += \
    vendor/qcom/opensource/usb/etc

# Update Engine
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

# Vendor Service Manager
PRODUCT_PACKAGES += \
    vndservicemanager

# Verified Boot
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.verified_boot.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.verified_boot.xml

# Vibrator
    # Vibrator: 改用 blob 版（同名 source 版會讓 init 全部失效 ⇒ C162）

# Wi-Fi
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.wifi.aware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.aware.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.passpoint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.passpoint.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.ipsec_tunnels.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnels.xml

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/conf/wifi/WCNSS_qcom_cfg.ini:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/qca6750/WCNSS_qcom_cfg.ini

PRODUCT_PACKAGES += \
    android.hardware.wifi-service \
    firmware_WCNSS_qcom_cfg.ini_symlink \
    firmware_wlanmdsp.otaupdate_symlink \
    firmware_wlan_mac.bin_symlink \
    hostapd \
    libwifi-hal-ctrl \
    libwifi-hal-qcom \
    wpa_supplicant \
    wpa_supplicant.conf


# Diagnostics that have to survive the update: an always-on logcatd is how a first-stage failure on this
# device gets observed at all (no USB until the framework comes up), and MTP lets files off the phone.
#
# ★ C89：讓 WITH_ADB_INSECURE 真正生效（修根因 ✓）
#
# 我們原本把它放在 BoardConfig.mk，但唯一的消費者 vendor/lineage/config/common.mk:35 是在
# **產品設定階段**求值的，而 BoardConfig 的變數在那時還看不到 ✗ ⇒ Lineage 走 else 分支：
#     ro.adb.secure=1 ＋ PRODUCT_NOT_DEBUGGABLE_IN_USERDEBUG := true
# ⇒ 產物 system/build.prop 出現 ro.debuggable=0 ✗（9/28 建置實測 ✓；9/26 建置因為上游還沒加這段
#    邏輯而仍是 ro.debuggable=1 ✓ —— 這也是「兩份 build.prop 只差幾行」的原因之一 ✓）
# ⇒ 後果：我們的 ROM 開機後 adb 可能不可用 ✗，而「沒有 adb」會被誤判成「沒開機」✗。
#
# 本檔（device.mk）在 lineage_FroggerPro.mk 中比 vendor/lineage/config/common_full_phone.mk 更早被繼承 ✓
# ⇒ 在這裡設定，上游機制即可正常運作 ✓（不是繞道，是把開關放回它該在的階段 ✓）。
# C305（2026-10-06 發布）：移除 WITH_ADB_INSECURE ✗（原：WITH_ADB_INSECURE := true）
#   ⇒ 走 vendor/lineage/config/common.mk:38-44 的 else 分支 ⇒ ro.adb.secure=1 ✓
#      ＋ PRODUCT_NOT_DEBUGGABLE_IN_USERDEBUG := true ⇒ ro.debuggable=0 ✓
#   ＝ 【LineageOS 官方標準】✓（使用者需在開發者選項手動開啟 USB 偵錯 ✓
#      或「Rooted debugging」臨時取得 root ✓）

# NOTE (C65 follow-up): the old local add-ons vendor_extra_blobs.mk / vendor_missing_modules.mk are deliberately
# NOT re-included any more. They were written against the July device tree and list modules by name
# (init.qcom.rc, fstab.default, FroggerPro*Overlay, froggerPro_hidl_vendor_deps, ...) that upstream's current
# tree no longer defines that way, so kati aborts with "includes non-existent modules in PRODUCT_PACKAGES".
# Upstream now installs that content itself; if a later link step turns out to need vendor libs again, add the
# specific modules back rather than the whole list.
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.usb.config=adb,mtp \
    ro.adb.secure=0 \
    persist.logd.logpersistd=logcatd

# Nothing 點陣字型（C176 ✓）
-include device/nothing/froggerPro/fonts.mk

# C 案：原廠缺失服務移植（copy-only ✓ C240 ✓）
$(call inherit-product, vendor/nothing/FroggerPro/c_blobs.mk)
# 原廠 odm 內容移植（C ✓ copy-only ✓）
$(call inherit-product, vendor/nothing/FroggerPro/odm_content.mk)

# C 案：原廠缺失 HAL 的 VINTF manifest（改用正確機制 ✓ 不用 PRODUCT_COPY_FILES ✗）
# MINI3_TEST 停用（疑似卡 logo 元凶 ✗ 2026-10-04）：DEVICE_MANIFEST_FILE += vendor/nothing/FroggerPro/extra_files_c/etc/vintf/manifest/android.hardware.biometrics.face-service.noth.xml
# MINI3_TEST 停用（疑似卡 logo 元凶 ✗ 2026-10-04）：DEVICE_MANIFEST_FILE += vendor/nothing/FroggerPro/extra_files_c/etc/vintf/manifest/vendor.cnce.hardware.facsvc@2.0-service.xml
# MINI3_TEST 停用（疑似卡 logo 元凶 ✗ 2026-10-04）：DEVICE_MANIFEST_FILE += vendor/nothing/FroggerPro/extra_files_c/etc/vintf/manifest/vendor.noth.hardware.camera-service.xml
# MINI3_TEST 停用（疑似卡 logo 元凶 ✗ 2026-10-04）：DEVICE_MANIFEST_FILE += vendor/nothing/FroggerPro/extra_files_c/etc/vintf/manifest/vendor.noth.hardware.stability-service.xml
# MINI3_TEST 停用（疑似卡 logo 元凶 ✗ 2026-10-04）：DEVICE_MANIFEST_FILE += vendor/nothing/FroggerPro/extra_files_c/etc/vintf/manifest/vendor.noth.hardware.thermal-service.xml
# 停用原廠震動 VINTF（其 HAL 會卡開機 ✗ 2026-10-04）：DEVICE_MANIFEST_FILE += vendor/nothing/FroggerPro/extra_files_c/etc/vintf/manifest/vendor.qti.hardware.vibrator.service.xml
# MINI3_TEST 停用（疑似卡 logo 元凶 ✗ 2026-10-04）：DEVICE_MANIFEST_FILE += vendor/nothing/FroggerPro/extra_files_c/etc/vintf/manifest/vendor.qti.hardware.wifi.wifilearner-service.xml
# MINI3_TEST 停用（疑似卡 logo 元凶 ✗ 2026-10-04）：DEVICE_MANIFEST_FILE += vendor/nothing/FroggerPro/extra_files_c/etc/vintf/manifest/vendor.qti.memory.pasrmanager-service.xml
# MINI3_TEST 停用（HAL 二進位不在映像 ✗ C224 模式 ✓）：DEVICE_MANIFEST_FILE += vendor/nothing/FroggerPro/extra_odm/ovl_overlayfs_origin/vendor/etc/vintf/manifest/android.hardware.security.keymint-service.strongbox-thales.xml
# MINI3_TEST 停用（HAL 二進位不在映像 ✗ C224 模式 ✓）：DEVICE_MANIFEST_FILE += vendor/nothing/FroggerPro/extra_odm/ovl_overlayfs_origin/vendor/etc/vintf/manifest/android.hardware.security.sharedsecret-service.strongbox-thales.xml
# MINI3_TEST 停用（HAL 二進位不在映像 ✗ C224 模式 ✓）：DEVICE_MANIFEST_FILE += vendor/nothing/FroggerPro/extra_odm/ovl_overlayfs_origin/vendor/etc/vintf/manifest/android.hardware.weaver-service.thales.xml
$(call inherit-product, vendor/nothing/FroggerPro/c_modules.mk)

# 我方自製震動 HAL 的 VINTF ✓（二進位確實存在 ✓ 2026-10-04）
DEVICE_MANIFEST_FILE += vendor/nothing/FroggerPro/etc/vintf/manifest/android.hardware.vibrator.service.froggerpro-richtap.xml

# 2026-10-06 C-SVC：補 3 個原廠 HAL 的 VINTF 宣告 ✓（執行期崩潰的【真因】✓）
#   症狀：/vendor/bin/hw/{vendor.qti.hardware.servicetrackeraidl-service,
#         vendor.qti.hardware.lights.service,
#         android.hardware.biometrics.face-service.noth}
#         在 main() SIGABRT『Check failed: status == STATUS_OK』⇒ 每 ~6.6 s 崩一次 ✗
#   真因 ✓：這 3 個二進位都用 AIDL 且 binder 呼叫 AIBinder_markVintfStability（實證見 strings／
#           readelf --dyn-syms）⇒ servicemanager 的 meetsDeclarationRequirements
#           (frameworks/native/cmds/servicemanager/ServiceManager.cpp:342) 會要求該 fqname
#           必須出現在 VINTF device manifest ⇒ 我們沒宣告 ✗ ⇒ AServiceManager_addService
#           回傳非 STATUS_OK ✗ ⇒ CHECK 失敗 ⇒ abort ✗
#   同型先例 ✓：C208（android.hardware.sensors 同症狀同修法，實機驗證成功 ✓）
#   ⚠️ VINTF metadata 不可用 PRODUCT_COPY_FILES ✗（build/make/core/Makefile:148 會報錯 ✗）
#      ⇒ 必須走 DEVICE_MANIFEST_FILE ✓
DEVICE_MANIFEST_FILE += \
    vendor/nothing/FroggerPro/etc/vintf/manifest/vendor.qti.hardware.servicetrackeraidl-service.xml \
    vendor/nothing/FroggerPro/etc/vintf/manifest/vendor.qti.hardware.lights.service.xml \
    vendor/nothing/FroggerPro/etc/vintf/manifest/android.hardware.biometrics.face-service.noth.xml \
    vendor/nothing/FroggerPro/etc/vintf/manifest/vendor.noth.hardware.thermal-service.xml \
    vendor/nothing/FroggerPro/etc/vintf/manifest/vendor.qti.memory.pasrmanager-service.xml

# C304（2026-10-06）：pasrmanager oneshot 靜默崩潰 ✗ 修法（子代理 R 盤點發現 ✓ 助理覆核 ✓）
#   實機證據 ✓：開機時 SIGABRT『Check failed: status == STATUS_OK』✗
#     （＝ servicemanager 因 VINTF 缺宣告而拒絕註冊 ⇒ 與 C300 thermal 同病因 ✓）
#   為什麼難發現 ✗：它是 __oneshot__ 服務 ⇒ 崩了【不再重試】✗
#     ⇒ 不會出現在 `getprop | grep init.svc | grep restarting` 清單 ✗ ⇒ 靜默黑數 ✓
#   兩層檢查 ✓：service_contexts【已有】✓ ⇒ 只缺 VINTF 這一層 ⇒ 補宣告即可 ✓
#   原廠逐字複製 ✓（stock OTA: vendor/etc/vintf/manifest/vendor.qti.memory.pasrmanager-service.xml）
#   影響範圍：QTI 記憶體管理（次要功能 ✓ 非開機／核心路徑 ✓）
#   ⚠️ 此項【不在】2026-10-04「疑似卡 logo」那批停用名單內 ✓（該批為 face/facsvc/camera/
#      stability/thermal/vibrator/wifilearner ✗）⇒ 無該項顧慮 ✓

# C300（2026-10-06）：vendor.noth.thermal-default 每 5 秒崩潰 ✗ 的第二層修法
#   實機證據 ✓：servicemanager 回
#     "Could not find vendor.noth.hardware.thermal.IThermalControl/default in the VINTF manifest"
#   ⇒ 與 2026-10-05 修的 lights/face/servicetracker 同病因（缺 VINTF 宣告）✓
#   ⇒ 第一層（SELinux service_contexts，C296）已修 ✓ avc 已消失 ✓
#   ⇒ 本行補第二層：VINTF device manifest 宣告 ✓（原廠逐字複製 ✓）

# C272：原廠缺件補回（keylayout ＋ 硬體編解碼器）✓
-include vendor/nothing/FroggerPro/stock_add.mk

# C273：安全版全量補檔（不含 VINTF ✓）
-include vendor/nothing/FroggerPro/stock_full.mk

# C273：缺的 VINTF 宣告 ✓
# C273d 暫停：soong glob 快取問題 ✗ 24 個新 VINTF 先不裝 ✓（69/93 本來就已宣告 ✓）
# -include vendor/nothing/FroggerPro/stock_vintf.mk
