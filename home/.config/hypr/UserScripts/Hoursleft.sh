#!/bin/bash

# Target date and time (format: YYYY-MM-DD HH:MM:SS)
TARGET="2071-01-01 00:00:00"

# Current date and time
NOW=$(date +"%Y-%m-%d %H:%M:%S")

# Calculate the difference in seconds
SECONDS_LEFT=$(( $(date -d "$TARGET" +%s) - $(date -d "$NOW" +%s) ))

# Convert seconds to hours
if [ $SECONDS_LEFT -gt 0 ]; then
    HOURS_LEFT=$((SECONDS_LEFT / 3600))

    # Format the number with commas
    FORMATTED_HOURS=$(printf "%'d" $HOURS_LEFT)

    echo "{\"text\": \"$FORMATTED_HOURS\" , \"tooltip\": \"Countdown to $TARGET\"}"
else
    echo "{\"text\": \"Event passed\", \"tooltip\": \"Target date: $TARGET\"}"
fi

