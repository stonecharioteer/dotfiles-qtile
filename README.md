# Qtile Desktop Environment

A comprehensive qtile desktop environment configuration.

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
  libnotify-bin cinnamon-screensaver x11-xserver-utils xinput \
  x11-xkb-utils upower powertop conky-all arandr autorandr

# 4. Install multimedia and hardware packages  
sudo apt install pulseaudio-utils brightnessctl bc xbacklight lm-sensors touchegg

# 5. Install fonts
sudo apt install fontconfig fonts-jetbrains-mono
# Or copy custom fonts: sudo cp -r install/fonts/JetBrainsMono/* /usr/share/fonts/truetype/jetbrainsmono/
# sudo fc-cache -fv

# 6. GPU-specific packages (if applicable)
# For NVIDIA: sudo apt install nvidia-utils-535
# For AMD: sudo apt install radeontop

# 7. Set up Alacritty (optional - builds from source)
sudo apt install cmake g++ pkg-config libfontconfig1-dev libxcb-xfixes0-dev \
  libxkbcommon-dev gzip scdoc
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# Follow Alacritty build instructions in install/alacritty/

# 8. Create all configuration symlinks
ln -s ~/.config/qtile/install/alacritty ~/.config/alacritty
ln -s ~/.config/qtile/install/auto-rotate ~/.config/auto-rotate
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
# For laptops only: copy and enable suspend/auto-rotation services
```

## Features

### Hardware-Aware Configuration
The configuration automatically detects your system type and enables appropriate features:

**All Systems:**
- Core desktop environment (qtile, rofi, picom, dunst)
- Multimedia key bindings and notifications
- Monitor management and multi-screen support
- Touchpad gesture support (including USB trackpads)
- GPU monitoring (NVIDIA/AMD detection)
- Network and system monitoring widgets

**Laptop-Specific Features:**
- Battery monitoring with notifications
- Intelligent suspend (only when using laptop screen alone)
- Auto-rotation for tablet mode
- Power consumption monitoring
- Keyboard/touchpad disable in tablet mode

**Desktop-Specific Features:**
- No battery/suspend services
- Optimized for external peripherals
- Enhanced multi-monitor support

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
2. Check service status: `systemctl --user status auto-rotate.service` (laptops only)
3. Review logs: `~/.cache/qtile-suspend.log`, `journalctl --user -u auto-rotate.service`

**Manual commands:**
```bash
# Install missing dependencies
sudo apt install jq xclip dunst rofi picom

# Test notification history
~/.config/qtile/install/rofi/notification-history.sh

# Test touchpad gestures
systemctl status touchegg.service
```
