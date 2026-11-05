#!/bin/sh
# enumerates installed wayland sessions for the login screen's session dropdown,
# rather than hardcoding sway/hyprland/tty like the design prototype does -
# whatever DE packages are actually installed on this build is what shows up
out="[]"

for f in /usr/share/wayland-sessions/*.desktop /usr/share/xsessions/*.desktop; do
    [ -f "$f" ] || continue
    # uwsm-wrapped entries (e.g. hyprland-uwsm.desktop) duplicate a compositor
    # that's already listed under its own plain entry, and uwsm isn't part of
    # how Kira actually launches sessions - skip them rather than showing two
    # confusingly similar rows for the same DE
    case "$f" in *uwsm*) continue ;; esac
    name=$(sed -n 's/^Name=//p' "$f" | head -n1)
    exec_line=$(sed -n 's/^Exec=//p' "$f" | head -n1 | sed 's/ %[a-zA-Z]//g')
    [ -n "$name" ] && [ -n "$exec_line" ] || continue
    # a real Kira session always launches through its own kira-start-* wrapper
    # (sets up XDG_CURRENT_DESKTOP, autostart, theming, etc). Anything else is
    # a raw compositor binary pulled in as some other package's dependency
    # (e.g. kira-hyprlock depends on hyprland itself, which ships its own
    # wayland-sessions entry even with no actual desktop session behind it)
    case "$exec_line" in *kira-start-*) ;; *) continue ;; esac
    cmd_json=$(printf '%s\n' "$exec_line" | jq -R 'split(" ") | map(select(length > 0))')
    out=$(printf '%s\n' "$out" | jq --arg name "$name" --argjson cmd "$cmd_json" \
        '. + [{"name":$name,"cmd":$cmd,"type":"wayland"}]')
done

# always-present fallback: a plain login shell on the VT, no compositor
out=$(printf '%s\n' "$out" | jq '. + [{"name":"tty","cmd":["__TTY__"],"type":"console"}]')

# eww.yuck's dropdown/trigger fall back to sessions_json[0] whenever the user
# hasn't clicked a row yet, so remembering the last successful login (written
# by greetd-auth.py) is just a matter of sorting that entry to the front -
# no eww-side state or extra var needed. sort_by is stable, so this only
# ever reorders around the remembered name and leaves everything else as-is
last=$(cat /var/lib/greetd/last-session 2>/dev/null || true)
if [ -n "$last" ]; then
    out=$(printf '%s\n' "$out" | jq --arg last "$last" 'sort_by(.name != $last)')
fi

# -c is required, not cosmetic: deflisten treats each line of stdout as one
# complete value, and jq's default pretty-printer spreads a single array
# across many lines, which eww then tries to parse line-by-line as JSON
# fragments ("Failed to turn `]` into a value of type json-value" etc.)
printf '%s\n' "$out" | jq -c .
