#!/bin/bash

# Setup dunst notification styling for qtile
# Creates dunst config directory and copies styled configuration

set -e

echo "Setting up dunst notification styling..."

# Create dunst config directory if it doesn't exist
mkdir -p ~/.config/dunst

# Copy styled dunst configuration
cp "$(dirname "$0")/dunstrc" ~/.config/dunst/

echo "Dunst configuration installed to ~/.config/dunst/dunstrc"

# Check if dunst is running and restart it to apply new config
if pgrep -x "dunst" > /dev/null; then
    echo "Restarting dunst to apply new configuration..."
    killall dunst
    dunst &
    echo "Dunst restarted with new styling"
else
    echo "Starting dunst with new configuration..."
    dunst &
    echo "Dunst started"
fi

echo "Dunst styling setup complete!"
echo "Test with: notify-send 'Test' 'This is a test notification'"