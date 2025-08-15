# Qtile Setup with Ansible

Simple automation to install qtile + my dotfiles on any Linux machine.

## What You Need

1. **On your laptop** (control machine):
   - Ansible: `sudo apt install ansible`
   - SSH access to target machines

2. **On target machines**:
   - SSH server running
   - Your user has sudo privileges
   - Git access to clone from GitHub

## Setup Steps

### 1. Configure Git Access on Target Machines

**Option A: Copy your SSH key (recommended)**
```bash
# From your laptop, copy your SSH key to the target machine
ssh-copy-id username@target-machine-ip

# Then copy your GitHub SSH key
scp ~/.ssh/id_rsa* username@target-machine-ip:~/.ssh/
```

**Option B: Use GitHub CLI**
```bash
# On the target machine, install and setup gh cli
sudo apt install gh
gh auth login
```

### 2. Update Inventory

Edit `inventory/hosts.yml`:
```yaml
qtile_machines:
  hosts:
    my-desktop:
      ansible_host: 192.168.1.100
      ansible_user: stonecharioteer
    my-laptop:
      ansible_host: 192.168.1.101
      ansible_user: stonecharioteer
```

### 3. Run the Playbook

```bash
cd ansible/
ansible-playbook -i inventory/hosts.yml qtile-setup.yml --ask-become-pass
```

Enter your sudo password when prompted.

### 4. Login

Log out and select "Qtile" from your display manager.

## What This Does

- **Safely clones/updates** your dotfiles to `~/.config/qtile` on each machine
- **Installs Fish shell** and sets it as default
- **Builds Alacritty** from source with full desktop integration
- **Sets up qtile** in a Python virtual environment at `/opt/qtile`
- **Installs JetBrainsMono Nerd Fonts** with proper system integration
- **Configures all services** and desktop integration

## Failsafe Behavior

✅ **Safe Operations:**
- If `~/.config/qtile` exists and is the correct repository → updates safely
- If `/opt/qtile` venv exists with qtile installed → skips installation  
- If Alacritty already built → skips compilation
- Preserves local git branches and uncommitted changes

❌ **Will Stop If:**
- `~/.config/qtile` exists but isn't a git repository
- `~/.config/qtile` is a different git repository 
- `/opt/qtile` exists but isn't a valid Python virtual environment
- `~/code/tools/alacritty` exists but isn't the Alacritty repository

The playbook shows you exactly what it finds and what it will do before making changes.

## Testing Locally First

To test on your current machine:
```bash
ansible-playbook -i inventory/hosts.yml qtile-setup.yml --ask-become-pass --limit localhost
```

## Troubleshooting

- **Git clone fails**: Check SSH key setup or GitHub CLI authentication
- **Permission errors**: Make sure your user has sudo privileges
- **Connection fails**: Verify SSH access and machine IPs in inventory