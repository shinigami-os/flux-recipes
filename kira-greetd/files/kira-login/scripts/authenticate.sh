#!/bin/sh
# fired by the password field's Enter key. Keeps the entered password off argv
# entirely (piped to python over stdin) - eww's own :onchange updates already
# put it briefly on an `eww update` command line each keystroke, so this is a
# minor extra precaution, not a hard guarantee.
dir="$(dirname "$0")"
attempt_file="/tmp/kira-login-attempts"

# every eww CLI call here needs --config: without it eww falls back to
# $XDG_CONFIG_HOME/eww (nonexistent for the greetd user) instead of the
# actual running daemon's config dir, and just fails to connect - silently,
# since nothing here captures its stderr
eww="eww --config /etc/greetd/kira-login"

$eww update auth_state=checking auth_msg=""

session=$($eww get selected_session)
# selected_session stays "" until the user actually clicks a dropdown row -
# the trigger label only *displays* the first session as a fallback via a
# yuck ternary, it never writes that fallback back into the variable, so
# without this an untouched dropdown silently authenticated into whatever
# sessions.sh happens to list last (the tty entry) instead of the session
# actually shown on screen
if [ -z "$session" ]; then
    session=$($eww get sessions_json | jq -r '.[0].name')
fi
pw=$($eww get pw)

if printf '%s\n' "$pw" | python3 "$dir/greetd-auth.py" "$session"; then
    rm -f "$attempt_file"
    exit 0
fi

attempt=$(( $(cat "$attempt_file" 2>/dev/null || echo 0) + 1 ))
echo "$attempt" > "$attempt_file"

case "$attempt" in
    1) msg="incorrect" ;;
    2) msg="still no" ;;
    *) msg="try again" ;;
esac

$eww update auth_state=error auth_msg="$msg" pw=""
sleep 1.3
$eww update auth_state=idle
