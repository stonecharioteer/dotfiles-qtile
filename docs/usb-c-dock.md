# USB-C Dock and Dual Monitor Setup Journey

This document chronicles the process of setting up dual 4K monitors through a USB-C dock, the challenges encountered, and the solutions found.

## Hardware Setup

- **Laptop**: Internal display (DP-0) - 1920x1200
- **USB-C Dock**: Supports mixed DisplayPort and USB-C connections
- **Monitor 1**: 4K monitor via DisplayPort cable → DisplayPort-2-8
- **Monitor 2**: 4K monitor via USB-C cable → DisplayPort-2-9

## The Problem

When initially connecting two 4K monitors to the USB-C dock, several issues emerged:

### Initial HDMI Connection Issues

**Problem**: Second monitor connected via HDMI cable through dock
- Monitors detected with wrong resolutions (640x480 fallback)
- Missing EDID data (0mm x 0mm display dimensions)
- CRTC configuration failures when attempting high resolutions
- USB-C dock bandwidth limitations

**Root Cause**: HDMI over USB-C introduces bandwidth constraints that prevent dual high-refresh displays.

### Technical Details

```bash
# Initial problematic state
DisplayPort-2-8 connected 640x480+1920+0 (normal left inverted right x axis y axis) 0mm x 0mm
DisplayPort-2-9 connected 640x480+2978+640 (normal left inverted right x axis y axis) 0mm x 0mm
```

**EDID Detection Failure**: Both monitors showed 0 bytes EDID data:
```bash
Found connector: card1-DP-9
Current status: connected
EDID size: 0 bytes
```

## The Solution Evolution

### Phase 1: Manual Mode Creation + Bandwidth Management

**Approach**: Create custom display modes and work around bandwidth limitations

```bash
# Created custom 1440p modes
cvt 2560 1440 60  # Full refresh rate
cvt 2560 1440 30  # Reduced refresh rate for bandwidth

# Applied configuration
DisplayPort-2-8: 2560x1440 @ 60Hz (DisplayPort cable)
DisplayPort-2-9: 2560x1440 @ 30Hz (HDMI cable via dock)
```

**Result**: Working dual 1440p setup with refresh rate compromise on HDMI monitor.

### Phase 2: USB-C Connection Upgrade

**Key Insight**: The dock supported one USB-C display connection with better bandwidth allocation.

**Action**: Replaced HDMI cable with USB-C cable for second monitor.

**Immediate Improvements**:
1. **EDID Detection Restored**: Monitor now properly identified
   ```bash
   # Before (HDMI)
   DisplayPort-2-9 connected 2560x1440+4480+0 (...) 0mm x 0mm
   
   # After (USB-C)
   DisplayPort-2-9 connected 2560x1440+4480+0 (...) 597mm x 337mm
   ```

2. **Native Mode Support**: Full range of resolutions available
   ```bash
   DisplayPort-2-9 connected 2560x1440+4480+0 (normal left inverted right x axis y axis) 597mm x 337mm
      3840x2160     60.00 +  50.00    30.00    29.97  
      2560x1440     59.95  
      1920x1080     60.00    50.00    59.94    30.00    25.00    24.00    29.97    23.98
   ```

3. **Full Refresh Rate**: Both monitors now at ~60Hz
   ```bash
   xrandr --output DisplayPort-2-9 --mode "2560x1440" --rate 59.95
   ```

## Final Working Configuration

```
[Laptop Screen] [DisplayPort Monitor] [USB-C Monitor]
     DP-0         DisplayPort-2-8      DisplayPort-2-9
   1920x1200        2560x1440           2560x1440
     120Hz            60.00Hz             59.95Hz
```

Both external monitors now run at their full refresh rates with proper EDID detection.

### Phase 3: Performance Issues and Hybrid Graphics Conflicts

**Problem Discovered**: After achieving dual 60Hz setup, severe stuttering and frame lag appeared:
- Mouse movement was noticeably jerky with visible lag
- Terminal applications like `cmatrix` exhibited pausing/stuttering 
- Web scrolling was laggy despite proper refresh rates
- Issues persisted even without compositor (picom disabled)

**Root Cause Investigation**: Systematic troubleshooting ruled out:
- ✅ Compositor (picom) - stuttering persisted without compositor
- ✅ Individual monitor issues - problem occurred with single monitor
- ✅ USB-C dock timing - issue existed with DisplayPort-only setup
- ✅ NVIDIA driver settings - ForceCompositionPipeline, power modes had no effect
- ✅ CPU governor - performance mode didn't resolve stuttering

**Hardware Discovery**: System analysis revealed hybrid graphics configuration:
```bash
lspci | grep -E "(VGA|3D|Display)"
01:00.0 VGA compatible controller: NVIDIA Corporation GA107M [GeForce RTX 3050 Ti Mobile] (rev a1)
08:00.0 VGA compatible controller: Advanced Micro Devices, Inc. [AMD/ATI] Rembrandt [Radeon 680M] (rev 01)
```

**GPU Switching Conflict**: Prime GPU selection was set to `on-demand` mode:
```bash
prime-select query
on-demand
```

This caused **dynamic switching between AMD iGPU and NVIDIA dGPU**, resulting in:
- Frame synchronization conflicts between different graphics drivers
- GPU handoff delays causing micro-stutters
- Inconsistent frame timing across display pipeline

**Solution**: Force dedicated NVIDIA GPU mode:
```bash
sudo prime-select nvidia
# Requires reboot to take effect
```

**Result**: Complete elimination of stuttering and lag after reboot with consistent NVIDIA-only rendering.

**Important Note**: After switching to NVIDIA-only mode, display enumeration changes from `DisplayPort-2-x` to `DisplayPort-1-x`, requiring monitor setup scripts to be re-run with the new identifiers.

## Key Learnings

### USB-C vs HDMI Through Dock

| Connection Type | EDID Support | Max Resolution | Max Refresh | Bandwidth |
|----------------|-------------|----------------|-------------|-----------|
| HDMI via dock  | ❌ Failed   | 2560x1440     | 30Hz        | Limited   |
| USB-C via dock | ✅ Full     | 3840x2160     | 60Hz        | Full      |
| DisplayPort    | ✅ Full     | 2560x1440     | 60Hz        | Full      |

### Technical Insights

1. **EDID Dependency**: Without proper EDID data, monitors fall back to basic VGA modes
2. **Bandwidth Hierarchy**: USB-C > DisplayPort > HDMI when routed through docks
3. **CRTC Limitations**: GPU display controllers have finite bandwidth that must be managed
4. **Dock Architecture**: Mixed connections can work but USB-C provides best compatibility
5. **Hybrid Graphics Issues**: Laptops with dual GPUs (AMD iGPU + NVIDIA dGPU) can cause severe frame timing issues when in `on-demand` switching mode
6. **Performance vs Power Trade-off**: Forcing dedicated GPU mode eliminates stuttering but reduces battery life
7. **Display Enumeration Behavior**: Linux DRM subsystem assigns display names based on GPU hierarchy - primary GPU gets `DisplayPort-1-x`, secondary gets `DisplayPort-2-x`. Changing `prime-select` mode reorders GPU priority, causing display names to change even though physical connections remain the same. This is standard Linux behavior, not a bug.

## Troubleshooting Commands

### Detection and Diagnosis
```bash
# Check monitor detection
xrandr --listmonitors

# Verify EDID data
sudo find /sys/class/drm -name "edid" -exec wc -c {} + | grep -v " 0 "

# Force hardware re-detection
sudo echo 1 > /sys/bus/pci/rescan
```

### Manual Mode Creation
```bash
# Generate mode timings
cvt 2560 1440 60

# Create and apply custom modes
xrandr --newmode "2560x1440_60.00" [timing parameters]
xrandr --addmode DisplayPort-2-9 "2560x1440_60.00"
xrandr --output DisplayPort-2-9 --mode "2560x1440_60.00"
```

### Refresh Rate Verification
```bash
# Check current modes and refresh rates
xrandr --verbose | grep -E "(DisplayPort.*connected|clock.*Hz)"
```

### Hybrid Graphics Troubleshooting
```bash
# Check for dual GPU setup
lspci | grep -E "(VGA|3D|Display)"

# Check current GPU selection mode
prime-select query

# Check which GPU is handling OpenGL
glxinfo | grep -E "(OpenGL renderer|OpenGL vendor)"

# Force NVIDIA mode (requires reboot)
sudo prime-select nvidia

# Force AMD/Intel mode (requires reboot) 
sudo prime-select intel

# Test for stuttering
cmatrix  # Should flow smoothly without pauses
```

## Recommendations for USB-C Dock Users

### Connection Priority
1. **Primary monitor**: DisplayPort cable (most reliable)
2. **Secondary monitor**: USB-C cable (better than HDMI through dock)
3. **Avoid**: HDMI through dock for high-resolution displays

### Dock Selection Criteria
- **Thunderbolt 4**: Highest bandwidth for dual 4K @ 60Hz
- **USB-C 3.2**: Good for mixed resolutions/refresh rates
- **USB-C 3.1**: May require refresh rate compromises

### Resolution Strategies
- **Conservative**: Both monitors at 1920x1080 @ 60Hz (always works)
- **Optimal**: Both monitors at 2560x1440 @ 60Hz (requires good dock)
- **Ambitious**: Mixed 4K + 1440p (depends on total bandwidth)

## Integration with Qtile

The final configuration integrates seamlessly with qtile's monitor detection:

```python
def count_monitors():
    # Automatically detects 3-monitor setup
    # Configures widgets for laptop + dual external displays
    # Handles dynamic reconfiguration
```

The improved setup provides:
- Consistent 60Hz performance across all displays
- Proper DPI and scaling detection
- Reliable hotplug behavior
- Better color accuracy with proper EDID

## Linux Display Enumeration Behavior

### Why Display Names Change with GPU Switching

The display name changes from `DisplayPort-2-x` to `DisplayPort-1-x` when switching GPU modes is **standard Linux behavior**, not a bug or dock issue.

**Root Cause**: Linux DRM (Direct Rendering Manager) assigns display controller numbers based on GPU hierarchy:

| prime-select Mode | Primary GPU | Secondary GPU | Display Names |
|-------------------|-------------|---------------|---------------|
| `on-demand` | AMD iGPU | NVIDIA dGPU | `DisplayPort-2-8`, `DisplayPort-2-9` |
| `nvidia` | NVIDIA dGPU | AMD disabled | `DisplayPort-1-8`, `DisplayPort-1-9` |
| `intel` | AMD iGPU | NVIDIA disabled | `DisplayPort-1-8`, `DisplayPort-1-9` |

**Key Points**:
- Physical connections remain unchanged (same USB-C dock, same cables)
- EDID data stays consistent (same monitor identification)
- Only the Linux kernel's naming scheme changes
- Same behavior affects all display types: HDMI, eDP, VGA, etc.

**Why This Happens**:
1. **PCI enumeration order** determines initial GPU numbering
2. **Prime-select configuration** changes which GPU gets primary status
3. **DRM subsystem** reassigns display controller numbers on GPU priority change
4. **Display names follow controller numbers** automatically

**Enterprise Solutions**: Professional display management tools use EDID-based identification instead of port names to avoid this issue.

### Script Compatibility

The troubleshooting script handles this automatically by detecting which naming scheme is active:

```bash
# Auto-detection logic
if xrandr | grep -q "DisplayPort-1-[89] connected"; then
    DP1="DisplayPort-1-8"; DP2="DisplayPort-1-9"  # NVIDIA mode
elif xrandr | grep -q "DisplayPort-2-[89] connected"; then  
    DP1="DisplayPort-2-8"; DP2="DisplayPort-2-9"  # Hybrid mode
fi
```

## Future Considerations

### Potential Upgrades
- **Dual DisplayPort**: If dock supports two DP outputs
- **Direct GPU Connection**: Bypass dock entirely for one monitor
- **Higher Bandwidth Dock**: Thunderbolt 4 for multiple 4K displays

### Monitoring Setup Health
- Regular EDID verification
- Refresh rate monitoring
- Bandwidth utilization tracking
- Temperature monitoring under load

This journey demonstrates that USB-C docks can provide excellent dual monitor support when configured properly, with USB-C connections significantly outperforming HDMI routing through the same dock.