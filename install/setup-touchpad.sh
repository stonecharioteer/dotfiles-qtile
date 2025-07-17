#!/bin/bash

# Setup script for touchpad gestures
# Configures touchegg for pinch zoom and horizontal swipe navigation

set -e  # Exit on any error

echo "Setting up touchpad gestures..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "Error: This script should not be run as root. Please run as your regular user."
    echo "The script will prompt for sudo when needed."
    exit 1
fi

# Check if touchegg is installed
if ! command -v touchegg &> /dev/null; then
    echo "Error: touchegg is not installed. Please install it first:"
    echo "  sudo apt install touchegg"
    exit 1
fi

# Create touchegg config directory
echo "Creating touchegg configuration directory..."
mkdir -p ~/.config/touchegg

# Copy touchegg configuration
echo "Installing touchegg configuration..."
cp "$(dirname "$0")/touchegg.conf" ~/.config/touchegg/touchegg.conf

# Restart touchegg to reload configuration
echo "Restarting touchegg service to reload configuration..."
sudo systemctl restart touchegg.service

# Install X11 touchpad configuration (requires sudo)
echo "Installing X11 touchpad configuration..."
sudo cp "$(dirname "$0")/40-libinput-touchpad.conf" /etc/X11/xorg.conf.d/

# Enable and start touchegg service (system service)
echo "Enabling touchegg service..."
sudo systemctl enable touchegg.service
sudo systemctl start touchegg.service

# Check if service is running
if systemctl is-active --quiet touchegg.service; then
    echo "✅ touchegg service is running"
else
    echo "❌ Error: touchegg service failed to start"
    echo "Check service status with: systemctl status touchegg.service"
    exit 1
fi

# Test touchpad device
echo "Testing touchpad device detection..."
if xinput list | grep -i touchpad > /dev/null; then
    echo "✅ Touchpad device detected"
    xinput list | grep -i touchpad
else
    echo "❌ Warning: No touchpad device detected"
fi

echo ""
echo "🎉 Touchpad gestures setup complete!"
echo ""
echo "Configured gestures:"
echo "  - 2-finger pinch in/out: Zoom in/out (Ctrl+Plus/Minus)"
echo "  - 2-finger swipe left: Browser forward (Alt+Right)"
echo "  - 2-finger swipe right: Browser back (Alt+Left)"
echo ""
echo "⚠️  IMPORTANT: You need to restart your X11 session for touchpad settings to take effect."
echo "   Log out and log back in, or restart your computer."
echo ""
echo "To test gestures without restarting:"
echo "  1. Open a web browser"
echo "  2. Try pinch gestures on a webpage"
echo "  3. Try horizontal swipe gestures to navigate back/forward"
echo ""
echo "If gestures don't work, check the service status:"
echo "  systemctl status touchegg.service"