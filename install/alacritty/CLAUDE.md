# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About This Repository

This is an Alacritty terminal emulator configuration directory containing:
- `alacritty.toml` - Main configuration file
- `themes/` - Collection of color schemes for Alacritty from the official alacritty-theme repository

## Configuration Structure

The main configuration file (`alacritty.toml`) uses the following structure:
- `[general]` - Contains imports for theme files
- `[window]` - Window settings (opacity, etc.)
- `[font]` - Font configuration (currently using JetBrainsMono NF)

## Theme Management

The themes directory contains:
- `themes/themes/` - Individual theme files in TOML format
- `themes/images/` - Preview images for each theme
- `themes/print_colors.sh` - Script for generating theme screenshots

Currently configured theme: `hatsunemiku.toml`

## Common Operations

### Switching Themes
To change the theme, modify the import path in `alacritty.toml`:
```toml
[general]
import = [
    "~/.config/alacritty/themes/themes/{theme_name}.toml"
]
```

### Font Configuration
Font settings are in the `[font]` section. Current setup uses JetBrainsMono NF with size 8.

### Window Settings
Window opacity and other display settings are configured in the `[window]` section.

## Available Themes

The themes directory includes 100+ color schemes including popular ones like:
- Catppuccin variants (frappe, latte, macchiato, mocha)
- Dracula and Dracula Plus
- Gruvbox (dark/light and material variants)
- Tokyo Night variants
- Nord and Nordic
- Solarized (dark/light)
- GitHub themes
- And many more

## File Locations

- Main config: `alacritty.toml`
- Theme files: `themes/themes/*.toml`
- Theme previews: `themes/images/*.png`
- Theme generator script: `themes/print_colors.sh`

## Development Notes

- You don't need to bother about testing stuff automatically in this folder.