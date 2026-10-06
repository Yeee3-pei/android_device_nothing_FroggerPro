#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_system.mk)

$(call inherit-product, $(SRC_TARGET_DIR)/product/handheld_product.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/telephony_product.mk)

$(call inherit-product, $(SRC_TARGET_DIR)/product/handheld_system_ext.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/telephony_system_ext.mk)

$(call inherit-product, $(SRC_TARGET_DIR)/product/handheld_vendor.mk)

$(call inherit-product, device/nothing/froggerPro/device.mk)
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_BRAND := Nothing
PRODUCT_DEVICE := FroggerPro
PRODUCT_MANUFACTURER := Nothing
PRODUCT_MODEL := A069P
PRODUCT_NAME := lineage_FroggerPro

PRODUCT_GMS_CLIENTID_BASE := android-nothing

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="qssi_64-user 16 BQ2A.250913.001-BP2A.250605.031.A3 2609071153 release-keys" \
    BuildFingerprint=Nothing/FroggerPro/FroggerPro:16/BQ2A.250913.001-BP2A.250605.031.A3/2609071153:user/release-keys \
    DeviceName=FroggerPro \
    DeviceProduct=FroggerPro \
    SystemDevice=FroggerPro \
    SystemName=FroggerPro

# 自製 App（C176 ✓）
PRODUCT_PACKAGES += FroggerProLauncher

# 自製 App（C176 ✓）
PRODUCT_PACKAGES += FroggerProEssential

# C305（2026-10-06 發布）：依使用者決定（選項 2）【不把隱私 App 放進公開發布版】✓
#   ⇒ 公開版＝純 LineageOS 體驗 ✓；隱私 App 只保留在 lineage_FroggerPro_privacy ✓
#   （原為 2026-10-06 暫時收進主產品以方便實機驗證 ⇒ 驗證目的已達成 ⇒ 移除 ✓）
# PRODUCT_PACKAGES += FroggerProPrivacy   ← 已停用 ✗
