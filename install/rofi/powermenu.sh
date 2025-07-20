#!/bin/bash
# Interactive power menu using rofi

# Options
shutdown="⏻ Shutdown"
reboot="⟲ Reboot"
logout="⇠ Logout"
lock="🔒 Lock"
suspend="⏸ Suspend"
cancel="✘ Cancel"

# Show options
chosen=$(echo -e "$shutdown\n$reboot\n$logout\n$lock\n$suspend\n$cancel" | rofi -dmenu -i -p "Power Menu" -theme-str 'window {width: 300px;}' -theme-str 'listview {lines: 6;}')

# Execute based on choice
case $chosen in
    "$shutdown")
        systemctl poweroff
        ;;
    "$reboot")
        systemctl reboot
        ;;
    "$logout")
        qtile cmd-obj -o cmd -f shutdown
        ;;
    "$lock")
        cinnamon-screensaver-command --lock
        ;;
    "$suspend")
        systemctl suspend
        ;;
    "$cancel")
        exit 0
        ;;
    *)
        exit 0
        ;;
esac