#!/bin/bash

# Dual 4K Monitor Setup Script for USB-C Dock
# Sets up two 4K monitors at 1440p resolution through USB-C dock
# Handles DisplayPort + HDMI connection bandwidth limitations

set -e

echo "=== Dual 4K Monitor Setup for USB-C Dock ==="
echo "Setting up DisplayPort-2-8 (DP cable) and DisplayPort-2-9 (HDMI cable)"

# Remove any existing custom modes to start clean
echo "Cleaning existing custom modes..."
xrandr --delmode DisplayPort-2-8 "2560x1440_60.00" 2>/dev/null || true
xrandr --delmode DisplayPort-2-9 "2560x1440_60.00" 2>/dev/null || true
xrandr --delmode DisplayPort-2-8 "2560x1440_30.00" 2>/dev/null || true
xrandr --delmode DisplayPort-2-9 "2560x1440_30.00" 2>/dev/null || true
xrandr --delmode DisplayPort-2-8 "3840x2160_60.00" 2>/dev/null || true
xrandr --delmode DisplayPort-2-9 "3840x2160_60.00" 2>/dev/null || true
xrandr --rmmode "2560x1440_60.00" 2>/dev/null || true
xrandr --rmmode "2560x1440_30.00" 2>/dev/null || true
xrandr --rmmode "3840x2160_60.00" 2>/dev/null || true

# Create display modes
echo "Creating 1440p @ 60Hz mode..."
xrandr --newmode "2560x1440_60.00" 312.25 2560 2752 3024 3488 1440 1443 1448 1493 -hsync +vsync

echo "Creating 1440p @ 30Hz mode (for HDMI bandwidth limitations)..."
xrandr --newmode "2560x1440_30.00" 146.25 2560 2680 2944 3328 1440 1443 1448 1468 -hsync +vsync

echo "Creating 4K @ 60Hz mode (optional)..."
xrandr --newmode "3840x2160_60.00" 712.75 3840 4160 4576 5312 2160 2163 2168 2237 -hsync +vsync

# Check if monitors are connected
if ! xrandr | grep -q "DisplayPort-2-8 connected"; then
    echo "ERROR: DisplayPort-2-8 not detected. Check DP cable connection."
    exit 1
fi

if ! xrandr | grep -q "DisplayPort-2-9 connected"; then
    echo "ERROR: DisplayPort-2-9 not detected. Check HDMI cable connection."
    exit 1
fi

# Add modes to both monitors
echo "Adding modes to DisplayPort-2-8 (DP cable)..."
xrandr --addmode DisplayPort-2-8 "2560x1440_60.00"
xrandr --addmode DisplayPort-2-8 "3840x2160_60.00"

echo "Adding modes to DisplayPort-2-9 (HDMI cable)..."
xrandr --addmode DisplayPort-2-9 "2560x1440_60.00"
xrandr --addmode DisplayPort-2-9 "2560x1440_30.00"
xrandr --addmode DisplayPort-2-9 "3840x2160_60.00"

# Configure monitors
echo "Setting DisplayPort-2-8 to 1440p @ 60Hz..."
xrandr --output DisplayPort-2-8 --mode "2560x1440_60.00" --pos 1920x0

echo "Setting DisplayPort-2-9 to 1440p @ 30Hz (HDMI bandwidth limit)..."
xrandr --output DisplayPort-2-9 --mode "2560x1440_30.00" --pos 4480x0

# Verify setup
echo ""
echo "=== Monitor Setup Complete ==="
xrandr --listmonitors

echo ""
echo "Current configuration:"
echo "- Laptop screen (DP-0): Primary display"
echo "- DisplayPort-2-8 (DP cable): 2560x1440 @ 60Hz"
echo "- DisplayPort-2-9 (HDMI cable): 2560x1440 @ 30Hz"
echo ""
echo "Note: HDMI monitor runs at 30Hz due to USB-C dock bandwidth limitations."
echo "For full 60Hz on both monitors, use two DisplayPort cables or upgrade dock."