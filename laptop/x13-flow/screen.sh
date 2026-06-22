#!/usr/bin/env bash
set -euo pipefail

BACKLIGHT="${BACKLIGHT:-/sys/class/backlight/amdgpu_bl1}"
FB_BLANK="${FB_BLANK:-/sys/class/graphics/fb0/blank}"

usage() {
  cat <<EOF
Usage: $0 --off|--on|--status

Controls the laptop panel/backlight for headless/tent mode.

Environment overrides:
  BACKLIGHT=$BACKLIGHT
  FB_BLANK=$FB_BLANK
EOF
}

write_sysfs() {
  local value="$1"
  local path="$2"

  if [[ ! -e "$path" ]]; then
    printf 'Warning: %s does not exist; skipping\n' "$path" >&2
    return 0
  fi

  if [[ ${EUID} -eq 0 ]]; then
    printf '%s\n' "$value" >"$path"
  else
    printf '%s\n' "$value" | sudo tee "$path" >/dev/null
  fi
}

screen_off() {
  write_sysfs 4 "$BACKLIGHT/bl_power"
  write_sysfs 0 "$BACKLIGHT/brightness"
  write_sysfs 1 "$FB_BLANK"
  status
}

screen_on() {
  local max_brightness=255

  if [[ -r "$BACKLIGHT/max_brightness" ]]; then
    max_brightness="$(<"$BACKLIGHT/max_brightness")"
  fi

  write_sysfs 0 "$FB_BLANK"
  write_sysfs 0 "$BACKLIGHT/bl_power"
  write_sysfs "$max_brightness" "$BACKLIGHT/brightness"
  status
}

status() {
  printf 'Backlight: %s\n' "$BACKLIGHT"
  for f in bl_power brightness actual_brightness max_brightness; do
    if [[ -r "$BACKLIGHT/$f" ]]; then
      printf '  %s=%s\n' "$f" "$(<"$BACKLIGHT/$f")"
    fi
  done

  if [[ -r "$FB_BLANK" ]]; then
    printf 'Framebuffer blank: %s\n' "$(<"$FB_BLANK")"
  fi
}

case "${1:-}" in
  --off)
    screen_off
    ;;
  --on)
    screen_on
    ;;
  --status)
    status
    ;;
  -h|--help|'')
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
