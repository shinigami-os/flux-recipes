#!/bin/sh
# same loginctl commands wlogout already uses on the desktop side, so power
# actions behave identically whether triggered before or after login
case "$1" in
    shutdown) loginctl poweroff ;;
    reboot)   loginctl reboot ;;
    suspend)  loginctl suspend ;;
esac
