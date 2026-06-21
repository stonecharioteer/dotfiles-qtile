#!/usr/bin/env bash
set -euo pipefail

# Install ASUS Linux graphics tooling on Linux Mint 22.x.
#
# The old ASUS Linux OBS apt repo does not currently publish xUbuntu_24.04
# packages, so this installs supergfxctl from upstream source instead.
# asusctl is optional because it is heavier and not required just to switch
# hybrid graphics mode.
#
# Usage:
#   ./install-asus-linux-tools.sh
#   INSTALL_ASUSCTL=1 ./install-asus-linux-tools.sh   # optional/heavier

SRC_ROOT="${SRC_ROOT:-$HOME/.local/src/asus-linux}"
INSTALL_ASUSCTL="${INSTALL_ASUSCTL:-0}"

printf 'Cleaning any failed ASUS Linux OBS apt repo entries...\n'
sudo rm -f /etc/apt/sources.list.d/asus-linux.list /etc/apt/trusted.gpg.d/asus-linux.gpg

printf 'Installing build prerequisites...\n'
sudo apt update
sudo apt install -y git curl build-essential pkg-config make libudev-dev

if ! command -v cargo >/dev/null 2>&1 || ! command -v rustc >/dev/null 2>&1; then
  printf '\nRust/cargo not found. Install Rust first, then rerun this script:\n'
  printf '  curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh\n'
  printf '  source ~/.cargo/env\n'
  exit 1
fi

mkdir -p "$SRC_ROOT"

printf '\nInstalling supergfxctl from source...\n'
if [ -d "$SRC_ROOT/supergfxctl/.git" ]; then
  git -C "$SRC_ROOT/supergfxctl" pull --ff-only
else
  git clone https://gitlab.com/asus-linux/supergfxctl.git "$SRC_ROOT/supergfxctl"
fi

make -C "$SRC_ROOT/supergfxctl"
sudo make -C "$SRC_ROOT/supergfxctl" install
sudo systemctl daemon-reload
sudo systemctl enable --now supergfxd

if [ "$INSTALL_ASUSCTL" = "1" ]; then
  printf '\nInstalling optional asusctl/asusd from source...\n'
  sudo apt install -y libclang-dev libudev-dev libfontconfig-dev cmake libxkbcommon-dev

  if [ -d "$SRC_ROOT/asusctl/.git" ]; then
    git -C "$SRC_ROOT/asusctl" pull --ff-only
  else
    git clone https://gitlab.com/asus-linux/asusctl.git "$SRC_ROOT/asusctl"
  fi

  make -C "$SRC_ROOT/asusctl"
  sudo make -C "$SRC_ROOT/asusctl" install
  sudo systemctl daemon-reload
  sudo systemctl enable --now asusd
else
  printf '\nSkipping asusctl/asusd. Set INSTALL_ASUSCTL=1 to build it too.\n'
fi

printf '\nInstalled status:\n'
systemctl --no-pager --full status supergfxd 2>/dev/null | sed -n '1,60p' || true
if [ "$INSTALL_ASUSCTL" = "1" ]; then
  systemctl --no-pager --full status asusd 2>/dev/null | sed -n '1,60p' || true
fi

printf '\nGraphics mode:\n'
supergfxctl -g || true

printf '\nUseful commands:\n'
printf '  supergfxctl -g                  # get current graphics mode\n'
printf '  sudo supergfxctl -m Integrated  # switch to integrated-only mode\n'
printf '  sudo supergfxctl -m Hybrid      # switch back to hybrid\n'
printf '  supergfxctl --help\n'
printf '\nReboot after changing graphics mode.\n'
