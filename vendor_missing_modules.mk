# Modules that produce the vendor files this product is missing.
#
# The list comes from Soong's install map, filtered by filter_missing_modules.py against
# out/soong/module-info-lineage_froggerPro.json. The filter matters: artifact filenames are not module names,
# and a single non-existent entry aborts the whole build in main.mk:1074.
#
# Two corrections from the feature investigations are folded in:
#
#   * fingerprint.default is NOT listed. Soong builds AOSP's demo stub for it - the module's own description
#     reads "Demo Fingerprint HAL" and every operation returns FINGERPRINT_ERROR - and it installs exactly where
#     the real Goodix implementation belongs, vendor/lib64/hw/fingerprint.default.so. The blob tree carries the
#     Goodix build and proprietary-files.txt lists it, but the generated FroggerPro-vendor.mk has no copy rule
#     for it, so the stub was what shipped. The blob is restored through missing_vendor_blobs.mk instead.
#
#   * The protobuf pair the camera HAL's DT_NEEDED resolve against appears as -vendorcompat:
#     libprotobuf-cpp-full-21.12-vendorcompat and libprotobuf-cpp-lite-21.12-vendorcompat are the vendor: true
#     builds. The bare lite name is system_ext_specific and lands in /system_ext/lib64, which a vendor process
#     cannot see. (An earlier comment here claimed those artifacts are built by libprotobuf-cpp-full; this tree
#     has no such module.)
#
# The Qualcomm audio graphservices family is deliberately absent. Its sources here are incomplete: liblx-osal
# fails to compile outright -
#   ar_osal_shmem_db.c:23:10: fatal error: 'linux/msm_audio.h' file not found
# because the kernel UAPI headers its module declares (audio_kernel_headers, qti_audio_kernel_uapi) are not
# produced by this tree's generator. Its siblings (libar-gsl, libar-gpr, liblx-ar_util, libar-acdb, libats) and
# everything layered on them (libagm*, libpal*, the audio effect and codec2 wrappers) link against it, so the
# whole family is left out rather than half-built. Those artifacts ship as the vendor's own binaries.
#
# Interface libraries appear twice, once plain and once as <name>.vendor. They are vendor_available, so Soong
# builds both variants; naming only the plain module installs the core variant into system/lib64, where a vendor
# HAL cannot see it, because the vendor linker namespace does not include /system/lib64. Vendor variants are only
# listed for names Soong actually has - an unknown name aborts the build.

#
# Each interface library also appears as <name>.vendor. These modules are vendor_available, so Soong builds
# a vendor variant; naming only the plain module installs the core variant into system/lib64, where a vendor
# HAL cannot see it, because the vendor linker namespace does not include /system/lib64. The reference vendor
# carries them in vendor/lib64. Vendor variants are only listed for names Soong actually has, because an
# unknown name aborts the build in main.mk.
PRODUCT_PACKAGES += \
    android.frameworks.cameraservice.common-V1-ndk \
    android.frameworks.cameraservice.common-V1-ndk.vendor \
    android.frameworks.cameraservice.device-V2-ndk \
    android.frameworks.cameraservice.device-V2-ndk.vendor \
    android.frameworks.cameraservice.service-V2-ndk \
    android.frameworks.cameraservice.service-V2-ndk.vendor \
    android.frameworks.location.altitude-V2-ndk \
    android.frameworks.location.altitude-V2-ndk.vendor \
    android.frameworks.sensorservice-V1-ndk \
    android.frameworks.sensorservice-V1-ndk.vendor \
    android.hardware.authsecret-V1-ndk \
    android.hardware.authsecret-V1-ndk.vendor \
    android.hardware.biometrics.common-V3-ndk \
    android.hardware.biometrics.common-V3-ndk.vendor \
    android.hardware.biometrics.fingerprint-V3-ndk \
    android.hardware.biometrics.fingerprint-V3-ndk.vendor \
    android.hardware.bluetooth-V1-ndk \
    android.hardware.bluetooth-V1-ndk.vendor \
    android.hardware.bluetooth.finder-V1-ndk \
    android.hardware.bluetooth.finder-V1-ndk.vendor \
    android.hardware.bluetooth.lmp_event-V1-ndk \
    android.hardware.bluetooth.lmp_event-V1-ndk.vendor \
    android.hardware.bluetooth.ranging-V1-ndk \
    android.hardware.bluetooth.ranging-V1-ndk.vendor \
    android.hardware.camera.common-V1-ndk \
    android.hardware.camera.common-V1-ndk.vendor \
    android.hardware.camera.device-V2-ndk \
    android.hardware.camera.device-V2-ndk.vendor \
    android.hardware.camera.metadata-V2-ndk \
    android.hardware.camera.metadata-V2-ndk.vendor \
    android.hardware.camera.provider-V2-ndk \
    android.hardware.camera.provider-V2-ndk.vendor \
    android.hardware.gatekeeper-V1-ndk \
    android.hardware.gatekeeper-V1-ndk.vendor \
    android.hardware.gnss-V4-ndk \
    android.hardware.gnss-V4-ndk.vendor \
    android.hardware.health-V1-ndk \
    android.hardware.health-V1-ndk.vendor \
    android.hardware.identity-V5-ndk \
    android.hardware.identity-V5-ndk.vendor \
    android.hardware.keymaster-V3-ndk \
    android.hardware.keymaster-V3-ndk.vendor \
    android.hardware.keymaster-V4-ndk \
    android.hardware.keymaster-V4-ndk.vendor \
    android.hardware.media.bufferpool2-V2-ndk \
    android.hardware.media.bufferpool2-V2-ndk.vendor \
    android.hardware.media.c2-V1-ndk \
    android.hardware.media.c2-V1-ndk.vendor \
    android.hardware.radio-V3-ndk \
    android.hardware.radio-V3-ndk.vendor \
    android.hardware.radio.config-V3-ndk \
    android.hardware.radio.config-V3-ndk.vendor \
    android.hardware.radio.data-V3-ndk \
    android.hardware.radio.data-V3-ndk.vendor \
    android.hardware.radio.messaging-V3-ndk \
    android.hardware.radio.messaging-V3-ndk.vendor \
    android.hardware.radio.modem-V3-ndk \
    android.hardware.radio.modem-V3-ndk.vendor \
    android.hardware.radio.network-V3-ndk \
    android.hardware.radio.network-V3-ndk.vendor \
    android.hardware.radio.sap-V1-ndk \
    android.hardware.radio.sap-V1-ndk.vendor \
    android.hardware.radio.sim-V3-ndk \
    android.hardware.radio.sim-V3-ndk.vendor \
    android.hardware.radio.voice-V3-ndk \
    android.hardware.radio.voice-V3-ndk.vendor \
    android.hardware.secure_element-V1-ndk \
    android.hardware.secure_element-V1-ndk.vendor \
    android.hardware.security.keymint-V2-ndk \
    android.hardware.security.keymint-V2-ndk.vendor \
    android.hardware.security.keymint-V3-ndk \
    android.hardware.security.keymint-V3-ndk.vendor \
    android.hardware.security.keymint-V4-ndk \
    android.hardware.security.keymint-V4-ndk.vendor \
    android.hardware.security.rkp-V3-ndk \
    android.hardware.security.rkp-V3-ndk.vendor \
    android.hardware.security.sharedsecret-V1-ndk \
    android.hardware.security.sharedsecret-V1-ndk.vendor \
    android.hardware.weaver-V2-ndk \
    android.hardware.weaver-V2-ndk.vendor \
    android.hardware.wifi.common-V1-ndk \
    android.hardware.wifi.common-V1-ndk.vendor \
    android.hardware.wifi.hostapd-V2-ndk \
    android.hardware.wifi.hostapd-V2-ndk.vendor \
    android.hardware.wifi.supplicant-V3-ndk \
    android.hardware.wifi.supplicant-V3-ndk.vendor \
    android.se.omapi-V1-ndk \
    android.se.omapi-V1-ndk.vendor \
    android.system.net.netd-V1-ndk \
    android.system.net.netd-V1-ndk.vendor \
    audio.usb.default \
    audioadsprpcd \
    audioeffectservice_qti.xml \
    audiohalservice.qti \
    libPeripheralStateUtils \
    lib_android_keymaster_keymint_utils \
    lib_android_keymaster_keymint_utils.vendor \
    lib_bt_aptx \
    lib_bt_ble \
    lib_bt_bundle \
    libalsautils \
    libalsautils.vendor \
    libandroid_runtime_lazy \
    libandroid_runtime_lazy.vendor \
    libaudioroute \
    libaudioroute.vendor \
    libaudioserviceexampleimpl \
    libavservices_minijail \
    libavservices_minijail.vendor \
    libbatterylistener \
    libcamera_metadata \
    libcamera_metadata.vendor \
    libcap \
    libcap.vendor \
    libcodec2 \
    libcodec2.vendor \
    libcodec2_aidl \
    libcodec2_aidl.vendor \
    libcodec2_hal_common \
    libcodec2_hal_common.vendor \
    libcodec2_hidl_plugin \
    libcodec2_vndk \
    libcodec2_vndk.vendor \
    libcppbor \
    libcppbor.vendor \
    libcppbor_external \
    libcppbor_external.vendor \
    libcppcose_rkp \
    libcppcose_rkp.vendor \
    libcurl \
    libcurl.vendor \
    libexif \
    libexif.vendor \
    libexpat \
    libexpat.vendor \
    libgatekeeper \
    libgatekeeper.vendor \
    libhidltransport \
    libhidltransport.vendor \
    libhwbinder \
    libhwbinder.vendor \
    libjpeg \
    libjpeg.vendor \
    libjson \
    libkeymaster_messages \
    libkeymaster_messages.vendor \
    libkeymaster_portable \
    libkeymaster_portable.vendor \
    libminijail \
    libminijail.vendor \
    libprotobuf-cpp-full-21.12-vendorcompat \
    libprotobuf-cpp-lite-21.12-vendorcompat \
    libqdutils \
    libqti_vndfwk_detect \
    libqti_vndfwk_detect.vendor \
    libqti_vndfwk_detect_vendor \
    librmnetctl \
    libsensorndkbridge \
    libsfplugin_ccodec_utils \
    libsfplugin_ccodec_utils.vendor \
    libsoft_attestation_cert \
    libsoft_attestation_cert.vendor \
    libsqlite \
    libsqlite.vendor \
    libstagefright_aidl_bufferpool2 \
    libstagefright_aidl_bufferpool2.vendor \
    libtinyalsa \
    libtinyalsa.vendor \
    libtinycompress \
    libtinyxml2-v34 \
    libwpa_client \
    manifest_audiocorehal_default.xml \
    mapper.qti \
    vendor.qti.hardware.agm-V1-ndk \
    vendor.qti.hardware.bluetooth.audio-V1-ndk \
    vendor.qti.hardware.bluetooth.audio-V1-ndk.vendor \
    vendor.qti.hardware.camera.aon-V2-ndk \
    vendor.qti.hardware.camera.aon-V2-ndk.vendor \
    vendor.qti.hardware.camera.offlinecamera-V2-ndk \
    vendor.qti.hardware.camera.offlinecamera-V2-ndk.vendor \
    vendor.qti.hardware.display.color-V1-ndk \
    vendor.qti.hardware.display.color-V1-ndk.vendor \
    vendor.qti.hardware.display.config-V5-ndk \
    vendor.qti.hardware.display.config-V5-ndk.vendor \
    vendor.qti.hardware.display.config-V7-ndk \
    vendor.qti.hardware.display.config-V7-ndk.vendor \
    vendor.qti.hardware.display.postproc-V1-ndk \
    vendor.qti.hardware.display.postproc-V1-ndk.vendor \
    vendor.qti.hardware.pal-V1-ndk \
    vendor.qti.hardware.paleventnotifier-V2-ndk \
    vendor.qti.hardware.paleventnotifier-V2-ndk.vendor \
    wifi_legacy \
    wifi_legacy.vendor \
    android.frameworks.sensorservice@1.0 \
    android.hardware.bluetooth@1.0 \
    android.hardware.health@1.0 \
    android.hardware.health@2.0 \
    android.hardware.health@2.1 \
    android.hardware.keymaster@3.0 \
    android.hardware.keymaster@4.0 \
    android.hardware.keymaster@4.1 \
    android.hardware.secure_element@1.0 \
    android.hardware.secure_element@1.1 \
    android.hardware.secure_element@1.2 \
    vendor.qti.hardware.bluetooth_audio@2.0 \
    vendor.qti.hardware.bluetooth_audio@2.1 \
    vendor.qti.hardware.display.mapper@2.0



# GPU driver APK from the phone's own vendor tree. AOSP forbids shipping an APK through PRODUCT_COPY_FILES
# (build/make/core/Makefile:148), and vendor/nothing/FroggerPro/app/Android.mk already declares it as a
# presigned vendor prebuilt, so it is installed as a package instead. The vendor's generated makefile lists
# only CneApp, which is why this file was absent from the image.
PRODUCT_PACKAGES += \
    com.qualcomm.qti.gpudrivers.sun.api35

# Carrier module for the vendor variants of the HIDL interface libraries the vendor blobs load; see
# device/nothing/froggerPro/hidl_vendor_deps/Android.bp for why a dependency edge is the only mechanism
# that gets those variants built and installed.
PRODUCT_PACKAGES += \
    froggerPro_hidl_vendor_deps

# Vendor apps the blob tree already declares as presigned prebuilt modules (app/Android.mk) but the
# generated vendor makefile omits - without naming them here they are never installed.
PRODUCT_PACKAGES += \
    CACertService \
    ConnectionSecurityService
#   3 個 iwlan native 庫保留 ✓ 那才是 BUG-004 的真修補 ✓）

    TimeService \
    TrustZoneAccessService \
    TxPwrAdmin
