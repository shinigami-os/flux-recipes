#!/bin/sh
set -e
f="$1"
echo "patch: before=$(grep -c 'prefer saturation' "$f") pwd=$(pwd) file=$f" >> /tmp/matugen-patch.log
grep -q 'prefer saturation' "$f" && exit 0
sed -i -e '/type_flag" \]\] && matugen_args+=/a\    matugen_args+=(--prefer saturation)' "$f"
grep -q 'prefer saturation' "$f"
echo "patch: after=$(grep -c 'prefer saturation' "$f")" >> /tmp/matugen-patch.log
