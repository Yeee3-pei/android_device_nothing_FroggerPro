#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# ★ 第二支：隱私／客製版（FroggerPro_privacy）
#
# 設計原則（見 ~/nphone/PLAN_two_builds_privacy_tiers.md，已過 sol 覆核）：
#   - 共用同一棵 device tree（config.fs / sepolicy / rro_overlays / system.prop 全部共用 ✓）
#   - 只在本檔覆寫「產品層」的差異：套件清單、屬性、以及（日後）排除原廠元件
#   - 上游 bug 修一次兩支都受益（例：60fps 的 Aperture overlay = C171 ✓）
#
# ⚠️ 第一版刻意【先證明機制可行】（sol 要求：實跑 lunch 與建置 ✓），
#    尚未填入 OEM 元件的排除清單 —— 那需要先逐項盤點「哪些原廠元件與隱私限制衝突」，
#    盤點完成後才用 PRODUCT_PACKAGES := $(filter-out ...) 精準排除，不憑猜測刪東西 ✓。

$(call inherit-product, device/nothing/froggerPro/lineage_FroggerPro.mk)

# 產品識別：必須與 lineage_FroggerPro 不同，否則 out/ 目錄與 OTA 會相撞 ✗
PRODUCT_NAME := lineage_FroggerPro_privacy

# 隱私設定 App（骨架：真實生效的開關 ＋ 等級選單 ✓）
# 放在 device tree 而非 hardware/nothing 上游 ⇒ 不分叉上游 ✓
PRODUCT_PACKAGES += \
    FroggerProPrivacy

# 讓兩支在裝置上看得出差異（也方便日後回報時確認刷的是哪一支 ✓）
PRODUCT_PROPERTY_OVERRIDES += \
    ro.froggerpro.variant=privacy

PRODUCT_MODEL := A069P
PRODUCT_BRAND := Nothing
PRODUCT_DEVICE := FroggerPro
PRODUCT_MANUFACTURER := Nothing

# ★ 2026-10-06 C302：移除「隱私版預設關 adb」的改動（使用者決定 ✓）★
#   使用者逐字：「H4 沒必要有這個開關，開發者選項就可以關閉」
#   ⇒ 隱私版【不需要】專屬的 adb 預設開關 ✓：使用者在【開發者選項】關掉 USB 偵錯即可 ✓
#   ⚠️ 同時記錄技術事實（避免日後重做白工 ✗）：
#      先前在這裡 filter-out 的是【vendor 屬性】✗，但真正的來源是
#        system.prop:10 的 `persist.sys.usb.config=adb,mtp` ✓
#        （經 build/make/core/config.mk:1277 自動併入 ⇒ 兩支 product 共用 ✗）
#      ⇒ 該改動本來就【無效】✗ ⇒ 依「不留技術債」原則整段移除 ✓
#   ⇒ 若日後真要「發布版預設關 adb」：改 system.prop 分版處理 ＋
#      ro.adb.secure 需在 inherit 之前（vendor/lineage/config/common.mk:31-48）處理 ✓

# 隱私版基線（建置期，不可執行期切換 —— 與 App 開關的界線一致 ✓）
# 待盤點後填入：
#   - PRODUCT_PACKAGES := $(filter-out <原廠元件...>, $(PRODUCT_PACKAGES))
#   - 遙測／統計相關的上游旗標

# 自製 App（C176 ✓）
PRODUCT_PACKAGES += FroggerProLauncher

# 自製 App（C176 ✓）
PRODUCT_PACKAGES += FroggerProEssential
