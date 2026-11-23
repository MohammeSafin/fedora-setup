#!/bin/bash

# Path to your GIF
GIF_PATH="$HOME/tenor.gif"

# Check if mpv is already running
if pgrep -x "mpv" > /dev/null; then
    # If mpv is running, kill it
    pkill -x mpv
    echo "MPV stopped"
else
    # Launch mpv with the GIF
    mpv --loop=inf --geometry=100x100+50+50 "$GIF_PATH" &
    echo "MPV started"
fi

