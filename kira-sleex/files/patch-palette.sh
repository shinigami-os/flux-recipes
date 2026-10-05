#!/bin/sh
# Kira-only fixes for Sleex's palette script, run from kira-sleex's %pre-build.
# Kept in files/ because the flux hook buffer is 4096 bytes and silently
# truncates anything past it.
set -e
colors="$1"

# the script's shebang re-activates a $SLEEX_VIRTUAL_ENV venv that only the
# upstream installer creates - Kira never does, so use the system python3,
# which has kira-materialyoucolor + py3-pillow
sed -i '1s|^.*$|#!/usr/bin/env python3|' "$colors/generate_colors_material.py"

# matugen refuses to pick a source color from a wallpaper with several strong
# competing colors unless told how to choose, and with no terminal attached it
# errors out instead of asking - so colors.json never regenerates on a wallpaper
# change. the fix lives on the fork's matugen-fix branch, which Kira doesn't track
# yet, so it's applied here until that reaches upstream main
if ! grep -q 'prefer saturation' "$colors/switchwall.sh"; then
    sed -i -e '/type_flag" \]\] && matugen_args+=/a\    matugen_args+=(--prefer saturation)' "$colors/switchwall.sh"
fi
grep -q 'prefer saturation' "$colors/switchwall.sh"
