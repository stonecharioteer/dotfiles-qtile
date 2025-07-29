#!/bin/bash

# Get the absolute path of the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Symlink the conky directory
ln -sf "$SCRIPT_DIR/conky" ~/.config/conky

echo "Conky configuration has been set up successfully!"
