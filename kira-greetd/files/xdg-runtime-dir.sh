#!/bin/sh
# pam_exec session hook, run by greetd's own PAM stack while it's still root
# (before the setuid drop to the target user). elogind's pam_elogind.so is
# supposed to create /run/user/$UID itself on session open, and does for a
# normal getty/login PAM stack, but not reliably when greetd is the one
# opening the session - leaving desktop session launchers (kira-start-sleex
# etc) unable to create it themselves, since /run/user is root-owned 0755
# and a plain user has no write permission there.
[ "$PAM_TYPE" = "open_session" ] || exit 0

uid=$(id -u "$PAM_USER" 2>/dev/null) || exit 0
gid=$(id -g "$PAM_USER" 2>/dev/null) || exit 0

dir="/run/user/$uid"
mkdir -p "$dir"
chown "$uid:$gid" "$dir"
chmod 0700 "$dir"
