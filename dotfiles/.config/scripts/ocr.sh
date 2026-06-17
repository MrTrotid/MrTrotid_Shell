#!/usr/bin/env bash
# OCR - Capture screen region and extract text via tesseract
# Usage: ocr.sh
# Copies extracted text to clipboard and shows notification

NOTIFY="$HOME/.config/scripts/qs-notify"

GEOM=$(slurp -d -c '#81d5caAA' -b '#1a212080')
[[ -z "$GEOM" ]] && exit 0

TEXT=$(grim -g "$GEOM" - | tesseract stdin stdout 2>/dev/null | sed '/^[[:space:]]*$/d')

if [ -z "$TEXT" ]; then
    $NOTIFY "OCR" "No text detected" "error"
    exit 1
fi

echo "$TEXT" | wl-copy

PREVIEW=$(echo "$TEXT" | head -5 | cut -c1-80)
COUNT=$(echo "$TEXT" | wc -l)
[ "$COUNT" -gt 5 ] && PREVIEW="$PREVIEW\n... ($COUNT lines total)"

$NOTIFY "OCR" "$PREVIEW" "success"
