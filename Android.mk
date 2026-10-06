#
# /vendor/lib64 頂層三個 Adreno 名稱：原廠/EvoX 映像是【symlink → lib64/egl/<name>】，
# 本樹原本以 PRODUCT_COPY_FILES 複製成【實體檔】（FroggerPro-vendor.mk 的 1063/1066/1069 三條，
# 已移除）。PRODUCT_COPY_FILES 無法產生 symlink。
#
# 為什麼放在 Android.mk 而不是 product 設定檔：$(TARGET_OUT_VENDOR) 在 product 設定檔解析時
# 【尚未定義】✗（實測 kati 會把目標誤解析為 /lib64/… 並報 writing to readonly directory ✗）；
# Android.mk 在 make 階段解析 ✓ 該變數已由 config.mk 定義 ✓。
# 也不可用 FORCE：kati 禁止實體安裝檔依賴 PHONY 目標
# （error: real file ... depends on PHONY target "FORCE" ✗）。
#
# 預先註冊的驗證判準（刷機後先確認連結存在 ✓，再觀察行為 ✓）：
#   ① ls -la /vendor/lib64/libGLESv2_adreno.so 應為 -> /vendor/lib64/egl/libGLESv2_adreno.so
#   ② logcat AdrenoGLES-0: Driver Path 是否顯示解析後路徑
#   ③ renderer 是否由 Adreno (TM) 4XX 變成 722；Skia 是否不再報 no supported rendering path
#   ⇒ 若 ① 成立而 ②③ 不變 ⇒ 只能判定「此修改不足以修復」✗，不能判定驅動路徑假設整體死亡 ✓
#
LOCAL_PATH := $(call my-dir)

ADRENO_TOP_SYMLINKS := libEGL_adreno.so libGLESv2_adreno.so libq3dtools_adreno.so

$(foreach f,$(ADRENO_TOP_SYMLINKS),\
  $(eval $(TARGET_OUT_VENDOR)/lib64/$(f): $(TARGET_OUT_VENDOR)/lib64/egl/$(f))\
  $(eval $(TARGET_OUT_VENDOR)/lib64/$(f): ; $$(hide) rm -f $$@ && ln -sf /vendor/lib64/egl/$(f) $$@)\
  $(eval ALL_DEFAULT_INSTALLED_MODULES += $(TARGET_OUT_VENDOR)/lib64/$(f)))