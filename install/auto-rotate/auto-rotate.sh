#!/bin/bash
set -eu

# Auto-rotation service for laptop display and touch inputs
# Monitors accelerometer data and rotates display/touch accordingly

SCRIPT_NAME="auto-rotate"
LOG_FILE="$HOME/.cache/${SCRIPT_NAME}.log"
LOCK_FILE="/tmp/${SCRIPT_NAME}.lock"
CONFIG_FILE="$HOME/.config/qtile/install/auto-rotate/config"

# Configuration defaults
ROTATE_EXTERNAL_DISPLAYS=false
ENABLE_LAPTOP_DISPLAY=true

# Load configuration if it exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check if script is already running
if [ -f "$LOCK_FILE" ]; then
    if ps -p "$(cat "$LOCK_FILE")" > /dev/null 2>&1; then
        log_message "Auto-rotate service already running (PID: $(cat "$LOCK_FILE"))"
        exit 1
    else
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file
echo $$ > "$LOCK_FILE"

# Cleanup function
cleanup() {
    log_message "Auto-rotate service stopping"
    rm -f "$LOCK_FILE"
    exit 0
}

trap cleanup EXIT INT TERM

log_message "Auto-rotate service starting"

# Function to get rotatable display name
get_rotatable_display() {
    # Find any connected display that can be rotated
    local connected_display=$(xrandr --query | grep " connected" | cut -d' ' -f1 | head -1)
    
    if [ -n "$connected_display" ]; then
        log_message "Using display for rotation: $connected_display"
        echo "$connected_display"
        return 0
    fi
    
    log_message "No connected display found for rotation."
    return 1
}

# Function to get touch devices
get_touch_devices() {
    # Get touchpad, stylus, and touchscreen devices
    xinput list --name-only | grep -iE "touch|finger|wacom|stylus" | head -5
    # Also get the ELAN9008 touchscreen device (without "Stylus" in name)
    xinput list --name-only | grep "ELAN9008:00 04F3:2C82$" | head -1
}

# Function to rotate display
rotate_display() {
    local orientation=$1
    local display=$(get_rotatable_display)
    
    if [ -z "$display" ]; then
        return 1
    fi
    
    case "$orientation" in
        "normal")
            xrandr --output "$display" --rotate normal
            ;;
        "right-up")
            xrandr --output "$display" --rotate right
            ;;
        "left-up")
            xrandr --output "$display" --rotate left
            ;;
        "bottom-up")
            xrandr --output "$display" --rotate inverted
            ;;
        *)
            log_message "Unknown orientation: $orientation"
            return 1
            ;;
    esac
    
    log_message "Rotated display $display to $orientation"
}

# Function to rotate touch inputs
rotate_touch_inputs() {
    local orientation=$1
    
    # Touch transformation matrices for different orientations
    local matrix_normal="1 0 0 0 1 0 0 0 1"
    local matrix_right="0 1 0 -1 0 1 0 0 1"
    local matrix_left="0 -1 1 1 0 0 0 0 1"
    local matrix_inverted="-1 0 1 0 -1 1 0 0 1"
    
    local matrix
    case "$orientation" in
        "normal")
            matrix="$matrix_normal"
            ;;
        "right-up")
            matrix="$matrix_right"
            ;;
        "left-up")
            matrix="$matrix_left"
            ;;
        "bottom-up")
            matrix="$matrix_inverted"
            ;;
        *)
            log_message "Unknown touch orientation: $orientation"
            return 1
            ;;
    esac
    
    # Apply transformation to all touch devices
    while IFS= read -r device; do
        if [ -n "$device" ]; then
            # Try standard Coordinate Transformation Matrix first
            if xinput set-prop "$device" "Coordinate Transformation Matrix" $matrix 2>/dev/null; then
                log_message "Rotated touch device: $device (standard matrix)"
            # If that fails, try libinput Calibration Matrix (for stylus devices)
            elif xinput set-prop "$device" "libinput Calibration Matrix" $matrix 2>/dev/null; then
                log_message "Rotated touch device: $device (libinput matrix)"
            else
                log_message "Failed to rotate touch device: $device (no compatible matrix property)"
            fi
        fi
    done < <(get_touch_devices)
}

# Function to handle orientation change
handle_orientation_change() {
    local new_orientation=$1
    
    if [ "$new_orientation" != "$current_orientation" ]; then
        log_message "Orientation changed from $current_orientation to $new_orientation"
        
        # Rotate display
        if rotate_display "$new_orientation"; then
            log_message "Display rotation completed successfully"
        else
            log_message "Display rotation failed"
        fi
        
        # Rotate touch inputs
        if rotate_touch_inputs "$new_orientation"; then
            log_message "Touch rotation completed successfully"
        else
            log_message "Touch rotation failed"
        fi
        
        # Send notification
        if command -v dunstify >/dev/null 2>&1; then
            dunstify -u low -i display "Display Rotation" "Rotated to: $new_orientation" -t 2000 2>/dev/null || true
            log_message "Sent notification for orientation: $new_orientation"
        else
            log_message "dunstify not available for notification"
        fi
        
        current_orientation="$new_orientation"
    fi
}

# Check if required tools are available
if ! command -v monitor-sensor >/dev/null 2>&1; then
    log_message "ERROR: monitor-sensor not found. Install iio-sensor-proxy package."
    exit 1
fi

if ! command -v xrandr >/dev/null 2>&1; then
    log_message "ERROR: xrandr not found."
    exit 1
fi

if ! command -v xinput >/dev/null 2>&1; then
    log_message "ERROR: xinput not found."
    exit 1
fi

# Initialize current orientation
current_orientation="normal"

# Main monitoring loop
log_message "Starting orientation monitoring..."

# Use a named pipe to avoid pipeline issues
PIPE="/tmp/auto-rotate-$$"
mkfifo "$PIPE"

# Start monitor-sensor in background
monitor-sensor --accel 2>/dev/null > "$PIPE" &
MONITOR_PID=$!

# Clean up pipe on exit
cleanup_pipe() {
    kill $MONITOR_PID 2>/dev/null || true
    rm -f "$PIPE"
    cleanup
}
trap cleanup_pipe EXIT INT TERM

# Read from pipe
while read -r line < "$PIPE"; do
    log_message "Monitor-sensor output: $line"
    if echo "$line" | grep -q "Accelerometer orientation changed:"; then
        orientation=$(echo "$line" | sed 's/.*Accelerometer orientation changed: //')
        log_message "Detected orientation change to: $orientation"
        handle_orientation_change "$orientation"
    fi
done

log_message "Monitor-sensor exited unexpectedly"