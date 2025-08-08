#!/bin/bash

# Monitor Manager - Interactive display configuration
# Watches for monitor connection changes and presents configuration options

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOG_FILE="$HOME/.cache/qtile-monitor-manager.log"
LOCK_FILE="/tmp/monitor-manager.lock"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    logger -t "monitor-manager" "$1"
}

cleanup() {
    rm -f "$LOCK_FILE"
    exit 0
}

trap cleanup EXIT INT TERM

# Prevent multiple instances
if [[ -f "$LOCK_FILE" ]]; then
    log "Another instance is running, exiting"
    exit 1
fi
echo $$ > "$LOCK_FILE"

get_connected_monitors() {
    xrandr --query | grep " connected" | cut -d' ' -f1 | sort
}

show_monitor_menu() {
    local action="$1"
    local monitor_info="$2"
    
    # Call the separate menu script
    "$SCRIPT_DIR/monitor-menu.sh" "$action" "$monitor_info"
}

monitor_displays() {
    log "Starting monitor detection service"
    local previous_monitors
    previous_monitors=$(get_connected_monitors)
    
    while true; do
        sleep 2
        local current_monitors
        current_monitors=$(get_connected_monitors)
        
        if [[ "$current_monitors" != "$previous_monitors" ]]; then
            log "Monitor change detected"
            log "Previous: $previous_monitors"
            log "Current: $current_monitors"
            
            # Determine what changed
            local added_monitors
            local removed_monitors
            
            added_monitors=$(comm -13 <(echo "$previous_monitors") <(echo "$current_monitors") | tr '\n' ' ')
            removed_monitors=$(comm -23 <(echo "$previous_monitors") <(echo "$current_monitors") | tr '\n' ' ')
            
            local action=""
            local info=""
            
            if [[ -n "$added_monitors" ]] && [[ -n "$removed_monitors" ]]; then
                action="Monitors Changed"
                info="Added: $added_monitors | Removed: $removed_monitors"
            elif [[ -n "$added_monitors" ]]; then
                action="Monitor Connected"
                info="$added_monitors"
            elif [[ -n "$removed_monitors" ]]; then
                action="Monitor Disconnected"
                info="$removed_monitors"
            fi
            
            if [[ -n "$action" ]]; then
                # Small delay to let system settle
                sleep 1
                show_monitor_menu "$action" "$info"
            fi
            
            previous_monitors="$current_monitors"
        fi
    done
}

# Check if required tools are available
for tool in xrandr rofi autorandr dunstify; do
    if ! command -v "$tool" &> /dev/null; then
        log "ERROR: Required tool '$tool' not found"
        exit 1
    fi
done

# Start monitoring
log "Monitor manager started with PID $$"
monitor_displays