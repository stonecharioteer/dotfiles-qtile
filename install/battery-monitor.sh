#!/bin/bash

# Battery monitoring script for qtile
# Add to crontab to run every 5 minutes: */5 * * * * /home/stonecharioteer/.config/qtile/install/battery-monitor.sh

# Check if battery exists
if [ ! -d "/sys/class/power_supply/BAT0" ] && [ ! -d "/sys/class/power_supply/BAT1" ]; then
    exit 0
fi

# Find the battery directory
BATTERY_DIR=""
for bat in /sys/class/power_supply/BAT*; do
    if [ -d "$bat" ]; then
        BATTERY_DIR="$bat"
        break
    fi
done

if [ -z "$BATTERY_DIR" ]; then
    exit 0
fi

# Read battery status
CAPACITY=$(cat "$BATTERY_DIR/capacity" 2>/dev/null || echo "0")
STATUS=$(cat "$BATTERY_DIR/status" 2>/dev/null || echo "Unknown")

# Threshold for low battery warning
LOW_BATTERY_THRESHOLD=30

# Check if battery is below threshold and not charging
if [ "$CAPACITY" -le "$LOW_BATTERY_THRESHOLD" ] && [ "$STATUS" != "Charging" ]; then
    # Send notification using dunst
    notify-send -u critical \
        -i "battery-caution" \
        "Low Battery Warning" \
        "Battery level is ${CAPACITY}%. Please connect charger."
fi

# Additional critical warning at 15%
if [ "$CAPACITY" -le 15 ] && [ "$STATUS" != "Charging" ]; then
    notify-send -u critical \
        -i "battery-empty" \
        "Critical Battery Warning" \
        "Battery level is ${CAPACITY}%. System will shutdown soon!"
fi