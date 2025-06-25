#!/bin/bash

screenshot_dir="$HOME/Pictures/screenshots"
mkdir -p "$screenshot_dir"

chosen=$(printf "🖥️ Full screen\n🪟 Active window\n📐 Region" | rofi -dmenu -p "Take screenshot")

case "$chosen" in
  "🖥️ Full screen")
    scrot "$screenshot_dir/%Y-%m-%d_%H-%M-%S.png" && notify-send "Screenshot" "Full screen saved"
    ;;
  "🪟 Active window")
    scrot -u "$screenshot_dir/%Y-%m-%d_%H-%M-%S.png" && notify-send "Screenshot" "Active window saved"
    ;;
  "📐 Region")
    scrot -s "$screenshot_dir/%Y-%m-%d_%H-%M-%S.png" && notify-send "Screenshot" "Region saved"
    ;;
esac
