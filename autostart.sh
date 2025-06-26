#!/bin/bash
export XCURSOR_THEME=Adwaita
export XCURSOR_SIZE=24
# only run once
pgrep -x picom >/dev/null || picom --config ~/.config/picom.conf &
pgrep -x nm-applet >/dev/null || nm-applet &
pgrep -x pasystray >/dev/null || pasystray &
pgrep -x dunst >/dev/null || dunst &
# keyboard customizations, only for the laptop
# TODO: Figure out how to customize laptop keyboard specifically
# xmodmap ~/.Xmodmap
setxkbmap -option caps:escape -option shift:both_capslock

# start other background services
xset r rate 200 35 &
xset s off -dpms &

notify-send "Qtile" "Config loaded successfully." -u low 2>/dev/null
