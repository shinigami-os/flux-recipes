#!/bin/sh
# acpid runs this as root with no session environment at all - hyprctl needs
# the real user's XDG_RUNTIME_DIR and HYPRLAND_INSTANCE_SIGNATURE to reach the
# running compositor's control socket. Same lowest-UID convention the
# greeter's own login script (greetd-auth.py) uses to find "the" user on
# Kira's single-real-account model.
user=$(awk -F: '$3 >= 1000 && $3 < 60000 { print $1; exit }' /etc/passwd)
[ -n "$user" ] || exit 0
uid=$(id -u "$user")
runtime_dir="/run/user/$uid"
sig=$(ls "$runtime_dir/hypr" 2>/dev/null | head -n1)
[ -n "$sig" ] || exit 0

# The Line: its own IPC. A global dispatched through hyprctl reaches the shell as
# a key release (Hyprland passes on the state of the last real key), which The
# Line's shortcut ignores. No The Line running: qs finds no instance, no-op.
chpst -u "$user:$user" env XDG_RUNTIME_DIR="$runtime_dir" \
    qs -p /usr/share/the-line ipc call line powerButton 2>/dev/null

# Sleex: "global" is Hyprland's own dispatcher for the hyprland-global-shortcuts-v1
# protocol, which is how quickshell registered this shortcut in the first place.
# Hyprland 0.55's Lua config only accepts dispatchers written as hl.dsp.* calls
chpst -u "$user:$user" env XDG_RUNTIME_DIR="$runtime_dir" HYPRLAND_INSTANCE_SIGNATURE="$sig" \
    hyprctl dispatch 'hl.dsp.global("quickshell:powerButtonPressed")'
