#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/nothing/FroggerPro

include build/make/target/board/BoardConfigMainlineCommon.mk
include vendor/nothing/FroggerPro/BoardConfigVendor.mk

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    init_boot \
    odm \
    product \
    recovery \
    system_dlkm \
    system_ext \
    system \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor \
    vendor_boot \
    vendor_dlkm \
    vendor

# API
BOARD_SHIPPING_API_LEVEL := 202404

# adb must be up on a userdebug A16 build without unlocking anything manually: logcat is the only window
# onto a first-stage failure on this device. Restored after the upstream update (it was a local edit).
# C305（2026-10-06 發布）：移除 WITH_ADB_INSECURE ✗（原：WITH_ADB_INSECURE := true）
#   ⇒ 走 vendor/lineage/config/common.mk:38-44 的 else 分支 ⇒ ro.adb.secure=1 ✓
#      ＋ PRODUCT_NOT_DEBUGGABLE_IN_USERDEBUG := true ⇒ ro.debuggable=0 ✓
#   ＝ 【LineageOS 官方標準】✓（使用者需在開發者選項手動開啟 USB 偵錯 ✓
#      或「Rooted debugging」臨時取得 root ✓）

# AVB
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

BOARD_AVB_BOOT_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_BOOT_ALGORITHM := SHA256_RSA4096
BOARD_AVB_BOOT_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_BOOT_ROLLBACK_INDEX_LOCATION := 3

BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

BOARD_AVB_VBMETA_SYSTEM := product system system_ext
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2

BOARD_AVB_VBMETA_VENDOR := odm system_dlkm vendor vendor_dlkm
BOARD_AVB_VBMETA_VENDOR_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VBMETA_VENDOR_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX_LOCATION := 4

BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
# ── CPU／ART 指令集（C265-fix2 ✓ 2026-10-04）──────────────────────
# 兩次試錯的實證（都失敗 ✗ 但已找出真因 ✓）：
#   ① 改 system.prop ⇒ 無效 ✗（vendor/build.prop 同鍵會覆蓋 ✗）
#   ② 在 BoardConfig 設 DEX2OAT_TARGET_CPU_VARIANT_RUNTIME ⇒ 無效 ✗
#      config.mk:1135 它會被無條件重算：
#      DEX2OAT_TARGET_CPU_VARIANT_RUNTIME := $(first_non_empty_of_three,
#          $(TARGET_CPU_VARIANT_RUNTIME),$(TARGET_CPU_VARIANT_RELEASE),$(TARGET_CPU_VARIANT))
# ✓ 正解＝TARGET_CPU_VARIANT_RUNTIME（board_config.mk:300）：
#   TARGET_CPU_VARIANT_RUNTIME := $(or $(TARGET_CPU_VARIANT_RUNTIME),$(TARGET_CPU_VARIANT))
#   ⇒ 用 or ✓ 我們先設就不會被覆蓋 ✓
#   ⇒ 一次餵兩個屬性 ✓ ro.bionic.cpu_variant ＋ dalvik.vm.isa.arm64.variant ✓（sysprop_config.mk:21,29 ✓）
#   ⇒ 無合法性檢查 ✓（board_config.mk:54 只是 readonly 清單 ✓）
TARGET_CPU_VARIANT_RUNTIME := kryo300
DEX2OAT_TARGET_INSTRUCTION_SET_FEATURES := default


# Audio
AUDIO_FEATURE_ENABLED_DLKM := true
AUDIO_FEATURE_ENABLED_GKI := true
AUDIO_FEATURE_ENABLED_INSTANCE_ID := true
AUDIO_FEATURE_ENABLED_MCS := true
AUDIO_FEATURE_ENABLED_SVA_MULTI_STAGE := true
# BOARD_SUPPORTS_OPENSOURCE_STHAL := true

# Board
TARGET_BOARD_INFO_FILE := $(DEVICE_PATH)/android-info.txt

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := FroggerPro

# Boot
BOARD_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)

BOARD_INIT_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_INIT_ARGS += --header_version $(BOARD_INIT_BOOT_HEADER_VERSION)

# DTB
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
#BOARD_KERNEL_SEPARATED_DTBO := true
#BOARD_USES_QCOM_MERGE_DTBS_SCRIPT := true
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/dtb
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/dtbo.img

# Display
TARGET_SCREEN_DENSITY := 420

# Filesystem
TARGET_FS_CONFIG_GEN := $(DEVICE_PATH)/config.fs

# Graphics
TARGET_USES_VULKAN := true

# Kernel
BOARD_BOOTCONFIG := \
    androidboot.hardware=qcom \
    androidboot.load_modules_parallel=true \
    androidboot.usbcontroller=a600000.dwc3
    
BOARD_KERNEL_CMDLINE := \
    androidboot.serialconsole=0 \
    firmware_class.path=/vendor/firmware,/vendor/firmware_mnt/image,/firmware/image \
    log_buf_len=1M \
    nosoftlockup \
    sysctl.kernel.firmware_config.force_sysfs_fallback=1

BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_KERNEL_PAGESIZE := 4096
BOARD_RAMDISK_USE_LZ4 := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true

TARGET_KERNEL_SOURCE := kernel/nothing/sm8750
TARGET_KERNEL_CONFIG := \
    gki_defconfig \
    vendor/sun_perf.config \
    vendor/noth_common.config \
    vendor/froggerpro_perf.config

TARGET_KERNEL_EXT_MODULE_ROOT := kernel/nothing/sm8750-modules
TARGET_KERNEL_EXT_MODULES := \
    qcom/opensource/mmrm-driver \
    qcom/opensource/mm-drivers/hw_fence \
    qcom/opensource/mm-drivers/msm_ext_display \
    qcom/opensource/mm-drivers/sync_fence \
    qcom/opensource/audio-kernel \
    qcom/opensource/securemsm-kernel \
    qcom/opensource/synx-kernel \
    qcom/opensource/camera-kernel \
    qcom/opensource/data-kernel/drivers/smem-mailbox \
    qcom/opensource/datarmnet-ext/mem \
    qcom/opensource/dataipa/drivers/platform/msm \
    qcom/opensource/datarmnet/core \
    qcom/opensource/datarmnet-ext/aps \
    qcom/opensource/datarmnet-ext/offload \
    qcom/opensource/datarmnet-ext/perf \
    qcom/opensource/datarmnet-ext/perf_tether \
    qcom/opensource/datarmnet-ext/sch \
    qcom/opensource/datarmnet-ext/shs \
    qcom/opensource/datarmnet-ext/wlan \
    qcom/opensource/display-drivers/msm \
    qcom/opensource/dsp-kernel \
    qcom/opensource/eva-kernel \
    qcom/opensource/graphics-kernel \
    qcom/opensource/spu-kernel \
    qcom/opensource/touch-drivers \
    qcom/opensource/video-driver \
    qcom/opensource/wlan/platform \
    qcom/opensource/wlan/qcacld-3.0/.qca6750 \
    qcom/opensource/bt-kernel \
    st/opensource/driver \
    st/opensource/eSE-driver

BOARD_SYSTEM_KERNEL_MODULES_BLOCKLIST_FILE := $(DEVICE_PATH)/modules.blocklist.system_dlkm
BOARD_SYSTEM_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/modules.load.system_dlkm))
BOARD_VENDOR_KERNEL_MODULES_BLOCKLIST_FILE := $(DEVICE_PATH)/modules.blocklist.vendor_dlkm
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/modules.load.vendor_dlkm))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/modules.load.vendor_boot))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/modules.load.recovery))
BOOT_KERNEL_MODULES := $(BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD)
SYSTEM_KERNEL_MODULES := $(BOARD_SYSTEM_KERNEL_MODULES_LOAD)

# Partitions
# 本機（FroggerPro）修正（C79）：群組名由 qti_dynamic_partitions 改為 default ✓
#
# 證據：以原始 lpdump 比對三顆 super 的分組與屬性 ——
#   原廠（twrprecure/super.img，能開機 ✓）      : Group 只有 default；system_a Attributes = readonly
#   9/26（能開機的那版 ✓）                      : Group 只有 default；system_a Attributes = readonly
#   我們 9/28（卡 logo、USB 全無 ✗）            : Group = qti_dynamic_partitions_a/b；Attributes = none ✗
# ⇒ 原廠與唯一能開機的版本完全一致，我們是唯一的偏離 ✗。
# 來源：這四行是上游 2e9ef80（Alexander Koskovich, 2026-05-07）寫的，非本地改動 ✓。
#
# 依 build/make/core/config.mk:1003 的機制，AOSP 會把群組名轉大寫後找
# BOARD_<GROUP>_PARTITION_LIST 與 BOARD_<GROUP>_SIZE ⇒ 故改名後變數名必須同步 ✓。
BOARD_DEFAULT_PARTITION_LIST := odm product system system_dlkm system_ext vendor vendor_dlkm
# ★ C103 實驗（v4）：群組宣告值必須 < super/2（4,831,838,208）✗
#   證據：v3 把 vendor 宣告值修小後，check_all_partition_sizes 的錯誤由
#     "sum of sizes of ['odm','product','system',...,'vendor_dlkm']" ✗（7 個分區）
#     變成 "sum of sizes of ['default']" ✗（群組本身）
#   ⇒ 分區總和已通過 ✓（4,183,564,288 < 4,831,838,208 ✓）⇒ 只剩群組值超標 ✗
#   原值 9659482112 ✗ ≥ 4831838208 ✗ ⇒ 改為 4829184000（＝4096 × 1179000 ✓）
BOARD_DEFAULT_SIZE := 4829184000 # BOARD_SUPER_PARTITION_SIZE - 4MiB
BOARD_SUPER_PARTITION_GROUPS := default
BOARD_SUPER_PARTITION_SIZE := 9663676416

# ★ C100（完成 C84 只寫了註解、未落地的部分 ✓）：給 retrofit 動態分區所需的兩個 BOARD 變數 ✓
#
# config.mk:1021-1033 在 PRODUCT_RETROFIT_DYNAMIC_PARTITIONS=true 時要求：
#   ① BOARD_SUPER_PARTITION_METADATA_DEVICE 必須存在（否則 $(error)）
#   ② BOARD_SUPER_PARTITION_BLOCK_DEVICES 必須存在，且 metadata device 要在清單裡
# 本機的 super 是真的實體分區（/dev/block/by-name/super → sda6 ✓）⇒ 兩者都填 super ✓
# 又因 metadata device 就是 super，config.mk 不會額外注入 androidboot.super_partition ✓（cmdline 不變 ✓）
BOARD_SUPER_PARTITION_METADATA_DEVICE := super
BOARD_SUPER_PARTITION_BLOCK_DEVICES := super

# ★ C100 說明（結論：in-tree 路線不可行 ✗，改用 scripts/make_super_retrofit.sh ✓）
#
# 目標：讓 super 走 retrofit 幾何（`--metadata-slots 2` ＋ 單一 default 群組 ＋ readonly ✓），
#       即原廠與 EvoX 共有的、實測能開機的形狀 ✓
#
# 兩條 in-tree 路線都已實測失敗 ✗：
#   ① PRODUCT_RETROFIT_DYNAMIC_PARTITIONS 寫在 device.mk ⇒ 被 config.mk:911 守衛
#      （PRODUCT_SHIPPING_API_LEVEL=36 ≥ 29）直接 $(error) 擋下 ✗
#   ② 移除 PRODUCT_SHIPPING_API_LEVEL 以繞過守衛 ✗ ⇒ soong 的 hardware/lineage/compat
#      vendorcompat 模組命名相撞（"module ... already defined"）建置失敗 ✗
#   ③ 把 PRODUCT_RETROFIT_DYNAMIC_PARTITIONS 寫在 BoardConfig.mk（守衛已過）✗ ⇒ 同樣觸發
#      soong_config.mk:492 ProductRetrofitDynamicPartitions 的模組重複定義 ✗
#   ⇒ 這就是為什麼下面這兩行刻意保留但**不啟用** retrofit ✓（它們對非 retrofit 路徑是預設值 ✓）
#
# 替代方案（本機採用 ✓）：用自己的 lpmake 產生正確形狀的 super ✓
#   script: /home/laixi/nphone/bootrec/make_super_retrofit.sh
#   （長期若要 in-tree：需在本機分支 patch build/make/core/config.mk 的守衛，等使用者決定 ✓）
# ignore: C100-in-tree-attempts-failed
BOARD_SUPER_PARTITION_METADATA_DEVICE := super
BOARD_SUPER_PARTITION_BLOCK_DEVICES := super

# 本機（FroggerPro）修正（C84）：採用 retrofit 動態分區 ✓
#
# 證據（以原始 lpdump 比對 superH7＝實測能開機的那顆）：
#   superH7 : Metadata version 10.0 / Metadata slot count 2 / Header flags: none
#             Group table 只有 default（Maximum size 0 bytes）
#   我們    : Metadata version 10.0 / Metadata slot count 3 / Header flags: none
#             Group table 為 default（0 bytes）＋ default_a／default_b（各 9659482112 bytes）✗
#
# 成因（build/make/tools/releasetools/build_super_image.py）：
#   :81  retrofit = info_dict.get("dynamic_partition_retrofit") == "true"
#   :101 append_suffix = ab_update and not retrofit     ⇒ retrofit 時群組不加 _a／_b 後綴
#   :85,:92 if ab_update and retrofit: --metadata-slots 2   ⇒ retrofit 時 slot 數為 2
#   ⇒ 只有 retrofit=true 能同時產生「單一 default 群組」與「slot 數 2」，即 superH7 的形狀 ✓
#
# 註：config.mk:1039 會因此把 androidboot.super_partition=super 加入核心 cmdline（AOSP 的既定行為）✓
#     config.mk 亦要求這兩個 BOARD 變數必須存在且 metadata device 須在 block devices 清單中 ✓

BOARD_BOOTIMAGE_PARTITION_SIZE := 0x6000000
BOARD_DTBOIMG_PARTITION_SIZE := 0x3200000
BOARD_FLASH_BLOCK_SIZE := 131072 # (BOARD_KERNEL_PAGESIZE * 32)
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 0x800000
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 0x6400000
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 0x6000000

BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs

TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

# Platform
BOARD_USES_QCOM_HARDWARE := true
TARGET_BOARD_PLATFORM := sun

# RIL
ENABLE_VENDOR_RIL_SERVICE := true

# Recovery
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
BOARD_USES_FULL_RECOVERY_IMAGE := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/init/fstab.default
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_UI_MARGIN_HEIGHT := 100
TARGET_USERIMAGES_USE_F2FS := true

# SELinux
include vendor/nothing/NanoGlyph/sepolicy/config.mk
include hardware/nothing/config.mk
include device/qcom/sepolicy_vndr/SEPolicy.mk
include device/lineage/sepolicy/libperfmgr/sepolicy.mk

SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/public
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/private
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor

# VINTF
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += \
    $(DEVICE_PATH)/vintf/framework_matrix_nothing.xml \
    hardware/qcom-caf/common/vendor_framework_compatibility_matrix.xml \
    $(NANOGLYPH_PATH)/matrix/vintf/framework_matrix_nanoglyph.xml

DEVICE_MANIFEST_FILE += \
    $(DEVICE_PATH)/vintf/manifest.xml \
    $(AUDIO_HAL_DIR)/configs/sun/manifest_audio_qti_services.xml

# V10（2026-09-30）：把 EvoX 的 91 個 vintf 碎片接進建置（根因修法 ✓）
#   背景：我方 vendor/etc/vintf/manifest.xml 只宣告 5 個 HAL ✗，EvoX 宣告 104 個 ✓
#   機制：DEVICE_MANIFEST_FILE（Makefile:148 指定的正確做法，不可用 PRODUCT_COPY_FILES）
include $(DEVICE_PATH)/vintf/evox_vintf_fragments.mk

ODM_MANIFEST_FILES += $(DEVICE_PATH)/vintf/manifest_FroggerPro.xml    
ODM_MANIFEST_SKUS += JPN
ODM_MANIFEST_JPN_FILES += $(DEVICE_PATH)/vintf/manifest_JPN.xml

DEVICE_MATRIX_FILE += hardware/qcom-caf/common/compatibility_matrix.xml

# Wi-Fi
BOARD_WLAN_DEVICE := qcwcn
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
BOARD_WPA_SUPPLICANT_DRIVER := $(BOARD_HOSTAPD_DRIVER)
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := $(BOARD_HOSTAPD_PRIVATE_LIB)
BOARD_WPA_SUPPLICANT_PRIVATE_LIB_EVENT := "ON"
WIFI_DRIVER_STATE_CTRL_PARAM := "/dev/wlan"
WIFI_DRIVER_STATE_OFF := "OFF"
WIFI_DRIVER_STATE_ON := "ON"
WIFI_FEATURE_HOSTAPD_11AX := true
WIFI_FEATURE_SUPPLICANT_11AX := true
WIFI_HIDL_FEATURE_AWARE := true
WIFI_HIDL_FEATURE_DUAL_INTERFACE := true
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true
WPA_SUPPLICANT_VERSION := VER_0_8_X

# ============================================================================
# 本機（FroggerPro）修正 — 核心改用「從原始碼編譯 + ext modules」（C67）
#
# 上一版（C66）嘗試沿用預編譯核心以避開原始碼編譯，但實測失敗 ✗：
#   hardware/qcom-caf/sm8750/display/hal/gralloc/gr_dma_mgr.h:37:10:
#   fatal error: 'linux/qti-smmu-proxy.h' file not found
# 該標頭屬 ext module `qcom/opensource/securemsm-kernel`（smmu-proxy/include/uapi/linux/），
# 正是 upstream 在 TARGET_KERNEL_EXT_MODULES 中明列者 ⇒ 關掉 ext modules 就沒有它 ✗。
#
# 已驗證本機兩棵樹足以走此路線 ✓：
#   kernel/nothing/sm7750         Linux 6.6.102，HEAD 2f2119f512bd（與預編譯核心 vermagic
#                                 g2f2119f512bd 完全一致 ✓）
#   kernel/nothing/sm7750-modules upstream 明列的 31 個 ext module「一個都不缺」✓
# 唯一差異：upstream 清單中的 vendor/noth_common.config 本機不存在 ✗ ⇒ 自清單移除 ✓
#   （保留 gki_defconfig + vendor/sun_perf.config + vendor/froggerpro_perf.config ✓）
#
# ※ 2026-09-29：改回 upstream 的 sm8750（原本覆寫為 sm7750 ✗，理由是「SoC 名與本機目錄不符」✗）。
#   實測依據：上游裝置樹（8a79d6f "FroggerPro: Update for common kernel"）與 hardware/qcom-caf/sm8750 都
#   以 sm8750 為準；且兩棵核心 repo（nothing_sm7750 / nothing_sm8750）HEAD 相同（6242c82bd7d5）✓，
#   真正的差異在 kernoth_modules 與 devicetree。sm7750 分支缺 vendor/ 內容 ⇒ 建置失敗 ✗。
#   sm8750 + sm8750-modules + sm8750-devicetrees 三棵齊備 ⇒ 與維護者一致 ✓
TARGET_KERNEL_SOURCE := kernel/nothing/sm8750
TARGET_KERNEL_CONFIG := \
    gki_defconfig \
    vendor/sun_perf.config \
    vendor/noth_common.config \
    vendor/froggerpro_perf.config
TARGET_KERNEL_VERSION := 6.6

# ※ 不可省略 ✗：vendor/lineage 的 generated_kernel_includes 產生器會把此變數內插進
#   一段 shell（分支之一為 `gzip -d < $TARGET_PREBUILT_KERNEL_HEADERS | tar -x …`）。
#   若此變數恆空（因路徑不存在而被清掉）⇒ 產生出的腳本出現 `gzip -d <  | tar` ⇒
#   「syntax error near unexpected token `|'」⇒ 整支腳本在**解析階段**就失敗 ✗，
#   連「kernel Makefile 存在 ⇒ make headers_install」那條正確分支都跑不到 ✗。
#   本機 kernel/nothing/sm7750/Makefile 存在 ✓ ⇒ 執行時實際走 headers_install ✓，
#   此變數僅為讓腳本語法成立 ✓（檔案本身保持不刪，作為退路 ✓）。
TARGET_PREBUILT_KERNEL_HEADERS := $(DEVICE_PATH)/prebuilt/kernel-headers.tar.gz

TARGET_KERNEL_EXT_MODULE_ROOT := kernel/nothing/sm8750-modules
TARGET_KERNEL_EXT_MODULES := \
    qcom/opensource/mmrm-driver \
    qcom/opensource/mm-drivers/hw_fence \
    qcom/opensource/mm-drivers/msm_ext_display \
    qcom/opensource/mm-drivers/sync_fence \
    qcom/opensource/audio-kernel \
    qcom/opensource/securemsm-kernel \
    qcom/opensource/synx-kernel \
    qcom/opensource/camera-kernel \
    qcom/opensource/data-kernel/drivers/smem-mailbox \
    qcom/opensource/datarmnet-ext/mem \
    qcom/opensource/dataipa/drivers/platform/msm \
    qcom/opensource/datarmnet/core \
    qcom/opensource/datarmnet-ext/aps \
    qcom/opensource/datarmnet-ext/offload \
    qcom/opensource/datarmnet-ext/perf \
    qcom/opensource/datarmnet-ext/perf_tether \
    qcom/opensource/datarmnet-ext/sch \
    qcom/opensource/datarmnet-ext/shs \
    qcom/opensource/datarmnet-ext/wlan \
    qcom/opensource/display-drivers/msm \
    qcom/opensource/dsp-kernel \
    qcom/opensource/eva-kernel \
    qcom/opensource/graphics-kernel \
    qcom/opensource/spu-kernel \
    qcom/opensource/touch-drivers \
    qcom/opensource/video-driver \
    qcom/opensource/wlan/platform \
    qcom/opensource/wlan/qcacld-3.0/.qca6750 \
    qcom/opensource/bt-kernel \
    st/opensource/driver \
    st/opensource/eSE-driver

# 註：模組來源不再指向 prebuilt/modules ⇒ 由 kernel + ext modules 原始碼編譯產出 ✓
#     upstream 已接好 BOARD_*_KERNEL_MODULES_LOAD 與 *_BLOCKLIST_FILE（指向 device tree
#     內的 modules.load.* / modules.blocklist.* ✓），本處不需再覆寫 ✓

# ============================================================================
# 本機（FroggerPro）修正 — 允許 ELF 檔以 PRODUCT_COPY_FILES 安裝（C69）
#
# 症狀 ✗：
#   out/target/product/FroggerPro/vendor/bin/agmhostless: error: found ELF prebuilt in
#   PRODUCT_COPY_FILES, use cc_prebuilt_binary / cc_prebuilt_library_shared instead.
#   FAILED: .../obj/FAKE/check-non-elf-file-timestamps_intermediates/.../agmplay.timestamp
#
# 根因：本機 vendor 樹的 `.mk` 是**舊式**產生器產出的（`PRODUCT_COPY_FILES` 直搬檔案 ✓），
#   其中包含 vendor/bin 下的 ELF 執行檔（agmhostless、agmplay… 以及眾多 .so ✗）。
#   AOSP 自某版起禁止此做法 ✗，要求改用 soong 的 cc_prebuilt_binary/cc_prebuilt_library_shared ✗。
#   ⇒ 與 C66-8 的 VINTF、C65 的 dup-copy 同源：**都是自產舊式 .mk 與新樹規範衝突** ✗。
#
# 處置：啟用 AOSP 為此保留的正式開關 ✓（build/make/core/board_config.mk:179 ✓）
#   —— 這是 AOSP 允許 device tree 使用、把錯誤降為警告的既定機制 ✓，非 hack ✗。
#   長遠正解是把產生器改成輸出 soong prebuilt 模組 ✗（與 C66-4 的 VINTF 同列待辦 ✓）。
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
