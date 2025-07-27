#!/bin/bash

screenshot_dir="$HOME/Pictures/screenshots"
mkdir -p "$screenshot_dir"

# Get connected displays with monitor numbers for scrot -M
declare -A monitor_map
displays=""

while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*([0-9]+):[[:space:]]*\+([^[:space:]]+)[[:space:]]+([0-9]+/[0-9]+x[0-9]+/[0-9]+\+[0-9]+\+[0-9]+)[[:space:]]+(.+)$ ]]; then
        monitor_num="${BASH_REMATCH[1]}"
        geometry="${BASH_REMATCH[3]}"
        display_name="${BASH_REMATCH[4]}"
        
        # Extract dimensions from geometry
        if [[ "$geometry" =~ ([0-9]+)/[0-9]+x([0-9]+)/[0-9]+\+([0-9]+)\+([0-9]+) ]]; then
            width="${BASH_REMATCH[1]}"
            height="${BASH_REMATCH[2]}"
            x_pos="${BASH_REMATCH[3]}"
            y_pos="${BASH_REMATCH[4]}"
            
            display_option="🖥️ $display_name (${width}x${height} at ${x_pos},${y_pos})"
            monitor_map["$display_option"]="$monitor_num"
            
            if [ -n "$displays" ]; then
                displays="$displays\n$display_option"
            else
                displays="$display_option"
            fi
        fi
    fi
done < <(xrandr --listmonitors | grep -v "Monitors:")

# Build menu options
menu_options="🖥️ Full screen\n🪟 Active window\n📐 Region"
if [ -n "$displays" ]; then
    menu_options="$menu_options\n$displays"
fi

chosen=$(printf "$menu_options" | rofi -dmenu -p "Take screenshot")

case "$chosen" in
  "🖥️ Full screen")
    filename="$screenshot_dir/$(date +%Y-%m-%d_%H-%M-%S).png"
    scrot "$filename" && echo -n "$filename" | xclip -selection clipboard && notify-send "Screenshot" "Full screen saved and path copied to clipboard"
    ;;
  "🪟 Active window")
    filename="$screenshot_dir/$(date +%Y-%m-%d_%H-%M-%S).png"
    scrot -u "$filename" && echo -n "$filename" | xclip -selection clipboard && notify-send "Screenshot" "Active window saved and path copied to clipboard"
    ;;
  "📐 Region")
    filename="$screenshot_dir/$(date +%Y-%m-%d_%H-%M-%S).png"
    scrot -s "$filename" && echo -n "$filename" | xclip -selection clipboard && notify-send "Screenshot" "Region saved and path copied to clipboard"
    ;;
  🖥️*)
    # Get monitor number from our mapping
    monitor_num="${monitor_map["$chosen"]}"
    
    if [ -n "$monitor_num" ]; then
      filename="$screenshot_dir/$(date +%Y-%m-%d_%H-%M-%S).png"
      display_name=$(echo "$chosen" | sed 's/🖥️ //' | sed 's/ (.*//')
      
      scrot -M "$monitor_num" "$filename" && echo -n "$filename" | xclip -selection clipboard && notify-send "Screenshot" "Display $display_name saved and path copied to clipboard"
    else
      notify-send "Screenshot Error" "Could not find monitor number for selected display"
    fi
    ;;
esac
