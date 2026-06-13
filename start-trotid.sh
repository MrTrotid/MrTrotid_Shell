#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec Hyprland -c "$DIR/dotfiles/.config/hypr/hyprland.conf"
