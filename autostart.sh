#!/bin/bash
export XCURSOR_THEME=Adwaita
export XCURSOR_SIZE=24

# Hardware detection functions
has_battery() {
    ls /sys/class/power_supply/BAT* >/dev/null 2>&1
}

is_laptop() {
    has_battery
}

# only run once
pgrep -x picom >/dev/null || picom --config ~/.config/picom.conf --no-use-damage --daemon
pgrep -x nm-applet >/dev/null || nm-applet &
pgrep -x pasystray >/dev/null || pasystray &
pgrep -x dunst >/dev/null || dunst &
pgrep -x copyq >/dev/null || copyq &
pgrep -x blueman-applet >/dev/null || blueman-applet &

# keyboard customizations, only for the laptop
# TODO:Figure out how to customize laptop keyboard specifically
# xmodmap ~/.Xmodmap
setxkbmap -option caps:escape -option shift:both_capslock

# start other background services
xset r rate 200 35 &
xset s off -dpms &

# enable touchpad gestures (works with USB trackpads too)
pgrep -f "touchegg$" >/dev/null || touchegg &

# enable laptop-specific services only on laptops
if is_laptop; then
    # enable suspend lock services
    systemctl --user enable lock-on-suspend.service 2>/dev/null || true
    systemctl --user enable unlock-on-resume.service 2>/dev/null || true
fi

# Start Conky in the background after a delay
export ACTIVE_INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5}')
pgrep -x conky >/dev/null || (conky | logger -t conky) &

# enable auto-rotation service only on laptops (setup via install/auto-rotate/setup.sh)
if is_laptop; then
    systemctl --user start auto-rotate.service 2>/dev/null || true
fi
pgrep -f "monitor-manager.sh" >/dev/null || ~/.config/qtile/install/monitor-manager/monitor-manager.sh &

notify-send "Qtile" "Config loaded successfully." -u low 2>/dev/null
