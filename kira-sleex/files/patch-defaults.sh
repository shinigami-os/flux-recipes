#!/bin/sh
# Kira-only defaults, run from kira-sleex's %pre-build (kept in files/ for the
# same 4096-byte hook buffer reason as patch-palette.sh).
set -e
src="$1/src"
skel="$1/sleex-user-config/src/.config"

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

# Kira doesn't ship fish - without a shell= line foot runs the user's login shell
sed -i '/^shell=fish$/d' "$skel/foot/foot.ini"

# matugen writes its templates in random order, and colors.json is the one the
# shell watches live, so it has to go first
grep -q '^index = -10$' "$skel/matugen/config.toml" \
    || sed -i "\#^output_path = '~/.local/state/sleex/user/generated/colors.json'\$#a index = -10" "$skel/matugen/config.toml"
grep -q '^index = -10$' "$skel/matugen/config.toml"

# papirus-sync.py shells out to papirus-folders, which Alpine doesn't package
sed -i '/^\[templates\.papirus\]$/,/^post_hook/d' "$skel/matugen/config.toml"

# the watermark and About page show whatever version the package manager reports, which on
# Kira is this recipe's own version - show upstream's PKGBUILD release instead
pkgver=$(sed -n 's/^pkgver="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' "$1/PKGBUILD")
pkgrel=$(sed -n 's/^pkgrel="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' "$1/PKGBUILD")
[ -n "$pkgver" ] && [ -n "$pkgrel" ]
echo "$pkgver-$pkgrel" > "$src/share/sleex/version"
sed -i "s#flux list -a 2>/dev/null | grep -E '^(kira-)?sleex(-git)? '#echo sleex \$(cat /usr/share/sleex/version)#" \
    "$src/share/sleex/services/SystemInfo.qml"
grep -q 'cat /usr/share/sleex/version' "$src/share/sleex/services/SystemInfo.qml"
