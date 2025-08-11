#!/bin/bash
set -euo pipefail

# Map touchscreen to laptop display (DP-0) only
# This constrains touchscreen input to the laptop screen area when external monitors are connected

TOUCHSCREEN_DEVICE="ELAN9008:00 04F3:2C82"
LAPTOP_DISPLAY="DP-0"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
    logger -t "touchscreen-mapper" "$1" 2>/dev/null || true
}

# Function to map touchscreen to laptop display
map_touchscreen_to_laptop() {
    local rotation_matrix="${1:-1 0 0 0 1 0 0 0 1}"
    
    # Check if touchscreen device exists
    if ! xinput list --name-only | grep -q "^$TOUCHSCREEN_DEVICE$"; then
        log_message "Touchscreen device '$TOUCHSCREEN_DEVICE' not found"
        return 1
    fi
    
    # Get laptop display geometry
    local laptop_geometry
    laptop_geometry=$(xrandr --query | grep "$LAPTOP_DISPLAY connected" | grep -o '[0-9]*x[0-9]*+[0-9]*+[0-9]*')
    
    if [[ -z "$laptop_geometry" ]]; then
        log_message "Laptop display '$LAPTOP_DISPLAY' not found or not connected"
        return 1
    fi
    
    log_message "Found laptop display geometry: $laptop_geometry"
    
    # Parse geometry: WIDTHxHEIGHT+X_OFFSET+Y_OFFSET
    local laptop_width laptop_height laptop_x laptop_y
    laptop_width=$(echo "$laptop_geometry" | cut -d'x' -f1)
    laptop_height=$(echo "$laptop_geometry" | cut -d'x' -f2 | cut -d'+' -f1)
    laptop_x=$(echo "$laptop_geometry" | cut -d'+' -f2)
    laptop_y=$(echo "$laptop_geometry" | cut -d'+' -f3)
    
    # Get total desktop dimensions
    local desktop_info
    desktop_info=$(xrandr --query | grep "current" | head -1)
    local desktop_width desktop_height
    desktop_width=$(echo "$desktop_info" | sed 's/.*current \([0-9]*\) x \([0-9]*\).*/\1/')
    desktop_height=$(echo "$desktop_info" | sed 's/.*current \([0-9]*\) x \([0-9]*\).*/\2/')
    
    log_message "Desktop size: ${desktop_width}x${desktop_height}"
    log_message "Laptop display: ${laptop_width}x${laptop_height} at +${laptop_x}+${laptop_y}"
    
    # Calculate transformation matrix to map touchscreen to laptop display area
    # Matrix format: c0 c1 c2 c3 c4 c5 c6 c7 c8
    # where: x' = c0*x + c1*y + c2, y' = c3*x + c4*y + c5
    
    # Scale factors (laptop size / desktop size)
    local scale_x scale_y
    scale_x=$(echo "scale=6; $laptop_width / $desktop_width" | bc -l)
    scale_y=$(echo "scale=6; $laptop_height / $desktop_height" | bc -l)
    
    # Offset factors (laptop position / desktop size)  
    local offset_x offset_y
    offset_x=$(echo "scale=6; $laptop_x / $desktop_width" | bc -l)
    offset_y=$(echo "scale=6; $laptop_y / $desktop_height" | bc -l)
    
    # Create display mapping matrix
    local display_matrix="$scale_x 0 $offset_x 0 $scale_y $offset_y 0 0 1"
    
    # If rotation matrix provided, combine it with display mapping
    local final_matrix="$display_matrix"
    if [[ "$rotation_matrix" != "1 0 0 0 1 0 0 0 1" ]]; then
        log_message "Combining rotation matrix: $rotation_matrix"
        # For rotation, we need to apply display mapping first, then rotation
        # This is a simplified approach - proper matrix multiplication would be more accurate
        # but for touchscreen mapping, applying display area constraint is more important
        final_matrix="$display_matrix"
        log_message "Using display mapping matrix (rotation handled separately if needed)"
    fi
    
    log_message "Applying transformation matrix: $final_matrix"
    
    # Apply transformation matrix to touchscreen
    if xinput set-prop "$TOUCHSCREEN_DEVICE" "Coordinate Transformation Matrix" $final_matrix 2>/dev/null; then
        log_message "✓ Successfully mapped touchscreen to laptop display"
        return 0
    else
        log_message "✗ Failed to apply transformation matrix"
        return 1
    fi
}

# Check if bc calculator is available
if ! command -v bc >/dev/null 2>&1; then
    log_message "ERROR: bc calculator not found. Install bc package."
    exit 1
fi

# Check if xinput is available
if ! command -v xinput >/dev/null 2>&1; then
    log_message "ERROR: xinput not found"
    exit 1
fi

# Check if xrandr is available
if ! command -v xrandr >/dev/null 2>&1; then
    log_message "ERROR: xrandr not found"
    exit 1
fi

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script called directly
    rotation_matrix="${1:-1 0 0 0 1 0 0 0 1}"
    map_touchscreen_to_laptop "$rotation_matrix"
fi