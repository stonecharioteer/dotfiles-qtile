#!/bin/bash

# Monitor-aware suspend script for qtile
# Only allows suspend when using laptop screen only (single monitor)
# Prevents suspend when external monitor is connected

# Function to count connected monitors (mirrors qtile config logic)
count_monitors() {
    local output
    local monitors
    
    # Get xrandr output and count connected monitors
    if output=$(xrandr --query 2>/dev/null); then
        monitors=$(echo "$output" | grep -c " connected")
        echo "$monitors"
    else
        echo "1"  # Fallback to single monitor
    fi
}

# Function to check if we should allow suspend
should_suspend() {
    local monitor_count
    monitor_count=$(count_monitors)
    
    # Only suspend if we have exactly 1 monitor (laptop screen only)
    if [ "$monitor_count" -eq 1 ]; then
        return 0  # Allow suspend
    else
        return 1  # Prevent suspend
    fi
}

# Main logic
case "${1:-check}" in
    "check")
        # Check if suspend should be allowed
        if should_suspend; then
            echo "Single monitor detected - suspend allowed"
            exit 0
        else
            echo "Multiple monitors detected - suspend prevented"
            exit 1
        fi
        ;;
    "suspend")
        # Perform suspend if allowed
        if should_suspend; then
            echo "Initiating suspend..."
            systemctl suspend
        else
            echo "Suspend prevented - external monitor connected"
            # Send notification to user
            notify-send "Suspend Prevented" "External monitor connected - lid close ignored" -u normal 2>/dev/null
        fi
        ;;
    *)
        echo "Usage: $0 {check|suspend}"
        exit 1
        ;;
esac