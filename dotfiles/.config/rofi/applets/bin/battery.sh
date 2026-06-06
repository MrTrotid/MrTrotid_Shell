#!/usr/bin/env bash

## Author  : Aditya Shakya (adi1090x)
## Github  : @adi1090x
## Modified: powerprofilesctl variant

# Theme
theme="$HOME/.config/rofi/applets/type-3"
style='style-3.rasi'

# Theme Elements
prompt="Power Profile"
current=$(powerprofilesctl get)
mesg="Current: $current"

list_col='1'
list_row='3'
win_width='120px'

# Options
layout=$(cat ${theme}/${style} | grep 'USE_ICON' | cut -d'=' -f2)
if [[ "$layout" == 'NO' ]]; then
	option_1=" Performance"
	option_2=" Balanced"
	option_3=" Power Saving"
else
	option_1=""
	option_2=""
	option_3=""
fi

# Set active profile
active=""
urgent=""
case "$current" in
    "performance") urgent="-u 1" ;;
    "balanced") active="-a 1" ;;
    "power-saver") active="-a 2" ;;
esac

# Rofi CMD
rofi_cmd() {
	rofi -theme-str "window {width: $win_width;}" \
		-theme-str "listview {columns: $list_col; lines: $list_row;}" \
		-theme-str "textbox-prompt-colon {str: \"\";}" \
		-dmenu \
		-p "$prompt" \
		-mesg "$mesg" \
		${active} ${urgent} \
		-markup-rows \
		-theme ${theme}/${style}
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$option_1\n$option_2\n$option_3" | rofi_cmd
}

# Execute Command
run_cmd() {
	if [[ "$1" == '--opt1' ]]; then
		powerprofilesctl set performance
		notify-send "Power Profile" "Set to Performance"
	elif [[ "$1" == '--opt2' ]]; then
		powerprofilesctl set balanced
		notify-send "Power Profile" "Set to Balanced"
	elif [[ "$1" == '--opt3' ]]; then
		powerprofilesctl set power-saver
		notify-send "Power Profile" "Set to Power Saver"
	fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $option_1)
		run_cmd --opt1
        ;;
    $option_2)
		run_cmd --opt2
        ;;
    $option_3)
		run_cmd --opt3
        ;;
esac
