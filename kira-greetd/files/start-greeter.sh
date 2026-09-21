#!/bin/sh
# greetd's actual session command (see config.toml). Sets up the keyboard
# layout before exec'ing cage - cage is the Wayland compositor here, so it's
# the one that resolves physical keycodes to keysyms, and it does that once
# at its own startup. Setting XKB_DEFAULT_LAYOUT inside cage's *client*
# (launch-kira-login.sh) is too late, the decision has already been made by
# the time the client even starts.
export XDG_RUNTIME_DIR=/run/greetd

# derive layout/variant from the same keymap file the console uses
# (/etc/keymaps/<layout>-<variant>.bmap) instead of hardcoding a value here -
# there's exactly one file there today, but this follows whatever it's
# actually set to rather than guessing
keymap_file=$(ls /etc/keymaps/*.bmap 2>/dev/null | head -n1)
if [ -n "$keymap_file" ]; then
    keymap_name=$(basename "$keymap_file" .bmap)
    export XKB_DEFAULT_LAYOUT="${keymap_name%%-*}"
    variant="${keymap_name#*-}"
    [ "$variant" != "$keymap_name" ] && export XKB_DEFAULT_VARIANT="$variant"
fi

cage -s -- /etc/greetd/kira-login/launch-kira-login.sh &
cage_pid=$!

# cage's own shutdown just stops its Wayland event loop and then blocks
# indefinitely waiting for its client to notice the dead socket and exit on
# its own (cleanup_primary_client() in cage.c never actually kills it) -
# that's what made every login handoff take 5-6 seconds, not anything in
# our own scripts. Kill the client ourselves the moment greetd asks this
# session to end, instead of waiting on cage to notice.
cleanup() {
    echo "$(date +%s.%N) start-greeter.sh got TERM, killing client directly" >> /tmp/kira-login-timing.log
    pkill -TERM -f launch-kira-login.sh 2>/dev/null
    pkill -TERM -x eww 2>/dev/null
    kill -TERM "$cage_pid" 2>/dev/null
}
trap cleanup TERM INT

wait "$cage_pid"
