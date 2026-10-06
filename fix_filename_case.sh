#!/bin/bash
# fix_filename_case.sh - 修正 FroggerPro 檔案名稱大小寫
# 在 device/nothing/froggerPro/ 目錄下執行
set -e

cd "$(dirname "$0")"

echo "========================================="
echo " 修正檔案名稱大小寫：froggerPro → froggerPro"
echo "========================================="
echo ""

# 1) 修正檔案名稱大小寫
echo "=== [1] 重新命名檔案（froggerPro → froggerPro）==="
find . -name '*froggerPro*' -not -path '*/.git/*' 2>/dev/null | while read f; do
    newname="$(dirname "$f")/$(basename "$f" | sed 's/froggerPro/froggerPro/g')"
    if [ "$f" != "$newname" ]; then
        mv -v "$f" "$newname"
    fi
done
echo ""

# 2) 修正檔案內容大小寫
echo "=== [2] 修正檔案內容（froggerPro → froggerPro）==="
find . -type f \( -name '*.mk' -o -name '*.bp' -o -name '*.rc' -o -name '*.sh' -o -name '*.prop' -o -name '*.xml' -o -name '*.conf' -o -name '*.config' -o -name '*.txt' -o -name 'AndroidProducts.mk' \) -not -path '*/.git/*' -exec grep -l 'froggerPro' {} \; 2>/dev/null | while read f; do
    echo "  修正: $f"
    sed -i 's/froggerPro/froggerPro/g' "$f"
done
echo ""

# 3) 驗證
echo "=== [3] 驗證 ==="
echo ""
echo "--- 仍含 froggerPro (全小寫) 的檔案名稱 ---"
FOUND=$(find . -name '*froggerPro*' -not -path '*/.git/*' 2>/dev/null)
if [ -z "$FOUND" ]; then
    echo "  ✅ 全部修正"
else
    echo "  ❌ $FOUND"
fi
echo ""
echo "--- 仍含 froggerPro (全小寫) 的檔案內容 ---"
FOUND=$(grep -rn 'froggerPro' --include='*' . 2>/dev/null | grep -v '.git/' | grep -v 'Binary' || true)
if [ -z "$FOUND" ]; then
    echo "  ✅ 全部修正"
else
    echo "  ❌ $FOUND"
fi
echo ""
echo "--- Android.bp 引用的 init 檔案 ---"
grep 'src:' init/Android.bp 2>/dev/null | awk '{print $2}' | tr -d '",' | while read f; do
    [ -f "init/$f" ] && echo "  ✅ $f" || echo "  ❌ $f (不存在)"
done
echo ""
echo "========================================="
echo " 完成！然後重新 build："
echo "========================================="
echo "  cd /mnt/data/lineageos"
echo "  source build/envsetup.sh"
echo "  lunch lineage_froggerPro bp4a userdebug"
echo "  m bacon"