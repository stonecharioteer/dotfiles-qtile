#!/bin/bash

echo "🔧 Setting up brightness control permissions"
echo "==========================================="

# Create udev rules for brightness control without sudo
sudo tee /etc/udev/rules.d/90-brightness.rules > /dev/null << 'EOF'
# Allow users in video group to control screen brightness
SUBSYSTEM=="backlight", ACTION=="add", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
SUBSYSTEM=="backlight", ACTION=="add", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"

# Allow users in input group to control keyboard backlight
SUBSYSTEM=="leds", ACTION=="add", KERNEL=="*kbd_backlight", RUN+="/bin/chgrp input /sys/class/leds/%k/brightness"
SUBSYSTEM=="leds", ACTION=="add", KERNEL=="*kbd_backlight", RUN+="/bin/chmod g+w /sys/class/leds/%k/brightness"
EOF

echo "✅ Created udev rules in /etc/udev/rules.d/90-brightness.rules"

# Apply the rules immediately
sudo udevadm control --reload-rules
sudo udevadm trigger

# Fix current permissions
sudo chgrp video /sys/class/backlight/*/brightness 2>/dev/null || true
sudo chmod g+w /sys/class/backlight/*/brightness 2>/dev/null || true
sudo chgrp input /sys/class/leds/*kbd_backlight/brightness 2>/dev/null || true
sudo chmod g+w /sys/class/leds/*kbd_backlight/brightness 2>/dev/null || true

echo "✅ Applied permissions immediately"
echo ""
echo "🧪 Testing brightness control:"
echo "   Screen brightness: $(brightnessctl -d nvidia_0 get 2>/dev/null || echo 'Failed')"
echo "   Keyboard backlight: $(brightnessctl -d asus::kbd_backlight get 2>/dev/null || echo 'Failed')"
echo ""
echo "If tests still fail, you may need to log out and back in for group membership to take effect."