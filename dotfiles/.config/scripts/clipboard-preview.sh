#!/usr/bin/env bash
# Preview script for rofi clipboard picker
# Called by rofi with the selected entry as $1

THUMB_DIR="/tmp/cliphist_thumbs"
mkdir -p "$THUMB_DIR"

id=$(echo "$1" | cut -f1)
[[ -z "$id" ]] && exit 0

thumb="$THUMB_DIR/${id}.png"

# Only generate thumbnail for binary/image entries
if echo "$1" | grep -q "binary data"; then
    if [[ ! -f "$thumb" ]] || [[ ! -s "$thumb" ]]; then
        cliphist decode "$id" > "$thumb" 2>/dev/null
        if command -v magick &>/dev/null; then
            magick "$thumb" -resize 200x200 "$thumb" 2>/dev/null
        elif command -v convert &>/dev/null; then
            convert "$thumb" -resize 200x200 "$thumb" 2>/dev/null
        fi
    fi
    [[ -f "$thumb" ]] && [[ -s "$thumb" ]] && cat "$thumb"
fi
