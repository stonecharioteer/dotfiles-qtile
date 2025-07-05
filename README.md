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
