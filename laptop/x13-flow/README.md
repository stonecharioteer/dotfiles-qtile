# ROG X13 Flow laptop/server notes

Utilities and notes for running the ASUS ROG X13 Flow as a mostly headless CPU/RAM/storage server.

These scripts are intentionally kept here rather than in `/tmp`/scratch so the setup can be reapplied or audited later.

## Why this exists

The laptop previously hard-hung: display was dead and SSH was unreachable. Battery charge limit was investigated and looked unlikely. The remaining suspects were graphics/display power management and the hybrid AMD+iGPU/NVIDIA stack.

This folder contains:

- mitigations to reduce GPU/display risk
- monitoring to preserve useful evidence if the machine hangs again
- RCA notes for future investigation

## Recommended install/run order

From this directory:

```bash
cd ~/.config/qtile/laptop/x13-flow
./fix-blacklist-nouveau.sh
./disable-nvidia-dgpu.sh
./setup-hang-monitoring.sh
./enable-lightdm-display-sleep.sh
```

Then reboot when convenient:

```bash
sudo reboot
```

`enable-lightdm-display-sleep.sh` can also be applied without reboot by restarting LightDM, but this kills any GUI session:

```bash
sudo systemctl restart lightdm
```

## Files

### `laptop-hang-rca.md`

RCA notes for the hard hang where SSH died.

Use it when reinvestigating a future reboot/hang. It includes:

- symptoms observed
- hypotheses checked
- evidence collected
- changes applied
- commands to collect logs after the next incident

No install step; it is documentation only.

### `setup-hang-monitoring.sh`

Installs a systemd timer that writes one health snapshot per minute to:

```text
/var/log/hang-health.log
```

Why needed: if the system hard-hangs, interactive debugging is impossible. This gives us the last known state before the freeze.

It records:

- uptime/load
- memory/swap
- disk usage
- AC/battery state
- thermal zones
- `sensors` output
- NVIDIA state if available
- top CPU/memory processes
- recent kernel warnings/errors

Install/run:

```bash
./setup-hang-monitoring.sh
```

Verify:

```bash
systemctl status hang-health-snapshot.timer
 tail -120 /var/log/hang-health.log
```

### `disable-nvidia-dgpu.sh`

Switches PRIME to integrated-GPU mode and disables NVIDIA persistence daemon.

Why needed: the machine is being used for CPU/RAM/storage, not GPU. Disabling the NVIDIA dGPU reduces power use and removes one likely source of graphics/PCIe hangs.

On this AMD+iGPU/NVIDIA laptop, `prime-select intel` means “integrated GPU mode”, despite the name.

Run:

```bash
./disable-nvidia-dgpu.sh
```

Reboot afterward for full effect.

Verify after reboot:

```bash
prime-select query
lsmod | grep '^nvidia' || true
nvidia-smi || true
```

Expected state for server use:

- `prime-select query` returns `intel`
- no NVIDIA modules are loaded
- `nvidia-smi` fails because the NVIDIA driver is not running

### `fix-blacklist-nouveau.sh`

Fixes `/etc/modprobe.d/blacklist-nouveau.conf` by removing a stray `EOF` line and rebuilding initramfs.

Why needed: the malformed file caused modprobe warnings. It is not the main hang suspect, but it should be clean before diagnosing GPU issues.

Run:

```bash
./fix-blacklist-nouveau.sh
```

Verify:

```bash
cat /etc/modprobe.d/blacklist-nouveau.conf
```

Expected contents:

```text
blacklist nouveau
options nouveau modeset=0
```

### `enable-lightdm-display-sleep.sh`

Configures LightDM's login screen to blank/power off the display using DPMS.

Why needed: Qtile already sets display sleep after login, but the Linux Mint login screen did not. In tent/headless mode the panel should not stay on indefinitely.

This is display-only sleep. It does **not** suspend the machine. SSH and services should continue running.

Timings:

- blank after 5 min
- DPMS standby after 5 min
- suspend display after 10 min
- display off after 15 min

Run:

```bash
./enable-lightdm-display-sleep.sh
```

Apply via reboot, or immediately with:

```bash
sudo systemctl restart lightdm
```

Restarting LightDM kills the active GUI session, so do that only from SSH/TTY.

## Current desired baseline

For server-style use, desired state is:

```bash
prime-select query             # intel
lsmod | grep '^nvidia'         # no output
systemctl status hang-health-snapshot.timer
```

Battery at the configured charge limit is expected to show something like:

```text
AC0 online=1
BAT0 capacity≈59
BAT0 charge_control_end_threshold=60
BAT0 status=Not charging
```

## Quick health checks

```bash
uptime
last -x | head
tail -120 /var/log/hang-health.log
journalctl -b -p warning..alert --no-pager | tail -100
prime-select query
lsmod | grep '^nvidia' || true
```

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

Interpretation hints:

- `last` showing `crash` means the previous boot ended uncleanly.
- `hang-health.log` ending abruptly with normal temps/memory suggests kernel/firmware/hardware hang.
- Thermal spike suggests cooling/power profile issue.
- Swap/memory exhaustion suggests workload/OOM.
- NVIDIA modules or AER/PCIe GPU warnings returning suggests dGPU/hybrid graphics is still involved.
