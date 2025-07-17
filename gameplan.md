# Gameplan: Solving the Laptop Suspend Issue

## Problem Statement

The user wanted intelligent laptop suspend behavior that would:
- Suspend the laptop when closing the lid while using only the laptop screen
- Prevent suspend when external monitors are connected (assuming active work session)
- Automatically lock the screen before suspend for security

## Analysis Phase

### Understanding the System
1. **Hardware Detection**: Used `xrandr` to detect connected monitors
2. **Suspend Mechanism**: Leveraged systemd-logind for lid switch handling
3. **Screen Locking**: Integrated with cinnamon-screensaver for secure suspend/resume
4. **Service Management**: Used systemd user services for lifecycle management

### Key Challenges Identified
1. **Monitor Detection**: Need reliable way to detect external monitors
2. **Lid Switch Handling**: Configure system to trigger our custom logic
3. **Race Conditions**: Ensure proper timing between lock, suspend, and resume
4. **Logging**: Provide debugging capability for troubleshooting

## Solution Architecture

### Core Components

#### 1. Monitor Detection (`monitor-aware-suspend.sh`)
```bash
# Core logic: Count active monitors using xrandr
monitor_count=$(xrandr --listactivemonitors | head -n1 | grep -o '[0-9]*')
```

**Decision Logic:**
- Single monitor (laptop only) → Allow suspend
- Multiple monitors → Block suspend, show notification

#### 2. Suspend Lifecycle Management (`suspend-lock.sh`)
**Pre-suspend actions:**
- Lock screen using cinnamon-screensaver
- Log suspend event with timestamp
- Ensure proper screen state before suspend

**Post-resume actions:**
- Log resume event
- Handle any post-resume cleanup

#### 3. System Integration (`setup-sleep-functionality.sh`)
**System-level configuration:**
```bash
# Configure logind to handle lid switch
HandleLidSwitch=suspend
HandleLidSwitchDocked=ignore
HandleLidSwitchExternalPower=suspend
```

#### 4. Service Orchestration (systemd user services)
**Services created in autostart.sh:**
- `lock-on-suspend.service`: Triggers before suspend
- `unlock-on-resume.service`: Triggers after resume

## Implementation Strategy

### Phase 1: Core Functionality
1. **Monitor Detection Script**: Created `monitor-aware-suspend.sh` with xrandr integration
2. **Suspend Logic**: Implemented check/suspend modes in single script
3. **Testing**: Built-in test mode for verification

### Phase 2: Screen Locking Integration
1. **Pre-suspend Locking**: Integrated cinnamon-screensaver-command
2. **Lifecycle Management**: Created `suspend-lock.sh` for pre/post actions
3. **Error Handling**: Added proper error handling and logging

### Phase 3: System Integration
1. **Systemd Services**: Created user services for suspend/resume hooks
2. **Autostart Integration**: Modified autostart.sh to enable services
3. **System Configuration**: Created setup script for logind configuration

### Phase 4: User Experience
1. **Logging**: Comprehensive logging to `~/.cache/qtile-suspend.log`
2. **Notifications**: User feedback for suspend prevention
3. **Setup Script**: Automated system configuration

## Technical Decisions

### Why xrandr for Monitor Detection?
- **Reliable**: Standard X11 tool, always available
- **Accurate**: Shows actual active monitors, not just connected ones
- **Fast**: Quick execution, suitable for lid switch handling

### Why systemd User Services?
- **Integration**: Native systemd-logind integration
- **Reliability**: Proper lifecycle management
- **Permissions**: Runs as user, no root required

### Why cinnamon-screensaver?
- **Consistency**: Matches user's desktop environment
- **Reliability**: Mature screen locking solution
- **Integration**: Works well with suspend/resume cycle

## File Structure and Responsibilities

```
install/
├── monitor-aware-suspend.sh    # Core monitor detection and suspend logic
├── suspend-lock.sh            # Screen locking and lifecycle management
└── setup-sleep-functionality.sh # System configuration setup

autostart.sh                   # Service enablement
CLAUDE.md                     # Documentation and session log
README.md                     # User instructions
```

## Testing Strategy

### Validation Points
1. **Monitor Detection**: Verify correct monitor count detection
2. **Suspend Behavior**: Test both single and multi-monitor scenarios
3. **Screen Locking**: Ensure proper lock/unlock cycle
4. **Service Management**: Verify systemd services work correctly
5. **Logging**: Check log file creation and content

### Edge Cases Handled
- **No external monitors**: Normal suspend behavior
- **Multiple external monitors**: Proper suspend prevention
- **Service failures**: Graceful degradation
- **Screen locker unavailable**: Fallback behavior

## Deployment Process

### User Setup Steps
1. **Run setup script**: `./install/setup-sleep-functionality.sh`
2. **Restart qtile**: Services auto-enabled via autostart.sh
3. **Test functionality**: Close lid in different monitor configurations

### System Requirements
- systemd-logind (lid switch handling)
- xrandr (monitor detection)
- cinnamon-screensaver (screen locking)
- dunst (notifications)

## Monitoring and Debugging

### Log Analysis
- **Location**: `~/.cache/qtile-suspend.log`
- **Content**: Timestamps, monitor counts, suspend decisions
- **Format**: Human-readable with clear action indicators

### Troubleshooting Points
1. **Monitor detection issues**: Check xrandr output
2. **Suspend not working**: Verify logind configuration
3. **Screen lock failures**: Check cinnamon-screensaver status
4. **Service issues**: Use systemctl --user status

## Future Enhancements

### Potential Improvements
1. **Power-based logic**: Consider AC adapter status
2. **Time-based rules**: Different behavior during work hours
3. **Application awareness**: Check for active video calls/presentations
4. **Configuration file**: User-customizable behavior settings

### Maintenance Considerations
- **Monitor technology changes**: Wayland compatibility
- **Desktop environment changes**: Alternative screen lockers
- **System updates**: Logind configuration persistence

## Success Metrics

### Functionality Achieved
- ✅ Monitor-aware suspend behavior
- ✅ Automatic screen locking
- ✅ Comprehensive logging
- ✅ Easy setup and configuration
- ✅ Reliable operation without root privileges

### User Experience
- ✅ Intuitive behavior (suspend when expected, don't when working)
- ✅ Security (automatic screen lock)
- ✅ Transparency (clear logging for debugging)
- ✅ Easy installation and setup

This solution provides a robust, user-friendly laptop suspend system that adapts to the user's work context while maintaining security and reliability.