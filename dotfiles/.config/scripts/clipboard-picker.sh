#!/usr/bin/env bash
# Clipboard history picker with image previews using rofi -preview-cmd

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY="$HOME/.config/scripts/qs-notify"

selected=$(cliphist list | rofi -dmenu \
    -theme ~/.config/rofi/launchers/type-1/style-1.rasi \
    -p "Clipboard" \
    -hover-select \
    -me-select-entry "" \
    -me-accept-entry "MousePrimary" \
    -preview-cmd "$SCRIPT_DIR/clipboard-preview.sh" 2>/dev/null)

if [[ -n "$selected" ]]; then
    id=$(echo "$selected" | cut -f1)
    cliphist decode "$id" | wl-copy
    $NOTIFY "Clipboard" "Copied to clipboard" "clipboard"
fi
