#!/usr/bin/env bash
# Reload Quickshell — run after each migration step to test
pkill -x qs 2>/dev/null
sleep 0.3
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
qs --config "$DIR/dotfiles/.config/quickshell/shell.qml" &
disown
