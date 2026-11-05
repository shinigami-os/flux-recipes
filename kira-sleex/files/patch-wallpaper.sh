#!/bin/sh
# Kira-only wallpaper default, run from kira-sleex's %pre-build (kept in files/
# for the same 4096-byte hook buffer reason as patch-palette.sh).
set -e
share="$1"

# the Kira wallpaper ships from kira-branding - upstream keeps renaming its own
# default file (SleexOne.png, then twentySix.jpg), which left the background blank
sed -i 's#/usr/share/backgrounds/sleex/twentySix\.jpg#/usr/share/kira/wallpapers/default.png#; s#/usr/share/backgrounds/sleex#/usr/share/kira/wallpapers#' \
    "$share/modules/common/Config.qml" \
    "$share/modules/common/Directories.qml" \
    "$share/services/FirstRunExperience.qml"
! grep -rq 'backgrounds/sleex' "$share/modules" "$share/services"
