// Stub source for froggerPro_hidl_vendor_deps. See Android.bp next to this file: the library exists only so that
// Soong builds and installs the vendor variants of the 14 HIDL interface libraries that prebuilt vendor blobs on
// this device load at runtime. No code in this file uses those interfaces, and nothing on the device loads this
// library - a shared library still needs at least one translation unit, so this is it.
//
// If the compiler ever warns that the shared_libs in Android.bp are unused, that is expected and is the whole
// point of the module; drop the -Werror in that file rather than removing a dependency.

namespace {
int froggerPro_hidl_vendor_deps_marker = 0;
}