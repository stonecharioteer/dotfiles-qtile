Don't edit any files unless explicitly asked.

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.

## Qtile Configuration

- This folder contains my qtile config. Testing this isn't straightforward. On my machines, the executable environment will be at /opt/qtile/bin/python3, so if that environment doesn't exist feel free to tell me.
- **Automated deployment**: Use the Ansible playbook in `ansible/` directory for complete setup across multiple machines
- **Repository cloning**: Playbook automatically clones this repository to `~/.config/qtile` on target machines

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
- **`has_asus_keyboard()`**: Laptop detection for tablet mode functionality
- **`multimedia_cmd()`**: Helper function for multimedia commands with notifications
- **`get_power_draw()`**: Comprehensive power monitoring using UPower, component estimation, and PowerTOP
- **`get_hostname()`**: System hostname display for multi-machine identification
- **`get_ip_address()`**: Network interface and IP address detection
- **`sep()`**: Consistent separator widget factory using burgundy color theme
- **`TabletModeToggle`**: Class for managing keyboard/touchpad disable functionality

### Widget Organization Strategy
- **Top bar**: Navigation, branding, system tray, tablet mode toggle (laptops)
- **Bottom bar**: System monitoring, hardware stats, power monitoring, networking, clock
- **Conditional placement**: Main screen gets full features, secondary screens simplified
- **Hardware-dependent widgets**: Battery widget, power monitoring, hostname/IP on main screen only

### Hardware Integration
- **AMD GPU monitoring**: Custom `amdgpu_metadata()` and `get_vram_usage()` functions
- **NVIDIA GPU monitoring**: Power consumption via nvidia-smi integration
- **Power monitoring**: Multi-method approach using UPower, component estimation, and PowerTOP
- **Multi-monitor support**: Dynamic screen creation with `count_monitors()`
- **Thermal monitoring**: CPU and GPU temperature sensors
- **Mouse-aware navigation**: Custom `move_mouse_to_next_monitor()` function
- **Network monitoring**: Real-time IP address and interface detection

### Styling and Theming
- **Minimal color palette**: Single accent color (`burgandy: #b84d57`)
- **Typography**: JetBrainsMono Nerd Font throughout (18px base, 10px for details)
- **Visual consistency**: 8px margins, 5px bar margins, rounded corners via picom
- **Asset integration**: SVG/PNG icons for branding and system monitoring

### Script Organization in install/
- **Configuration files**: `picom.conf`, `rofi/config.rasi`, `qtile.desktop`
- **Utility scripts**: `battery-monitor.sh`, `redshift/gamma.sh`, `rofi/screenshot.sh`
- **Auto-rotation system**: `auto-rotate/auto-rotate.sh`, `auto-rotate.service`, `reset-touch.sh`
- **Setup scripts**: `setup-brightness-permissions.sh`, `setup-touchpad.sh`
- **Font assets**: `fonts/JetBrainsMono/` directory with complete Nerd Font collection
- **Integration pattern**: Self-contained scripts for system-wide functionality

### Ansible Automation in ansible/
- **Complete deployment**: `qtile-setup.yml` main playbook with 7 specialized roles
- **Role structure**: locale-setup, base-system, python-environment, qtile-desktop, fonts, desktop-apps, system-integration
- **Remote deployment**: Clones repository and sets up environment on target machines
- **Alacritty build**: Source compilation with full desktop integration at `~/code/tools/alacritty`
- **Inventory management**: `inventory/hosts.yml` for multi-machine deployment

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

### 2025-08-01
- Implemented comprehensive multimedia key support:
  - Added `multimedia_cmd()` helper function for consistent command execution and notifications
  - Implemented audio controls: XF86AudioMute, XF86AudioLowerVolume, XF86AudioRaiseVolume
  - Added microphone mute support: F20 key binding for pactl source mute toggle
  - Created brightness controls for screen (nvidia_0) and keyboard backlight (asus::kbd_backlight)
  - Added launcher shortcuts: XF86Launch3 (rofi drun), XF86Launch4 (rofi window)
  - Implemented progress bar notifications using dunstify with notification ID 9991
  - Prevents notification spam by updating single notification for volume changes
  - Enhanced UX with proper status messages: "Muted/Unmuted" instead of "yes/no"
  - Created `install/setup-brightness-permissions.sh` for udev rules and permissions
  - All multimedia keys provide visual feedback with appropriate emoji icons
- Enhanced tablet mode integration:
  - Added laptop screen rotation detection and touch input transformation
  - Implemented manual tablet mode toggle button in qtile top bar (💻/📱)
  - Created auto-rotation service with systemd integration
  - Support for touchscreen, stylus, and touchpad rotation matrices
  - Tablet mode disables keyboard/touchpad, enables touch-only interaction

### 2025-08-15
- Implemented comprehensive Ansible automation for qtile deployment:
  - Created complete Ansible playbook structure with 7 specialized roles
  - Locale-first setup ensuring US UTF-8 across all systems 
  - Automated Python environment creation at `/opt/qtile` with qtile + psutil
  - Fish shell configuration as default for stonecharioteer user
  - Full Alacritty build from source with desktop integration at `~/code/tools/alacritty`
  - Rust toolchain installation for Alacritty compilation
  - JetBrainsMono Nerd Fonts installation from `install/fonts/` directory
  - Complete qtile configuration deployment via GitHub repository cloning
  - Hardware-specific features (battery monitoring, touchpad gestures, auto-rotation)
  - Systemd services, cron jobs, and permissions automation
  - Power monitoring dependencies (upower, powertop, nvidia-smi)
- Remote deployment capability:
  - Playbook clones `stonecharioteer/dotfiles-qtile` directly to `~/.config/qtile` on target machines
  - SSH key or GitHub CLI authentication options
  - No manual file copying required - everything fetched from GitHub
  - Support for multiple machine deployment via Ansible inventory
  - Simple README with minimal setup requirements

## Gameplan / Todo Items

### Multimedia Key Improvements
- [ ] **Fix existing multimedia button support** - Address any issues with current audio/brightness key bindings
- [ ] **Add fan speed curve cycling** - Detect and bind laptop fan speed control buttons to cycle through performance profiles
- [ ] **Enhanced keyboard backlight controls** - Implement dedicated keyboard backlight up/down buttons (separate from existing brightness controls)

### Notification System Enhancements
- [ ] **Dynamic dunst notification scaling** - Implement screen-size aware notification scaling that works properly on both laptop and desktop displays
  - Detect screen resolution/DPI and adjust notification font size accordingly
  - Ensure notifications are appropriately sized for different screen sizes
  - Consider using xrandr or similar for runtime display detection

### Hardware Integration
- [ ] **ASUS ROG laptop-specific controls** - Research and implement laptop-specific function key mappings
- [ ] **Performance profile integration** - Connect fan curves to system performance modes if available
- [ ] **Advanced power management** - Integrate fan controls with existing battery monitoring system
- always use ssh based cloning in ansible playbooks for github