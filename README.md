# Qtile Desktop Environment

A Qtile desktop environment configuration for an AMD desktop.

This repository lives at `~/.config/qtile`, Qtile's live configuration location.
The Qtile executable and Python environment are installed separately in `/opt/qtile`.
The `install/` directory contains supporting configuration files and setup assets.

The retired ASUS Flow X13 configuration, including tablet mode, auto-rotation,
battery services, and laptop power estimation, is preserved in the annotated Git
tag `archive/asus-flow-x13`. Browse it on GitHub or inspect individual files without
changing the live checkout:

```bash
git show archive/asus-flow-x13:config.py
git ls-tree -r --name-only archive/asus-flow-x13 install/
git show archive/asus-flow-x13:install/auto-rotate/auto-rotate.sh
```

Removing these files does not uninstall previously deployed services or symlinks.
On an older installation, audit those separately before removing obsolete services.

## Installation

**Recommended:** Use the Ansible playbooks in [stonecharioteer/distributed-dotfiles](https://github.com/stonecharioteer/distributed-dotfiles) for automated deployment.

## Manual Setup

Manual installation steps:

```bash
# 1. Install base system packages
sudo apt install python3 python3-venv python3-pip build-essential git curl wget fish

# 2. Create qtile environment
sudo mkdir -p /opt/qtile
sudo chown $USER:$USER /opt/qtile
python3 -m venv /opt/qtile
source /opt/qtile/bin/activate
pip install qtile==0.33.0 psutil

# 3. Install core desktop packages
sudo apt install rofi dunst picom nitrogen feh xclip xorg lightdm \
  network-manager-gnome pavucontrol pasystray blueman copyq jq \
  libnotify-bin cinnamon-screensaver x11-xserver-utils \
  x11-xkb-utils conky-all arandr autorandr

# 4. Install multimedia and hardware packages  
sudo apt install pulseaudio-utils brightnessctl bc xbacklight lm-sensors touchegg

# 5. Install fonts
sudo apt install fontconfig fonts-jetbrains-mono
# Or copy custom fonts: sudo cp -r install/fonts/JetBrainsMono/* /usr/share/fonts/truetype/jetbrainsmono/
# sudo fc-cache -fv

# 6. GPU-specific packages (if applicable)
# Install amdgpu_top for the AMD VRAM widget (must be available on PATH).

# 7. Set up Alacritty (optional - builds from source)
sudo apt install cmake g++ pkg-config libfontconfig1-dev libxcb-xfixes0-dev \
  libxkbcommon-dev gzip scdoc
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# Follow Alacritty build instructions in install/alacritty/

# 8. Create all configuration symlinks
ln -s ~/.config/qtile/install/alacritty ~/.config/alacritty
ln -s ~/.config/qtile/install/conky ~/.config/conky  
ln -s ~/.config/qtile/install/dunst ~/.config/dunst
ln -s ~/.config/qtile/install/monitor-manager ~/.config/monitor-manager
ln -s ~/.config/qtile/install/redshift ~/.config/redshift
ln -s ~/.config/qtile/install/rofi ~/.config/rofi
ln -s ~/.config/qtile/install/touchegg ~/.config/touchegg
ln -s ~/.config/qtile/install/picom.conf ~/.config/picom.conf

# 9. Set up desktop integration
sudo cp ~/.config/qtile/install/qtile.desktop /usr/share/xsessions/
sudo chmod +rx /opt/qtile/bin/qtile /opt/qtile/bin/python*
sudo cp ~/.config/qtile/install/X11/40-libinput-touchpad.conf /etc/X11/xorg.conf.d/

# 10. Enable services
sudo systemctl enable touchegg
sudo systemctl start touchegg
```

## Features

### Desktop Configuration

The active configuration targets the AMD desktop. Laptop-specific features are
preserved in the Git tag above, not loaded or started by the desktop config.

- Core desktop environment (qtile, rofi, picom, dunst)
- Multimedia key bindings and notifications
- Monitor management and multi-screen support
- Touchpad gesture support (including USB trackpads)
- AMD GPU temperature and VRAM monitoring
- Network and system monitoring widgets

### Key Bindings

**System Controls:**
- `Mod + Shift + n` - Notification history (with copy to clipboard)
- `Mod + d` - Application launcher (rofi)
- `Mod + Tab` - Window switcher
- `XF86AudioMute/VolumeUp/VolumeDown` - Audio controls with notifications
- `Mod + Shift + s` - Screenshot tool

**Touchpad Gestures (all systems):**
- **2-finger pinch in/out** → Zoom in/out (Ctrl+Plus/Minus)
- **2-finger swipe right** → Browser back (Alt+Left)  
- **2-finger swipe left** → Browser forward (Alt+Right)

### Troubleshooting

**If something isn't working:**
1. Verify symlinks are created: `ls -la ~/.config/ | grep qtile`
2. Check the configuration: `/opt/qtile/bin/qtile check -c ~/.config/qtile/config.py`
3. Review Qtile logs: `~/.local/share/qtile/qtile.log`

**Manual commands:**
```bash
# Install missing dependencies
sudo apt install jq xclip dunst rofi picom

# Test notification history
~/.config/qtile/install/rofi/notification-history.sh

# Test touchpad gestures
systemctl status touchegg.service
```
