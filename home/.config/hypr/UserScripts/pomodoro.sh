#!/bin/bash

STATE_FILE="/tmp/pomodoro_state"
WORK_DURATION=25  # minutes
BREAK_DURATION=5  # minutes

while true; do
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "idle" > "$STATE_FILE"
    fi

    STATE=$(cat "$STATE_FILE")

    case "$STATE" in
        idle)
            echo '{"text": "🍅 Start", "tooltip": "Click to start Pomodoro"}'
            ;;
        work)
            END=$(cat "$STATE_FILE.end")
            NOW=$(date +%s)
            LEFT=$((END - NOW))

            if [[ $LEFT -le 0 ]]; then
                notify-send "Pomodoro" "Work session complete! Take a break."
                echo "break" > "$STATE_FILE"
                echo $(( $(date +%s) + (BREAK_DURATION * 60) )) > "$STATE_FILE.end"
            else
                MIN=$((LEFT / 60))
                SEC=$((LEFT % 60))
                echo "{\"text\": \"🍅 $MIN:$SEC\", \"tooltip\": \"Focus time remaining\"}"
            fi
            ;;
        break)
            END=$(cat "$STATE_FILE.end")
            NOW=$(date +%s)
            LEFT=$((END - NOW))

            if [[ $LEFT -le 0 ]]; then
                notify-send "Pomodoro" "Break over! Time to focus."
                echo "idle" > "$STATE_FILE"
            else
                MIN=$((LEFT / 60))
                SEC=$((LEFT % 60))
                echo "{\"text\": \"☕ $MIN:$SEC\", \"tooltip\": \"Break time remaining\"}"
            fi
            ;;
    esac

    sleep 1
done

