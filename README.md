# Qtile Dotfiles

```bash
mkdir -p ~/Pictures/screenshots
sudo apt install rofi
sudo mkdir -p /opt/qtile
sudo chown /opt/qtile stonecharioteer:stonecharioteer
python -m venv /opt/qtile
source /opt/qtile/bin/activate.fish
pip install qtile psutil
ln -s $PWD/install/rofi $HOME/.config/rofi
ln -s $PWD/install/.icons $HOME/.icons
sudo cp install/qtile.desktop /usr/share/xsessions/
sudo chmod a+rx /opt/qtile/bin/qtile /opt/qtile/bin/python
```

## Additional Configuration

### Battery Monitoring (Laptops Only)
Configure battery monitoring to receive notifications when battery is low:

```bash
# Make battery monitor script executable
chmod +x install/battery-monitor.sh

# Add to crontab to run every 10 minutes
crontab -e
# Add this line:
*/10 * * * * /home/stonecharioteer/.config/qtile/install/battery-monitor.sh
```

The script will send notifications when:
- Battery drops below 30% (low battery warning)
- Battery drops below 15% (critical battery warning)

Note: Notifications only appear when the battery is discharging (not while charging).

### Sleep Functionality (Laptops Only)
Configure intelligent laptop suspend that only triggers when using laptop screen alone:

```bash
# Run the setup script to configure system-level settings
./install/setup-sleep-functionality.sh
```

This will:
- Configure systemd-logind to handle lid switch events
- Enable automatic screen locking before suspend
- Set up monitor-aware suspend (prevents suspend when external monitor connected)

**Sleep Behavior:**
- **Lid close with laptop screen only** → suspend + lock screen
- **Lid close with external monitor** → no suspend (notification shown)
- **Wake from suspend** → unlock screen to continue

**Manual Testing:**
```bash
# Test monitor detection
./install/monitor-aware-suspend.sh check

# Test screen locking
./install/suspend-lock.sh lock
```

**Logs:** Check `~/.cache/qtile-suspend.log` for suspend/resume activity debugging.

### Touchpad Gestures (Laptops Only)
Configure Mac-like touchpad gestures for pinch zoom and browser navigation:

```bash
# Run the setup script to configure touchpad gestures
./install/setup-touchpad.sh
```

This will:
- Enable pinch-to-zoom gestures in all applications
- Enable 2-finger horizontal swipe for browser back/forward navigation
- Configure X11 touchpad settings for optimal gesture recognition

**Gesture Functionality:**
- **2-finger pinch in/out** → Zoom in/out (Ctrl+Plus/Minus)
- **2-finger swipe right** → Browser back (Alt+Left)
- **2-finger swipe left** → Browser forward (Alt+Right)

**Important:** You need to restart your X11 session (log out and back in) for touchpad configuration changes to take effect.

**Testing:**
```bash
# Check touchegg service status
systemctl status touchegg.service

# Or check if touchegg daemon is running
pgrep -x touchegg

# Test in a web browser - try pinch gestures and horizontal swipes
```
