#!/bin/bash

# only run once
pgrep -x picom >/dev/null || picom --config ~/.config/picom.conf --no-use-damage --daemon
pgrep -x nm-applet >/dev/null || nm-applet &
pgrep -x pasystray >/dev/null || pasystray &
pgrep -x dunst >/dev/null || dunst &
pgrep -x copyq >/dev/null || copyq &
pgrep -x blueman-applet >/dev/null || blueman-applet &

# keyboard customizations
setxkbmap -option caps:escape -option shift:both_capslock

# start other background services
xset r rate 200 35 &

# Enable display power management so the monitor can sleep while the
# machine continues running.
# Timings are: screensaver blank after 5 min, DPMS standby after 5 min,
# suspend after 10 min, and power off after 15 min.
xset s blank &
xset s 300 300 &
xset +dpms &
xset dpms 300 600 900 &

# ensure screenshots directory exists
mkdir -p ~/Pictures/screenshots

# enable touchpad gestures (works with USB trackpads too)
pgrep -f "touchegg$" >/dev/null || touchegg &

# Start Conky in the background after a delay
export ACTIVE_INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5}')
pgrep -x conky >/dev/null || (conky | logger -t conky) &

pgrep -f "monitor-manager.sh" >/dev/null || ~/.config/qtile/install/monitor-manager/monitor-manager.sh &

notify-send "Qtile" "Config loaded successfully." -u low 2>/dev/null
