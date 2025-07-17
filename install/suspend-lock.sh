#!/bin/bash

# Suspend lock script for qtile
# Locks screen before system suspend and handles post-suspend actions

# Function to lock screen using the best available method
lock_screen() {
    # Try loginctl first (most reliable)
    if command -v loginctl >/dev/null 2>&1; then
        loginctl lock-session
    # Fallback to cinnamon-screensaver if loginctl fails
    elif command -v cinnamon-screensaver-command >/dev/null 2>&1; then
        cinnamon-screensaver-command --lock
    # Fallback to other screen lockers
    elif command -v i3lock >/dev/null 2>&1; then
        i3lock -c 000000
    elif command -v xscreensaver-command >/dev/null 2>&1; then
        xscreensaver-command -lock
    else
        echo "No screen locker found!" >&2
        return 1
    fi
    
    # Wait a moment for lock to engage
    sleep 0.5
    
    # Optionally send notification (will be shown when unlocked)
    notify-send "System Suspended" "Screen locked before suspend" -u low 2>/dev/null
}

# Function to handle pre-suspend actions
pre_suspend() {
    echo "$(date): Pre-suspend actions starting" >> ~/.cache/qtile-suspend.log
    
    # Lock the screen
    lock_screen
    
    # Additional pre-suspend actions can go here
    # e.g., pause music, save work, etc.
    
    echo "$(date): Pre-suspend actions completed" >> ~/.cache/qtile-suspend.log
}

# Function to handle post-suspend actions
post_suspend() {
    echo "$(date): Post-suspend actions starting" >> ~/.cache/qtile-suspend.log
    
    # Restore wallpaper (in case it gets corrupted)
    nitrogen --restore &
    
    # Optionally restart some services that might need it
    # (This runs after unlock, so user will see any notifications)
    
    echo "$(date): Post-suspend actions completed" >> ~/.cache/qtile-suspend.log
}

# Main logic
case "${1:-pre}" in
    "pre")
        pre_suspend
        ;;
    "post")
        post_suspend
        ;;
    "lock")
        lock_screen
        ;;
    *)
        echo "Usage: $0 {pre|post|lock}"
        exit 1
        ;;
esac