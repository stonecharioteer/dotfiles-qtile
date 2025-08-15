#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALACRITTY_CONFIG_DIR="$HOME/.config/alacritty"

echo "Installing Alacritty configuration..."

# Create alacritty config directory if it doesn't exist
mkdir -p "$ALACRITTY_CONFIG_DIR"

# Symlink the alacritty.toml file
if [[ -f "$ALACRITTY_CONFIG_DIR/alacritty.toml" ]]; then
    echo "Backing up existing alacritty.toml to alacritty.toml.backup"
    mv "$ALACRITTY_CONFIG_DIR/alacritty.toml" "$ALACRITTY_CONFIG_DIR/alacritty.toml.backup"
fi

ln -sf "$SCRIPT_DIR/alacritty.toml" "$ALACRITTY_CONFIG_DIR/alacritty.toml"
echo "Symlinked alacritty.toml"

# Clone the alacritty-theme repository to get themes
THEMES_DIR="$SCRIPT_DIR/themes"

if [[ -d "$THEMES_DIR" ]]; then
    echo "Themes directory already exists, pulling latest changes..."
    cd "$THEMES_DIR"
    git pull
else
    echo "Cloning alacritty-theme repository..."
    git clone https://github.com/alacritty/alacritty-theme.git "$THEMES_DIR"
fi

# Symlink the themes directory
if [[ -L "$ALACRITTY_CONFIG_DIR/themes" ]]; then
    echo "Removing existing themes symlink"
    rm "$ALACRITTY_CONFIG_DIR/themes"
elif [[ -d "$ALACRITTY_CONFIG_DIR/themes" ]]; then
    echo "Backing up existing themes directory to themes.backup"
    mv "$ALACRITTY_CONFIG_DIR/themes" "$ALACRITTY_CONFIG_DIR/themes.backup"
fi

ln -sf "$THEMES_DIR/themes" "$ALACRITTY_CONFIG_DIR/themes"
echo "Symlinked themes directory"

echo "Alacritty configuration installed successfully!"
echo "Configuration: $ALACRITTY_CONFIG_DIR/alacritty.toml -> $SCRIPT_DIR/alacritty.toml"
echo "Themes: $ALACRITTY_CONFIG_DIR/themes -> $THEMES_DIR/themes"