#!/bin/bash
# Interactive brightness menu using rofi

# Screen brightness options
screen_10="☀ Screen 10%"
screen_25="☀ Screen 25%"
screen_50="☀ Screen 50%"
screen_75="☀ Screen 75%"
screen_100="☀ Screen 100%"

# Keyboard brightness options
kbd_0="⌨ Keyboard Off"
kbd_1="⌨ Keyboard Low"
kbd_2="⌨ Keyboard Medium"
kbd_3="⌨ Keyboard High"

cancel="✘ Cancel"

# Show options
chosen=$(echo -e "$screen_10\n$screen_25\n$screen_50\n$screen_75\n$screen_100\n$kbd_0\n$kbd_1\n$kbd_2\n$kbd_3\n$cancel" | rofi -dmenu -i -p "Brightness" -theme-str 'window {width: 300px;}' -theme-str 'listview {lines: 10;}')

# Execute based on choice
case $chosen in
    "$screen_10")
        brightnessctl set 10%
        ;;
    "$screen_25")
        brightnessctl set 25%
        ;;
    "$screen_50")
        brightnessctl set 50%
        ;;
    "$screen_75")
        brightnessctl set 75%
        ;;
    "$screen_100")
        brightnessctl set 100%
        ;;
    "$kbd_0")
        brightnessctl -d 'asus::kbd_backlight' set 0
        ;;
    "$kbd_1")
        brightnessctl -d 'asus::kbd_backlight' set 1
        ;;
    "$kbd_2")
        brightnessctl -d 'asus::kbd_backlight' set 2
        ;;
    "$kbd_3")
        brightnessctl -d 'asus::kbd_backlight' set 3
        ;;
    "$cancel")
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
