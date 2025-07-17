Don't edit any files unless explicitly asked.

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.

## Qtile Configuration

- This folder contains my qtile config. Testing this isn't straightforward. On my machines, the executable environment will be at /opt/qtile/bin/python3, so if that environment doesn't exist feel free to tell me.

## Architecture Overview

### Core Design Principles
- **Modular, functional architecture** with clear separation of concerns
- **Runtime detection** for dynamic configuration based on system capabilities
- **Conditional functionality** that adapts to available hardware
- **Centralized constants** for colors, images, and configuration values

### Key Functions and Patterns
- **`screen(main=False)`**: Factory function for creating screen configurations with conditional widget placement
- **`count_monitors()`**: Runtime monitor detection using `xrandr`
- **`has_battery()`**: System capability detection for battery-dependent features
- **`sep()`**: Consistent separator widget factory using burgundy color theme

### Widget Organization Strategy
- **Top bar**: Navigation, branding, system tray
- **Bottom bar**: System monitoring, hardware stats, clock
- **Conditional placement**: Main screen gets full features, secondary screens simplified
- **Hardware-dependent widgets**: Battery widget only appears when battery detected

### Hardware Integration
- **AMD GPU monitoring**: Custom `amdgpu_metadata()` and `get_vram_usage()` functions
- **Multi-monitor support**: Dynamic screen creation with `count_monitors()`
- **Thermal monitoring**: CPU and GPU temperature sensors
- **Mouse-aware navigation**: Custom `move_mouse_to_next_monitor()` function

### Styling and Theming
- **Minimal color palette**: Single accent color (`burgandy: #b84d57`)
- **Typography**: JetBrainsMono Nerd Font throughout (18px base, 10px for details)
- **Visual consistency**: 8px margins, 5px bar margins, rounded corners via picom
- **Asset integration**: SVG/PNG icons for branding and system monitoring

### Script Organization in install/
- **Configuration files**: `picom.conf`, `rofi/config.rasi`, `qtile.desktop`
- **Utility scripts**: `battery-monitor.sh`, `redshift/gamma.sh`, `rofi/screenshot.sh`
- **Integration pattern**: Self-contained scripts for system-wide functionality

### Conditional Functionality Patterns
- Hardware detection before enabling features (battery, GPU, monitors)
- Graceful degradation when hardware unavailable
- Runtime reconfiguration support
- Environment-specific feature enablement

## Session Log

### 2025-07-05
- Updated CLAUDE.md with important instruction reminders
- Added session log section for tracking work done during conversations
- Confirmed qtile config location and testing approach with /opt/qtile/bin/python3
- **CRITICAL**: Never write to config.py without explicit user permission
- Added battery detection functionality to config.py:
  - Created has_battery() function that checks /sys/class/power_supply/BAT* 
  - Modified screen() function to conditionally show battery widget on laptops
  - Battery widget shows percentage, charge/discharge status, and low battery warning
- Created battery-monitor.sh script in install/ directory:
  - Monitors battery level and sends dunst notifications when below 30%
  - Additional critical warning at 15% battery
  - Made executable and ready for crontab
  - Add to crontab: */10 * * * * /home/stonecharioteer/.config/qtile/install/battery-monitor.sh
- Updated README.md with battery monitoring setup instructions
- Changed battery widget format to show icon before percentage: "{char} {percent:2.0%}"
- Updated battery widget icons: ⚡ for charging, 🔌 for discharging
- Changed battery widget low_percentage from 0.2 to 0.3 to align with battery monitor script
- Added midnight background (#1e2030) to bars and light blue background (#8fafc7) for systray to provide better contrast against black icons while complementing the color scheme

### 2025-07-17
- Implemented intelligent laptop sleep functionality:
  - Created `monitor-aware-suspend.sh` script that prevents suspend when external monitors are connected
  - Added `suspend-lock.sh` script for screen locking before suspend and post-suspend actions
  - Created systemd user services `lock-on-suspend.service` and `unlock-on-resume.service`
  - Updated `autostart.sh` to enable suspend services automatically
  - Sleep behavior: lid close → suspend only when using laptop screen alone, continue working when external monitor connected
  - Automatic screen lock using cinnamon-screensaver before suspend
  - Logging to ~/.cache/qtile-suspend.log for debugging

### Refactoring and Homogenization
- I'd like to homogenize things across scripts, so if something seems common between scripts and config.py, ensure that it is maintained so

### Sleep Functionality Setup
To enable the sleep functionality, you need to create the system-level logind configuration:

```bash
# Create system logind configuration (requires sudo)
sudo mkdir -p /etc/systemd/logind.conf.d
sudo tee /etc/systemd/logind.conf.d/lid-suspend.conf << 'EOF'
[Login]
HandleLidSwitch=suspend
HandleLidSwitchDocked=ignore
HandleLidSwitchExternalPower=suspend
EOF

# Restart logind to apply changes
sudo systemctl restart systemd-logind
```

The user-level services are automatically enabled via autostart.sh on qtile startup.

### 2025-07-17 (Session 2)
- Implemented Mac-like touchpad gestures:
  - Created `install/touchegg.conf` with pinch zoom and horizontal swipe gestures
  - 2-finger pinch in/out → Ctrl+Plus/Minus for zoom functionality
  - 2-finger horizontal swipe → Alt+Left/Right for browser navigation
  - Created `install/40-libinput-touchpad.conf` for X11 touchpad settings
  - Maintained existing scroll direction, only focused on requested gestures
  - Created `install/setup-touchpad.sh` script for automated installation
  - Updated `autostart.sh` to start touchegg service automatically
  - Updated `README.md` with touchpad setup instructions
  - All configuration files stored in ./install/ for easy reinstallation