#!/bin/sh
# "friday, 12 september" - busybox date has no GNU %-e/%-d, so strip the
# leading zero by hand instead of relying on a non-portable format flag
day=$(date +%d | sed 's/^0//')
printf '%s, %s %s\n' "$(date +%A)" "$day" "$(date +%B)" | tr '[:upper:]' '[:lower:]'
