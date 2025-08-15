# Qtile Ansible Automation

Automated setup for Qtile desktop environment across all your Linux machines.

## Prerequisites

1. **Ansible installed** on your control machine:
   ```bash
   sudo apt install ansible  # Ubuntu/Debian
   # or
   pip install ansible
   ```

2. **SSH access** to target machines (if not running locally)

3. **sudo privileges** on target machines

## Quick Start

1. **Update inventory**: Edit `inventory/hosts.yml` to include your machines:
   ```yaml
   qtile_machines:
     hosts:
       localhost:
         ansible_connection: local
       my-desktop:
         ansible_host: 192.168.1.100
         ansible_user: stonecharioteer
       my-laptop:
         ansible_host: 192.168.1.101  
         ansible_user: stonecharioteer
   ```

2. **Run the playbook**:
   ```bash
   cd ansible/
   ansible-playbook -i inventory/hosts.yml qtile-setup.yml --ask-become-pass
   ```

3. **Log out and select "Qtile"** from your display manager

## What Gets Installed

- **System**: US UTF-8 locale, Python 3, Fish shell (as default)
- **Qtile**: Virtual environment at `/opt/qtile` with qtile and psutil
- **Desktop**: Rofi, Dunst, Picom, Alacritty, system tray apps
- **Fonts**: JetBrainsMono Nerd Fonts (from install/fonts/ or package manager fallback)
- **Hardware**: Conditional laptop features (battery monitoring, touchpad gestures)
- **Services**: Auto-rotation, monitor management, suspend handling

## Customization

- **User account**: Change `qtile_user` in `group_vars/all.yml`
- **Package lists**: Modify distribution-specific packages in `group_vars/all.yml`
- **Target machines**: Add/remove hosts in `inventory/hosts.yml`

## Hardware-Specific Features

- **Laptops**: Battery monitoring, touchpad gestures, auto-rotation
- **Desktops**: Full multi-monitor support, AMD GPU monitoring
- **All**: Multimedia keys, brightness controls, notification system

## Manual Steps After Installation

1. Log out of current session
2. Select "Qtile" from display manager
3. Log in - everything should work automatically!

## Fonts Setup (Optional)

For full Nerd Font icon support:
1. Download JetBrainsMono Nerd Font from [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts/releases)
2. Extract font files to `install/fonts/` directory
3. Re-run the playbook

## Troubleshooting

- **Permission errors**: Make sure you run with `--ask-become-pass`
- **Service failures**: Check logs with `journalctl --user -u service-name`
- **Font icons missing**: Place JetBrainsMono Nerd Font files in install/fonts/ as described above

## Directory Structure

```
ansible/
├── qtile-setup.yml          # Main playbook
├── inventory/hosts.yml      # Machine definitions  
├── group_vars/all.yml       # Global variables
└── roles/                   # Individual installation roles
    ├── locale-setup/        # US UTF-8 locale configuration
    ├── base-system/         # Python, Fish, /opt/qtile setup
    ├── python-environment/  # Qtile venv and packages
    ├── qtile-desktop/       # Core desktop dependencies
    ├── fonts/               # JetBrainsMono installation
    ├── desktop-apps/        # Alacritty and tools
    └── system-integration/  # Config deployment and services
```