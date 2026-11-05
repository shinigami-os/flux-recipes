#!/bin/sh
# Kira-only defaults, run from kira-sleex's %pre-build (kept in files/ for the
# same 4096-byte hook buffer reason as patch-palette.sh).
set -e
src="$1"

# the Kira wallpaper ships from kira-branding - upstream keeps renaming its own
# default file (SleexOne.png, then twentySix.jpg), which left the background blank
sed -i 's#/usr/share/backgrounds/sleex/twentySix\.jpg#/usr/share/kira/wallpapers/default.png#; s#/usr/share/backgrounds/sleex#/usr/share/kira/wallpapers#' \
    "$src/share/sleex/modules/common/Config.qml" \
    "$src/share/sleex/modules/common/Directories.qml" \
    "$src/share/sleex/services/FirstRunExperience.qml"
! grep -rq 'backgrounds/sleex' "$src/share/sleex/modules" "$src/share/sleex/services"

# BlueZ rejects every pairing with AuthenticationFailed unless an agent is
# registered, and neither Sleex nor Quickshell provides one
grep -q 'blueman-applet' "$src/etc/sleex/hyprland/execs.lua" \
    || sed -i '\#qs -p /usr/share/sleex#a\    hl.exec_cmd("blueman-applet")' "$src/etc/sleex/hyprland/execs.lua"
grep -q 'blueman-applet' "$src/etc/sleex/hyprland/execs.lua"
