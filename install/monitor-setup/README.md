# Dual 4K Monitor Setup for USB-C Dock

This directory contains scripts and documentation for setting up dual 4K monitors through a USB-C dock with mixed DisplayPort and HDMI connections.

## Problem

When connecting two 4K monitors to a USB-C dock using different cable types (DisplayPort + HDMI), the system often fails to properly detect monitor capabilities, resulting in:

- Monitors falling back to basic VGA modes (640x480)
- Missing EDID data (0mm x 0mm display size)
- CRTC configuration failures when trying to set high resolutions
- USB-C dock bandwidth limitations preventing dual high-refresh displays

## Solution

The solution involves manually creating display modes and working around bandwidth limitations:

1. **DisplayPort monitor**: Full 2560x1440 @ 60Hz
2. **HDMI monitor**: 2560x1440 @ 30Hz (reduced refresh rate for bandwidth)

## Hardware Configuration

- **Primary laptop screen**: DP-0 (unchanged)
- **External monitor 1**: DisplayPort cable → DisplayPort-2-8 
- **External monitor 2**: HDMI cable → DisplayPort-2-9 (via USB-C dock)

## Usage

### Automatic Setup

Run the setup script:

```bash
./install/monitor-setup/dual-4k-monitors.sh
```

This script will:
- Clean any existing custom display modes
- Create 1440p modes at 60Hz and 30Hz
- Configure DisplayPort monitor at full 60Hz
- Configure HDMI monitor at bandwidth-limited 30Hz
- Verify the final configuration

### Manual Commands

If you need to set this up manually or troubleshoot:

```bash
# Create display modes
xrandr --newmode "2560x1440_60.00" 312.25 2560 2752 3024 3488 1440 1443 1448 1493 -hsync +vsync
xrandr --newmode "2560x1440_30.00" 146.25 2560 2680 2944 3328 1440 1443 1448 1468 -hsync +vsync

# Add modes to monitors
xrandr --addmode DisplayPort-2-8 "2560x1440_60.00"
xrandr --addmode DisplayPort-2-9 "2560x1440_30.00"

# Apply configuration
xrandr --output DisplayPort-2-8 --mode "2560x1440_60.00" --pos 1920x0
xrandr --output DisplayPort-2-9 --mode "2560x1440_30.00" --pos 4480x0
```

### Verification

Check your setup:

```bash
xrandr --listmonitors
```

Expected output:
```
Monitors: 3
 0: +*DP-0 1920/288x1200/180+0+0  DP-0
 1: +DisplayPort-2-8 2560/677x1440/381+1920+0  DisplayPort-2-8
 2: +DisplayPort-2-9 2560/677x1440/381+4480+0  DisplayPort-2-9
```

## Troubleshooting

### Monitor Not Detected

If a monitor isn't showing up:

1. Check physical connections
2. Try unplugging and reconnecting the USB-C dock
3. Force PCI bus rescan (requires sudo):
   ```bash
   echo 1 > /sys/bus/pci/rescan
   ```

### CRTC Configuration Failures

If you get "Configure crtc X failed" errors:

- This usually indicates bandwidth limitations
- Try lower refresh rates (30Hz instead of 60Hz)
- Ensure only necessary monitors are enabled
- Check that you're not exceeding your GPU's display output limits

### EDID Issues

If monitors show "0mm x 0mm":

- EDID data isn't being read properly through the dock
- This is why we manually create display modes
- The script works around this by forcing specific resolutions

## Hardware Limitations

### USB-C Dock Bandwidth

Most USB-C docks have bandwidth limitations that prevent:
- Dual 4K @ 60Hz displays
- High refresh rates on multiple displays
- Full DisplayPort bandwidth on HDMI-converted outputs

### Refresh Rate Compromise

The 30Hz refresh rate on the HDMI monitor is necessary because:
- USB-C docks convert HDMI to DisplayPort protocol
- Limited bandwidth requires lower refresh rates for high resolutions
- 30Hz is sufficient for productivity work but may feel sluggish for gaming/video

## Upgrading

For full 60Hz on both monitors, consider:

1. **Dual DisplayPort cables**: Use DP cables for both monitors if dock supports it
2. **Higher bandwidth dock**: Thunderbolt 4 docks with more bandwidth
3. **Direct GPU connection**: Connect one monitor directly to laptop if possible
4. **Lower resolution**: Run both at 1920x1080 @ 60Hz instead

## Integration with Qtile

This setup integrates with the qtile configuration's `count_monitors()` function, which automatically detects the three-monitor setup and configures widgets appropriately.

The monitors will be arranged as:
```
[Laptop Screen] [DisplayPort Monitor] [HDMI Monitor]
     DP-0         DisplayPort-2-8      DisplayPort-2-9
   1920x1200        2560x1440           2560x1440
     60Hz             60Hz                30Hz
```