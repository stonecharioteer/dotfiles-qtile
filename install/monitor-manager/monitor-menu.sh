#!/bin/bash

# Monitor Menu - Interactive display configuration menu
# Can be called manually or from monitor detection service

LOG_FILE="$HOME/.cache/qtile-monitor-manager.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    logger -t "monitor-manager" "$1"
}

show_monitor_menu() {
    local action="${1:-Manual Trigger}"
    local monitor_info="${2:-Current Setup}"
    
    # Menu options
    local options=(
        "🖥️ Auto Configure (autorandr -c)"
        "🔧 Launch ARandR (GUI)"
        "📋 Show Current Setup"
        "💾 Save Current Profile"
        "📂 Load Profile"
        "🔄 Detect Monitors"
        "❌ Do Nothing"
    )
    
    local choice
    choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "$action: $monitor_info" -theme-str 'window {width: 400px;}')
    
    case "$choice" in
        "🖥️ Auto Configure (autorandr -c)")
            log "User selected: Auto configure"
            autorandr -c
            qtile cmd-obj -o cmd -f reload_config
            dunstify -i display "Monitor Manager" "Applied auto configuration and reloaded qtile"
            ;;
        "🔧 Launch ARandR (GUI)")
            log "User selected: Launch ARandR"
            arandr &
            ;;
        "📋 Show Current Setup")
            log "User selected: Show current setup"
            local setup
            setup=$(autorandr --current 2>/dev/null || echo "No saved profile active")
            dunstify -i display "Current Setup" "$setup" -t 5000
            ;;
        "💾 Save Current Profile")
            log "User selected: Save current profile"
            local profile_name
            profile_name=$(echo "" | rofi -dmenu -p "Enter profile name:")
            if [[ -n "$profile_name" ]]; then
                autorandr --save "$profile_name"
                dunstify -i display "Profile Saved" "Saved as: $profile_name"
                log "Saved profile: $profile_name"
            fi
            ;;
        "📂 Load Profile")
            log "User selected: Load profile"
            local profiles
            profiles=$(autorandr --list 2>/dev/null)
            if [[ -n "$profiles" ]]; then
                local selected_profile
                selected_profile=$(echo "$profiles" | rofi -dmenu -p "Select profile:")
                if [[ -n "$selected_profile" ]]; then
                    autorandr --load "$selected_profile"
                    qtile cmd-obj -o cmd -f reload_config
                    dunstify -i display "Profile Loaded" "Applied: $selected_profile and reloaded qtile"
                    log "Loaded profile: $selected_profile"
                fi
            else
                dunstify -i display "No Profiles" "No saved autorandr profiles found"
            fi
            ;;
        "🔄 Detect Monitors")
            log "User selected: Detect monitors"
            xrandr --auto
            dunstify -i display "Monitor Detection" "Rescanned for monitors"
            ;;
        "❌ Do Nothing"|"")
            log "User selected: Do nothing"
            ;;
    esac
}

# Check if required tools are available
for tool in xrandr rofi autorandr dunstify qtile; do
    if ! command -v "$tool" &> /dev/null; then
        log "ERROR: Required tool '$tool' not found"
        dunstify -i error "Monitor Manager" "Missing required tool: $tool"
        exit 1
    fi
done

# Show the menu
log "Monitor menu triggered manually"
show_monitor_menu "$@"