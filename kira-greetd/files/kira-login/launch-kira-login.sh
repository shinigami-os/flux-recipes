#!/bin/sh
# cage's client command (set from kira-greetd's config.toml). Starts the eww
# daemon against this config and opens the one login window, then blocks so
# cage has a process to supervise - if eww's own process exits, cage exits
# too and greetd retries the greeter.
dir="$(cd "$(dirname "$0")" && pwd)" || exit 1
cd "$dir" || exit 1

export GDK_BACKEND=wayland
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/greetd}"

# cage relies on its client exiting for it to exit too - without an explicit
# trap, this script (and the eww daemon it started) can outlive whatever
# signal cage sends on shutdown, which is what greetd is actually waiting on
# before the real session starts
trap 'echo "$(date +%s.%N) launch-kira-login.sh got TERM" >> /tmp/kira-login-timing.log; eww kill 2>/dev/null; exit 0' TERM INT

eww kill 2>/dev/null
sleep 0.3
# eww's default config lookup is $XDG_CONFIG_HOME/eww / ~/.config/eww, neither
# of which exists for the greetd system user - point it at this directory
# explicitly instead of relying on cwd discovery
eww --config "$dir" daemon >/dev/null 2>&1
sleep 0.5
eww --config "$dir" open login

# eww daemon backgrounds itself; wait on it so this script (cage's child)
# stays alive for the duration of the greeter session. exact-name match,
# not -f: the daemon's own argv (eww --config <dir> daemon) doesn't contain
# the literal substring "eww daemon"
pid=$(pgrep -x eww | head -n1)
if [ -n "$pid" ]; then
    while kill -0 "$pid" 2>/dev/null; do
        sleep 1
    done
else
    sleep infinity
fi
