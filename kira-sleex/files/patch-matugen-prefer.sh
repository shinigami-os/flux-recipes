#!/bin/sh
set -e
f="$1"
grep -q 'prefer saturation' "$f" && exit 0
sed -i -e '/type_flag" \]\] && matugen_args+=/a\    matugen_args+=(--prefer saturation)' "$f"
grep -q 'prefer saturation' "$f"
