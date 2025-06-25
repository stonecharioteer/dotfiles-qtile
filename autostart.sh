#!/bin/bash

# only run once
pgrep -x picom > /dev/null || picom --config ~/.config/picom.conf &
pgrep -x nm-applet > /dev/null || nm-applet &
pgrep -x pasystray > /dev/null || pasystray &
pgrep -x dunst > /dev/null || dunst &
# keyboard customizations, only for the laptop
# TODO: Figure out how to customize laptop keyboard specifically
# xmodmap ~/.Xmodmap
setxkbmap -option caps:escape -option shift:both_capslock
# select the default monitor setup
# TODO: Select appropriate monitor setup
autorandr -c
# restore wallpaper
nitrogen --restore &

# start other background services
xset r rate 200 35 &
xset s off -dpms &

notify-send "Qtile" "Config loaded successfully." -u low 2>/dev/null

