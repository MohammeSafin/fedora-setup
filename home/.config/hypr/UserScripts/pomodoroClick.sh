#!/bin/bash

STATE_FILE="/tmp/pomodoro_state"

case "$(cat $STATE_FILE 2>/dev/null)" in
    idle)
        echo "work" > "$STATE_FILE"
        echo $(( $(date +%s) + (25 * 60) )) > "$STATE_FILE.end"
        ;;
    work|break)
        echo "idle" > "$STATE_FILE"
        ;;
esac

