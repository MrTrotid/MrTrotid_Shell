#!/usr/bin/env bash
# Screenshot helper for Hyprland (grim + slurp)
# Usage: screenshot.sh [mode]
# Modes: full, region, window, timer, monitor, copy

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/Screenshot_$(date +%Y-%m-%d_%H.%M.%S).png"
NOTIFY="$HOME/.config/scripts/qs-notify"

case "${1:-full}" in
    full)
        grim "$FILE" && wl-copy --type image/png < "$FILE"
        $NOTIFY "Screenshot" "Full screen saved" "screenshot"
        ;;
    region)
        GEOM=$(slurp -d -c '#81d5caAA' -b '#1a212080')
        [[ -z "$GEOM" ]] && exit 0
        grim -g "$GEOM" "$FILE" && wl-copy --type image/png < "$FILE"
        $NOTIFY "Screenshot" "Region saved" "screenshot"
        ;;
    window)
        GEOM=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        grim -g "$GEOM" "$FILE" && wl-copy --type image/png < "$FILE"
        $NOTIFY "Screenshot" "Window saved" "screenshot"
        ;;
    timer)
        $NOTIFY "Screenshot" "Taking screenshot in 5s..." "screenshot"
        sleep 5
        grim "$FILE" && wl-copy --type image/png < "$FILE"
        $NOTIFY "Screenshot" "Timer screenshot saved" "screenshot"
        ;;
    monitor)
        MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
        grim -o "$MONITOR" "$FILE" && wl-copy --type image/png < "$FILE"
        $NOTIFY "Screenshot" "Monitor saved" "screenshot"
        ;;
    copy)
        GEOM=$(slurp -d -c '#81d5caAA' -b '#1a212080')
        [[ -z "$GEOM" ]] && exit 0
        grim -g "$GEOM" - | wl-copy --type image/png
        $NOTIFY "Screenshot" "Copied to clipboard" "screenshot"
        ;;
    *)
        echo "Usage: $0 {full|region|window|timer|monitor|copy}"
        exit 1
        ;;
esac
