# Laptop Hang RCA Notes

Date: 2026-06-21
Host: `rog-x13-flow`
OS/kernel observed: Linux Mint/Ubuntu stack, `6.8.0-110-generic`

## Incident summary

Laptop was being used as a mostly headless/server machine. It became unreachable: GUI/display was not responsive and SSH was also dead. A hard reboot occurred afterward.

`last -x` showed prior sessions ending with `crash`, indicating the system did not shut down cleanly.

## Initial hypothesis checks

### Battery / charge limit

Battery was capped at 60%:

```text
charge_control_end_threshold=60
capacity≈59
status=Not charging / Discharging
AC0 online=1
```

Battery collector logs showed battery reached ~59% and stayed there. No low-battery/critical-battery evidence was found.

Conclusion: battery charge limit is unlikely to be the direct cause.

### Qtile / user display services

Found user services running from Qtile setup even outside useful GUI context:

- `auto-rotate.service`
- `monitor-manager.service`

They were enabled under user `default.target`, so they could run on user systemd startup / SSH login, not only Qtile login.

Observed repeated failures:

```text
auto-rotate.service: restart counter 900+
monitor-manager.sh: Invalid MIT-MAGIC-COOKIE-1 key
monitor-manager.sh: Can't open display :0
```

These were disabled as persistent user services. Qtile still starts them via `~/.config/qtile/autostart.sh`, so they should run only when Qtile starts.

Conclusion: noisy/misconfigured, but since SSH was dead during the incident, this is probably not the whole root cause.

### GPU / display stack

System has hybrid GPU:

```text
NVIDIA RTX 3050 Ti Laptop GPU
AMD Radeon 680M iGPU
```

Prior logs showed NVIDIA PCIe/AER warnings:

```text
nvidia 0000:01:00.0: PCIe Bus Error: severity=Correctable
BadTLP
RxErr
```

Because this machine is used for CPU/RAM/storage and not GPU, NVIDIA dGPU was disabled through PRIME integrated mode.

Current post-reboot status:

```text
prime-select query => intel
nvidia-smi => fails because NVIDIA driver is not running
```

Note: `prime-select intel` means integrated-GPU mode even though this is an AMD iGPU system.

Conclusion: GPU/display power management or NVIDIA hybrid stack remains a plausible cause, especially because hang happened after display sleep and SSH died.

## Changes made

### User display services

Disabled systemd user services from starting automatically:

```bash
systemctl --user disable --now auto-rotate.service monitor-manager.service
```

`auto-rotate.service` was restored as a file but left disabled. Qtile autostart still runs:

```bash
systemctl --user start auto-rotate.service
~/.config/qtile/install/monitor-manager/monitor-manager.sh &
```

### NVIDIA dGPU disabled

Script created:

```text
./disable-nvidia-dgpu.sh
```

It runs:

```bash
sudo prime-select intel
sudo systemctl disable --now nvidia-persistenced.service
```

A reboot is required after running it.

### Nouveau blacklist fixed

`/etc/modprobe.d/blacklist-nouveau.conf` had stray `EOF` line. Fixed with:

```text
blacklist nouveau
options nouveau modeset=0
```

Script created:

```text
./fix-blacklist-nouveau.sh
```

It also runs:

```bash
sudo update-initramfs -u
```

### Hang monitoring installed

Script created and run:

```text
./setup-hang-monitoring.sh
```

It installed:

```text
/usr/local/sbin/hang-health-snapshot
/etc/systemd/system/hang-health-snapshot.service
/etc/systemd/system/hang-health-snapshot.timer
```

Timer is enabled and logs every minute to:

```text
/var/log/hang-health.log
```

It records:

- uptime/load
- RAM/swap
- disk usage
- AC/battery state
- thermal zones
- `sensors` output
- NVIDIA state if available
- top CPU/memory processes
- recent kernel warnings/errors

Persistent journald storage was enabled via `/var/log/journal`.

SysRq was enabled:

```text
/etc/sysctl.d/99-sysrq.conf
kernel.sysrq = 1
```

## Current healthy baseline after reboot

After clean reboot at ~15:31:

```text
hang-health-snapshot.timer: active
prime-select query: intel
nvidia-smi: NVIDIA driver not running
RAM: ~29 GiB available
Swap: unused
Disk /: ~36% used
NVMe: ~34°C
CPU: ~49-59°C
AC0 online=1
Battery: ~59%, threshold=60
Recent kernel warnings/errors: none
```

Later update after installing `supergfxctl` and switching graphics mode:

```text
supergfxctl -g: Integrated
prime-select query: intel
nvidia-smi: NVIDIA driver not running
/sys/class/backlight/amdgpu_bl1 exists
/sys/class/drm/card1-eDP-1 connected/enabled
```

This fixed the earlier bad display-routing state where LightDM/Xorg was using a simple framebuffer and no real `/sys/class/backlight` device existed. After `sudo supergfxctl -m Integrated` and reboot, the login-screen display timeout worked: the screen/backlight turned off and pressing a laptop key woke it.

Fan/performance controls available through kernel platform profiles:

```text
/sys/firmware/acpi/platform_profile_choices: quiet balanced performance
/sys/firmware/acpi/platform_profile: balanced
```

Useful commands:

```bash
cat /sys/firmware/acpi/platform_profile_choices
cat /sys/firmware/acpi/platform_profile
echo quiet | sudo tee /sys/firmware/acpi/platform_profile
echo balanced | sudo tee /sys/firmware/acpi/platform_profile
echo performance | sudo tee /sys/firmware/acpi/platform_profile
sensors
```

TTY/headless screen-off notes after disabling LightDM:

- Physical console is usually `tty1`; SSH sessions are `pts/*`.
- `setterm --blank/--powerdown` did not reliably blank/power off the laptop panel.
- Kernel consoleblank was already set to `60`, but that did not visibly power off the panel.
- Direct backlight sysfs control works, but may have a delayed visible effect.

Observed working manual screen-off method in text-console/headless mode:

```bash
echo 4 | sudo tee /sys/class/backlight/amdgpu_bl1/bl_power
echo 0 | sudo tee /sys/class/backlight/amdgpu_bl1/brightness
echo 1 | sudo tee /sys/class/graphics/fb0/blank
```

The backlight-only commands set `bl_power=4`, `brightness=0`, and `actual_brightness=0`, but the panel still appeared active. Adding framebuffer blanking via `/sys/class/graphics/fb0/blank` made `--off` visibly work.

Restore from SSH:

```bash
echo 0 | sudo tee /sys/class/graphics/fb0/blank
echo 0 | sudo tee /sys/class/backlight/amdgpu_bl1/bl_power
echo 255 | sudo tee /sys/class/backlight/amdgpu_bl1/brightness
```

Reusable helper added:

```bash
~/.config/qtile/laptop/x13-flow/screen.sh --off
~/.config/qtile/laptop/x13-flow/screen.sh --on
~/.config/qtile/laptop/x13-flow/screen.sh --status
```

State when off should look like:

```text
brightness=0
actual_brightness=0
bl_power=4
fb0 blank=1
```

Unlike LightDM/DPMS, a laptop keypress may not restore this sysfs/framebuffer state; SSH restore with `screen.sh --on` is safest. This works for now for tent/headless mode.

## If it hangs/reboots again

After reboot, collect:

```bash
last -x | head -30
journalctl -b -1 -p warning..alert --no-pager
journalctl -b -1 -k --no-pager | tail -300
tail -500 /var/log/hang-health.log
prime-select query
lsmod | grep '^nvidia' || true
nvidia-smi || true
```

Also check whether the previous shutdown was clean:

```bash
last -x | head
```

Interpretation:

- If `last` says `crash`, previous boot died uncleanly.
- If `/var/log/hang-health.log` stops abruptly without thermal/OOM warnings, suspect kernel/hardware/firmware hang.
- If temps spike before stop, suspect thermal/power.
- If memory/swap exhaustion appears, suspect workload/OOM.
- If NVIDIA modules reappear or GPU/AER messages return, suspect dGPU/hybrid graphics.
- If AC goes offline or battery drains rapidly, suspect charger/EC/power path.

## Next mitigation ideas if hang recurs

1. Disable display manager/GUI entirely when using as server:

```bash
sudo systemctl set-default multi-user.target
sudo systemctl disable --now lightdm
```

2. Disable DPMS/display sleep from Qtile autostart as a test.

3. Add kernel boot params to reduce PCIe power-management issues, e.g. test-only:

```text
pcie_aspm=off
```

4. Check firmware/BIOS updates for ASUS ROG X13 Flow.

5. Consider a newer HWE/OEM kernel if GPU/ACPI hangs continue.
