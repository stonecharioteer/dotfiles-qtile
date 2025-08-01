#!/bin/bash
set -euo pipefail

# Reset all touch input devices to normal orientation

echo "Resetting touch input devices to normal orientation..."

# Reset touchpad
if xinput list --name-only | grep -q "ELAN1201:00 04F3:3098 Touchpad"; then
    xinput set-prop "ELAN1201:00 04F3:3098 Touchpad" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
    echo "✓ Reset touchpad"
fi

# Reset stylus
if xinput list --name-only | grep -q "ELAN9008:00 04F3:2C82 Stylus"; then
    xinput set-prop "ELAN9008:00 04F3:2C82 Stylus" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1 2>/dev/null || echo "⚠ Could not reset stylus"
fi

# Reset any other touch devices
xinput list --name-only | grep -iE "touch|finger|wacom" | while read -r device; do
    if [[ "$device" != *"ELAN1201"* && "$device" != *"ELAN9008"* ]]; then
        xinput set-prop "$device" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1 2>/dev/null || echo "⚠ Could not reset: $device"
        echo "✓ Reset: $device"
    fi
done || true

echo "Touch input reset complete."