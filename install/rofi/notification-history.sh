#!/bin/bash

# Rofi script to display dunst notification history
# Shows expanded notification text and copies to clipboard when selected

set -e

# Function to format timestamp
format_timestamp() {
    local timestamp_ms=$1
    # Convert microseconds to seconds since epoch
    local timestamp_s=$((timestamp_ms / 1000000))
    # Add current time offset to get actual time
    local current_time=$(date +%s)
    local boot_time=$(awk '{print int($1)}' /proc/uptime)
    local actual_time=$((current_time - boot_time + timestamp_s))
    date -d "@$actual_time" "+%H:%M:%S %m/%d"
}

# Function to clean and format notification text
clean_text() {
    echo "$1" | sed 's/<[^>]*>//g' | tr '\n' ' ' | sed 's/  */ /g'
}

# Get notification history and parse JSON
history_json=$(dunstctl history)

# Check if history is empty
if [[ "$history_json" == *'"data" : [ ]'* ]]; then
    rofi -dmenu -p "Notifications" -mesg "No notifications in history" <<< ""
    exit 0
fi

# Create temporary files for data storage
temp_dir=$(mktemp -d)
display_file="$temp_dir/display"
data_file="$temp_dir/data"

# Parse JSON and format for rofi
echo "$history_json" | jq -r '
.data[0] | reverse | to_entries[] | 
"\(.key)|\(.value.timestamp.data)|\(.value.appname.data)|\(.value.summary.data)|\(.value.body.data)"
' | while IFS='|' read -r index timestamp appname summary body; do
    # Format timestamp
    formatted_time=$(format_timestamp "$timestamp")
    
    # Clean text
    clean_summary=$(clean_text "$summary")
    clean_body=$(clean_text "$body")
    
    # Store full data for later retrieval
    echo "$index|$formatted_time|$appname|$clean_summary|$clean_body" >> "$data_file"
    
    # Truncate long text for display
    display_summary="$clean_summary"
    display_body="$clean_body"
    if [[ ${#display_summary} -gt 30 ]]; then
        display_summary="${display_summary:0:27}..."
    fi
    if [[ ${#display_body} -gt 50 ]]; then
        display_body="${display_body:0:47}..."
    fi
    
    # Format for rofi display
    printf "%-12s %-15s %-30s %s\n" "[$formatted_time]" "[$appname]" "$display_summary" "$display_body" >> "$display_file"
done

# Main loop for navigation
while true; do
    # Show in rofi
    selected_line=$(rofi -dmenu -i \
        -p "Notification History" \
        -mesg "Select a notification to view full text and copy to clipboard" \
        -theme-str 'window {width: 80%;}' \
        -theme-str 'listview {lines: 10;}' \
        -format 'i' < "$display_file")

    # If nothing was selected (escape pressed), exit
    if [[ -z "$selected_line" ]]; then
        break
    fi

    # Get the selected notification data (1-indexed to 0-indexed)
    selected_data=$(sed -n "$((selected_line + 1))p" "$data_file")
    
    if [[ -n "$selected_data" ]]; then
        IFS='|' read -r index formatted_time appname clean_summary clean_body <<< "$selected_data"
        
        # Create expanded text
        expanded_text="[$formatted_time] $appname
$clean_summary

$clean_body"
        
        # Copy to clipboard
        echo "$expanded_text" | xclip -selection clipboard
        
        # Show expanded notification in rofi
        expanded_result=$(echo "$expanded_text" | rofi -dmenu \
            -p "Notification Details (Copied to Clipboard)" \
            -mesg "Press Enter to return to notification list" \
            -theme-str 'window {width: 60%;}' \
            -theme-str 'listview {lines: 8;}' \
            -no-custom)
        
        # Whether they pressed escape or not, we continue the loop back to main list
    fi
done

# Cleanup
rm -rf "$temp_dir"