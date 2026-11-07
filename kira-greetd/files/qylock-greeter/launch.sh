#!/bin/sh
dir=/usr/share/kira-qylock
theme=$(head -n1 /etc/greetd/qylock-theme 2>/dev/null)

export QS_THEME_PATH="$dir/themes/${theme:-clockwork/orbital}"
export QML_IMPORT_PATH="$dir/imports"
export QML2_IMPORT_PATH="$dir/imports"
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QSG_RENDER_LOOP=basic
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/greetd}"
export XDG_CACHE_HOME=/run/greetd/cache
export XDG_STATE_HOME=/run/greetd/state
mkdir -p "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

exec qs -p /etc/greetd/qylock-greeter
