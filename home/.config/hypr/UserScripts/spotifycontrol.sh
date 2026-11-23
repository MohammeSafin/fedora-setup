#!/bin/bash

case "$1" in
  volume-up)
    current_volume=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
      /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get \
      string:"org.mpris.MediaPlayer2.Player" string:"Volume" | grep variant | awk '{print $3}')

    new_volume=$(echo "$current_volume + 0.1" | bc)

    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
      /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Set \
      string:"org.mpris.MediaPlayer2.Player" string:"Volume" \
      variant:double:$new_volume
    ;;
  volume-down)
    current_volume=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
      /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get \
      string:"org.mpris.MediaPlayer2.Player" string:"Volume" | grep variant | awk '{print $3}')

    new_volume=$(echo "$current_volume - 0.1" | bc)

    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
      /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Set \
      string:"org.mpris.MediaPlayer2.Player" string:"Volume" \
      variant:double:$new_volume
    ;;
  play-pause)
    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
      /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
    ;;
  next)
    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
      /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next
    ;;
  previous)
    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
      /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous
    ;;
esac

