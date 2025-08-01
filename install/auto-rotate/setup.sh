#!/bin/bash
set -euo pipefail

# Setup script for auto-rotate service
# Automatically configures laptop display and touch input rotation based on accelerometer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="auto-rotate.service"
SERVICE_FILE="$SCRIPT_DIR/$SERVICE_NAME"
SCRIPT_FILE="$SCRIPT_DIR/auto-rotate.sh"

echo "Setting up auto-rotate service..."

# Check if required files exist
if [ ! -f "$SERVICE_FILE" ]; then
    echo "ERROR: Service file not found: $SERVICE_FILE"
    exit 1
fi

if [ ! -f "$SCRIPT_FILE" ]; then
    echo "ERROR: Script file not found: $SCRIPT_FILE"
    exit 1
fi

# Make script executable
chmod +x "$SCRIPT_FILE"
echo "✓ Made auto-rotate.sh executable"

# Check for required dependencies
missing_deps=()

if ! command -v monitor-sensor >/dev/null 2>&1; then
    missing_deps+=("iio-sensor-proxy")
fi

if ! command -v xrandr >/dev/null 2>&1; then
    missing_deps+=("xrandr (x11-xserver-utils)")
fi

if ! command -v xinput >/dev/null 2>&1; then
    missing_deps+=("xinput (xinput)")
fi

if ! command -v dunstify >/dev/null 2>&1; then
    echo "⚠ dunstify not found - notifications will be disabled"
fi

if [ ${#missing_deps[@]} -gt 0 ]; then
    echo "ERROR: Missing required dependencies:"
    for dep in "${missing_deps[@]}"; do
        echo "  - $dep"
    done
    echo ""
    echo "Install missing dependencies and run setup again."
    exit 1
fi

# Test accelerometer availability
echo "Testing accelerometer availability..."
timeout 3 monitor-sensor --accel >/dev/null 2>&1
if [ $? -eq 124 ]; then
    echo "⚠ Accelerometer test timed out - may not be available"
elif [ $? -ne 0 ]; then
    echo "⚠ Accelerometer test failed - functionality may be limited"
else
    echo "✓ Accelerometer detected"
fi

# Stop existing service if running
if systemctl --user is-active --quiet "$SERVICE_NAME"; then
    echo "Stopping existing auto-rotate service..."
    systemctl --user stop "$SERVICE_NAME"
fi

# Link and enable the service
echo "Installing systemd user service..."
systemctl --user link "$SERVICE_FILE"
systemctl --user enable "$SERVICE_NAME"

# Start the service
echo "Starting auto-rotate service..."
systemctl --user start "$SERVICE_NAME"

# Check service status
if systemctl --user is-active --quiet "$SERVICE_NAME"; then
    echo "✓ Auto-rotate service is running"
else
    echo "ERROR: Failed to start auto-rotate service"
    echo "Check service status with: systemctl --user status $SERVICE_NAME"
    echo "Check logs with: journalctl --user -u $SERVICE_NAME -f"
    exit 1
fi

echo ""
echo "Auto-rotate setup completed successfully!"
echo ""
echo "Service commands:"
echo "  Status:  systemctl --user status $SERVICE_NAME"
echo "  Stop:    systemctl --user stop $SERVICE_NAME"
echo "  Start:   systemctl --user start $SERVICE_NAME"
echo "  Logs:    journalctl --user -u $SERVICE_NAME -f"
echo "  Log file: ~/.cache/auto-rotate.log"
echo ""
echo "The service will automatically start on login."