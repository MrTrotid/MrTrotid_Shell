#!/usr/bin/env bash
# Reload Quickshell — run after each migration step to test
pkill -x qs 2>/dev/null
sleep 0.3
qs --config "$HOME/Desktop/Trotid_Shell/quickshell/shell.qml" &
disown
