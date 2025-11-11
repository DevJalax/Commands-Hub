#!/bin/bash

# File to monitor for new OOM kills
LOG_FILE="/var/log/oom_monitor.log"
DMESG_CACHE="/tmp/last_dmesg_ts"

# Create a timestamp file if it doesn't exist
if [ ! -f "$DMESG_CACHE" ]; then
    echo 0 > "$DMESG_CACHE"
fi

# Get the last checked dmesg timestamp
LAST_TS=$(cat "$DMESG_CACHE")

# Get new OOM logs after that timestamp
dmesg | awk -v last_ts="$LAST_TS" '
    $0 ~ /Killed process/ {
        ts = gensub(/^\[([0-9\.]+)\].*/, "\\1", 1)
        if (ts > last_ts) {
            print ts " " $0
        }
    }
' | while read -r line; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $line" >> "$LOG_FILE"
    echo "⚠️  OOM Kill Detected: $line"
done

# Save the last timestamp for next check
LATEST=$(dmesg | awk '/Killed process/ {gsub(/\[|\]/, "", $1); ts=$1} END {print ts}')
echo "${LATEST:-$LAST_TS}" > "$DMESG_CACHE"
