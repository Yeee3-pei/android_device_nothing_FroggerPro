# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Vendor content the filtered auto-generated makefile (FroggerPro-vendor.mk) dropped.
#
# Two families of files matter here:
#   lib64/*-V*-ndk.so   AIDL/HIDL interface libraries the vendor's own HALs link against.
#   etc/init/*.rc       Device-specific init scripts. Losing init.froggerpro.rc in particular makes the
#                       device hang on the boot logo with nothing on the USB bus, because the early
#                       device setup it performs never runs.
#
# The files live in the blob tree, so they only need copying into the image. Regenerate this file with
# temp/pm/gen_vendor_extra_mk.py after re-running temp/pm/vendor_missing_report.py.

PRODUCT_COPY_FILES += \
    vendor/nothing/froggerPro/etc/bpf/qmsUidStats.o:$(TARGET_COPY_OUT_VENDOR)/etc/bpf/qmsUidStats.o
