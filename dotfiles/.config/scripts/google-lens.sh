#!/usr/bin/env bash
# Google Lens - Capture screen region, open Lens, paste image automatically
# Usage: google-lens.sh

NOTIFY="$HOME/.config/scripts/qs-notify"

GEOM=$(slurp -d -c '#81d5caAA' -b '#1a212080')
[[ -z "$GEOM" ]] && exit 0

grim -g "$GEOM" "/tmp/lens_capture.png"
wl-copy --type image/png < "/tmp/lens_capture.png"

zen-browser --new-window "https://lens.google.com" &

sleep 2

hyprctl dispatch focuswindow "class:^(zen)$" 2>/dev/null
sleep 0.5

wtype -M ctrl v -m ctrl 2>/dev/null || {
  $NOTIFY "Google Lens" "Press Ctrl+V to paste" "success"
  exit 0
}

$NOTIFY "Google Lens" "Searching..." "success"
