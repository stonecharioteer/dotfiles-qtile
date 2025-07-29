#!/bin/bash
export XCURSOR_THEME=Adwaita
export XCURSOR_SIZE=24
# only run once
pgrep -x picom >/dev/null || picom --config ~/.config/picom.conf --no-use-damage --daemon
pgrep -x nm-applet >/dev/null || nm-applet &
pgrep -x pasystray >/dev/null || pasystray &
pgrep -x dunst >/dev/null || dunst &
pgrep -x copyq >/dev/null || copyq &
pgrep -x blueman-applet >/dev/null || blueman-applet &

# keyboard customizations, only for the laptop
# TODO: Figure out how to customize laptop keyboard specifically
# xmodmap ~/.Xmodmap
setxkbmap -option caps:escape -option shift:both_capslock

# start other background services
xset r rate 200 35 &
xset s off -dpms &

# enable suspend lock services
systemctl --user enable lock-on-suspend.service
systemctl --user enable unlock-on-resume.service

# enable touchpad gestures (start client to connect to daemon)
pgrep -f "touchegg$" >/dev/null || touchegg &

# Start Conky in the background after a delay
export ACTIVE_INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5}')
pgrep -x conky >/dev/null || (conky | logger -t conky) &

notify-send "Qtile" "Config loaded successfully." -u low 2>/dev/null
