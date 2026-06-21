#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${BATTERY_LOG_FILE:-$HOME/.cache/battery-life.csv}"
mkdir -p "$(dirname "$LOG_FILE")"

if [ ! -f "$LOG_FILE" ]; then
    printf 'timestamp,battery,capacity_percent,status,energy_now_wh,energy_full_wh,energy_full_design_wh,power_now_w,voltage_v,charge_limit_percent,ac_online,estimated_runtime_hours\n' > "$LOG_FILE"
fi

read_value() {
    local file="$1"
    local default="${2:-}"
    if [ -r "$file" ]; then
        cat "$file"
    else
        printf '%s' "$default"
    fi
}

micro_to_unit() {
    local value="$1"
    if [ -n "$value" ]; then
        awk -v v="$value" 'BEGIN { printf "%.3f", v / 1000000 }'
    else
        printf ''
    fi
}

estimate_runtime_hours() {
    local status="$1"
    local energy_now="$2"
    local power_now="$3"

    if [ "$status" = "Discharging" ] && [ -n "$energy_now" ] && [ -n "$power_now" ] && [ "$power_now" -gt 0 ] 2>/dev/null; then
        awk -v e="$energy_now" -v p="$power_now" 'BEGIN { printf "%.2f", e / p }'
    else
        printf ''
    fi
}

ac_online="unknown"
for ac in /sys/class/power_supply/A*/online /sys/class/power_supply/AC*/online; do
    if [ -r "$ac" ]; then
        ac_online=$(cat "$ac")
        break
    fi
done

timestamp=$(date -Is)

for battery in /sys/class/power_supply/BAT*; do
    [ -d "$battery" ] || continue

    name=$(basename "$battery")
    capacity=$(read_value "$battery/capacity")
    status=$(read_value "$battery/status")
    energy_now=$(read_value "$battery/energy_now")
    energy_full=$(read_value "$battery/energy_full")
    energy_full_design=$(read_value "$battery/energy_full_design")
    power_now=$(read_value "$battery/power_now")
    voltage_now=$(read_value "$battery/voltage_now")
    charge_limit=$(read_value "$battery/charge_control_end_threshold")

    energy_now_wh=$(micro_to_unit "$energy_now")
    energy_full_wh=$(micro_to_unit "$energy_full")
    energy_full_design_wh=$(micro_to_unit "$energy_full_design")
    power_now_w=$(micro_to_unit "$power_now")
    voltage_v=$(micro_to_unit "$voltage_now")
    runtime_hours=$(estimate_runtime_hours "$status" "$energy_now" "$power_now")

    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
        "$timestamp" "$name" "$capacity" "$status" \
        "$energy_now_wh" "$energy_full_wh" "$energy_full_design_wh" \
        "$power_now_w" "$voltage_v" "$charge_limit" "$ac_online" "$runtime_hours" \
        >> "$LOG_FILE"
done
