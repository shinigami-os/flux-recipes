#!/usr/bin/zsh
export HOME=/root
export USER=root
export LOGNAME=root

if [ "$(tty)" = "/dev/tty1" ]; then
    _active=$(cat "$HOME/.config/kira-desktop/active-de" 2>/dev/null)
    _launcher="/usr/bin/kira-start-${_active}"
    if [ -x "$_launcher" ]; then
        # Wait for seatd
        i=0
        while [ ! -S /run/seatd.sock ] && [ $i -lt 30 ]; do
            sleep 1
            i=$((i + 1))
        done
        exec "$_launcher"
    fi
fi

exec -a -zsh /usr/bin/zsh