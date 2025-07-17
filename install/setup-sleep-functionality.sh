#!/bin/bash

# Setup script for qtile sleep functionality
# This script configures system-level settings for intelligent laptop suspend

set -e  # Exit on any error

echo "Setting up qtile sleep functionality..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "Error: This script should not be run as root. Please run as your regular user."
    echo "The script will prompt for sudo when needed."
    exit 1
fi

# Check if systemd-logind is available
if ! systemctl is-active --quiet systemd-logind; then
    echo "Error: systemd-logind is not running. This is required for lid switch handling."
    exit 1
fi

# Create logind configuration directory
echo "Creating systemd logind configuration directory..."
sudo mkdir -p /etc/systemd/logind.conf.d

# Create lid suspend configuration
echo "Creating lid suspend configuration..."
sudo tee /etc/systemd/logind.conf.d/lid-suspend.conf > /dev/null << 'EOF'
[Login]
# Handle lid switch events
HandleLidSwitch=suspend
HandleLidSwitchDocked=ignore
HandleLidSwitchExternalPower=suspend

# Power button handling (optional)
HandlePowerKey=poweroff
HandlePowerKeyLongPress=ignore

# Suspend delay (optional - 30 seconds)
HoldoffTimeoutSec=30
EOF

echo "Configuration file created at /etc/systemd/logind.conf.d/lid-suspend.conf"

# Restart systemd-logind to apply changes
echo "Restarting systemd-logind to apply changes..."
sudo systemctl restart systemd-logind

# Verify the service is still running
if systemctl is-active --quiet systemd-logind; then
    echo "✅ systemd-logind restarted successfully"
else
    echo "❌ Error: systemd-logind failed to restart"
    exit 1
fi

# Test if the user services exist
echo "Checking user systemd services..."
if [[ -f "$HOME/.config/systemd/user/lock-on-suspend.service" ]]; then
    echo "✅ lock-on-suspend.service found"
else
    echo "❌ lock-on-suspend.service not found - make sure qtile config is properly set up"
fi

if [[ -f "$HOME/.config/systemd/user/unlock-on-resume.service" ]]; then
    echo "✅ unlock-on-resume.service found"
else
    echo "❌ unlock-on-resume.service not found - make sure qtile config is properly set up"
fi

# Test the monitor detection script
echo "Testing monitor detection script..."
if [[ -x "$HOME/.config/qtile/install/monitor-aware-suspend.sh" ]]; then
    echo "✅ monitor-aware-suspend.sh is executable"
    echo "Current monitor status:"
    "$HOME/.config/qtile/install/monitor-aware-suspend.sh" check
else
    echo "❌ monitor-aware-suspend.sh not found or not executable"
fi

echo ""
echo "🎉 Sleep functionality setup complete!"
echo ""
echo "Next steps:"
echo "1. Restart qtile to enable the user services"
echo "2. Test by closing your laptop lid:"
echo "   - With laptop screen only: should suspend and lock"
echo "   - With external monitor: should NOT suspend (notification shown)"
echo "3. Check logs in ~/.cache/qtile-suspend.log for debugging"
echo ""
echo "To test without restarting qtile, run:"
echo "  systemctl --user enable lock-on-suspend.service"
echo "  systemctl --user enable unlock-on-resume.service"