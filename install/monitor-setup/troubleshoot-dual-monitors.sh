#!/bin/bash

# Dual Monitor USB-C Dock Troubleshooting Script
# Comprehensive diagnostics and fixes for dual 4K monitors through USB-C dock

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

print_section() {
    echo
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

# Phase 1: System Information and Hardware Detection
system_info() {
    print_section "SYSTEM INFORMATION"
    
    log "Kernel version:"
    uname -r
    
    log "Graphics hardware:"
    lspci | grep -E "(VGA|3D|Display)" || echo "No graphics hardware detected"
    
    log "NVIDIA driver version:"
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null || echo "NVIDIA driver not available"
    
    log "Current GPU mode:"
    prime-select query 2>/dev/null || echo "prime-select not available"
    
    log "OpenGL renderer:"
    glxinfo | grep -E "(OpenGL renderer|OpenGL vendor)" 2>/dev/null || echo "glxinfo not available"
}

# Phase 2: Monitor Detection and EDID Analysis
monitor_detection() {
    print_section "MONITOR DETECTION"
    
    log "Current monitor configuration:"
    xrandr --listmonitors
    
    echo
    log "Connected displays:"
    xrandr | grep connected
    
    echo
    log "EDID data analysis:"
    for dp in DisplayPort-1-{8,9} DisplayPort-2-{8,9}; do
        if xrandr | grep -q "$dp connected"; then
            edid_file="/sys/class/drm/card*-$(echo $dp | tr - _)/edid"
            if ls $edid_file 2>/dev/null; then
                edid_size=$(wc -c < $edid_file 2>/dev/null || echo 0)
                if [ "$edid_size" -gt 0 ]; then
                    success "$dp: EDID detected ($edid_size bytes)"
                else
                    warn "$dp: No EDID data (0 bytes) - may cause resolution issues"
                fi
            fi
        fi
    done
}

# Phase 3: Performance and Stuttering Analysis
performance_analysis() {
    print_section "PERFORMANCE ANALYSIS"
    
    log "Checking for hybrid graphics issues..."
    gpu_count=$(lspci | grep -E "(VGA|3D|Display)" | wc -l)
    if [ "$gpu_count" -gt 1 ]; then
        warn "Multiple GPUs detected - potential for switching conflicts"
        current_mode=$(prime-select query 2>/dev/null || echo "unknown")
        log "Current GPU mode: $current_mode"
        
        if [ "$current_mode" = "on-demand" ]; then
            error "GPU switching mode detected - this causes stuttering!"
            echo "  Fix: sudo prime-select nvidia (requires reboot)"
        elif [ "$current_mode" = "nvidia" ]; then
            success "Using dedicated NVIDIA GPU - should eliminate stuttering"
        fi
    else
        success "Single GPU system - no switching conflicts"
    fi
    
    echo
    log "Compositor status:"
    if pgrep picom > /dev/null; then
        success "Picom compositor running"
        picom_pid=$(pgrep picom)
        echo "  PID: $picom_pid"
    else
        warn "No compositor detected"
    fi
    
    echo
    log "Testing for stuttering (run cmatrix for 10 seconds)..."
    echo "Watch for pauses or jerky animation - press Ctrl+C if it stutters"
    timeout 10s cmatrix 2>/dev/null || echo "cmatrix test completed or interrupted"
}

# Phase 4: Resolution and Refresh Rate Setup
setup_monitors() {
    print_section "MONITOR SETUP"
    
    # Detect which DisplayPort naming scheme is active
    if xrandr | grep -q "DisplayPort-1-[89] connected"; then
        DP1="DisplayPort-1-8"
        DP2="DisplayPort-1-9"
        log "Using NVIDIA-mode DisplayPort naming (DisplayPort-1-x)"
    elif xrandr | grep -q "DisplayPort-2-[89] connected"; then
        DP1="DisplayPort-2-8"
        DP2="DisplayPort-2-9"
        log "Using hybrid-mode DisplayPort naming (DisplayPort-2-x)"
    else
        error "No compatible DisplayPort monitors detected"
        echo "Expected: DisplayPort-1-8/1-9 or DisplayPort-2-8/2-9"
        return 1
    fi
    
    # Check if both monitors are connected
    if ! xrandr | grep -q "$DP1 connected"; then
        error "$DP1 not detected. Check DisplayPort cable connection."
        return 1
    fi
    
    if ! xrandr | grep -q "$DP2 connected"; then
        error "$DP2 not detected. Check USB-C cable connection."
        return 1
    fi
    
    success "Both monitors detected: $DP1 and $DP2"
    
    # Clean existing modes
    log "Cleaning existing custom modes..."
    xrandr --delmode $DP1 "2560x1440_60.00" 2>/dev/null || true
    xrandr --delmode $DP2 "2560x1440_60.00" 2>/dev/null || true
    xrandr --rmmode "2560x1440_60.00" 2>/dev/null || true
    
    # Create and apply 1440p mode
    log "Creating 1440p @ 60Hz mode..."
    xrandr --newmode "2560x1440_60.00" 312.25 2560 2752 3024 3488 1440 1443 1448 1493 -hsync +vsync
    
    log "Adding modes to monitors..."
    xrandr --addmode $DP1 "2560x1440_60.00"
    xrandr --addmode $DP2 "2560x1440_60.00"
    
    log "Configuring monitor layout..."
    xrandr --output $DP1 --mode "2560x1440_60.00" --pos 1920x0
    xrandr --output $DP2 --mode "2560x1440_60.00" --pos 4480x0
    
    success "Monitor setup complete!"
    echo
    log "Final configuration:"
    xrandr --listmonitors
}

# Phase 5: Automated Fixes
auto_fix() {
    print_section "AUTOMATED FIXES"
    
    log "Applying common fixes..."
    
    # Disable TearFree to reduce input lag
    log "Disabling TearFree on external monitors..."
    for output in DisplayPort-1-8 DisplayPort-1-9 DisplayPort-2-8 DisplayPort-2-9; do
        if xrandr | grep -q "$output connected"; then
            xrandr --output $output --set TearFree off 2>/dev/null || true
        fi
    done
    
    # Force PCI bus rescan if monitors not detected
    missing_monitors=0
    for dp in DisplayPort-1-{8,9} DisplayPort-2-{8,9}; do
        if ! xrandr | grep -q "$dp connected"; then
            ((missing_monitors++))
        fi
    done
    
    if [ "$missing_monitors" -eq 4 ]; then
        warn "No external monitors detected - trying PCI rescan (requires sudo)"
        echo "Run: sudo echo 1 > /sys/bus/pci/rescan"
    fi
    
    success "Automated fixes applied"
}

# Interactive troubleshooting menu
interactive_menu() {
    while true; do
        echo
        echo "=========================================="
        echo "INTERACTIVE TROUBLESHOOTING MENU"
        echo "=========================================="
        echo "1. System information and hardware detection"
        echo "2. Monitor detection and EDID analysis" 
        echo "3. Performance and stuttering analysis"
        echo "4. Setup/restore dual monitor configuration"
        echo "5. Apply automated fixes"
        echo "6. Run full diagnostic (all above)"
        echo "7. Exit"
        echo
        read -p "Select option (1-7): " choice
        
        case $choice in
            1) system_info ;;
            2) monitor_detection ;;
            3) performance_analysis ;;
            4) setup_monitors ;;
            5) auto_fix ;;
            6) 
                system_info
                monitor_detection  
                performance_analysis
                setup_monitors
                auto_fix
                ;;
            7) 
                log "Troubleshooting complete!"
                exit 0 
                ;;
            *) 
                error "Invalid option. Please select 1-7."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Main execution
main() {
    echo "=========================================="
    echo "USB-C Dock Dual Monitor Troubleshooter"
    echo "=========================================="
    echo "This script diagnoses and fixes common issues with:"
    echo "- USB-C dock dual monitor setups"
    echo "- EDID detection problems"  
    echo "- Hybrid graphics stuttering"
    echo "- Resolution and refresh rate issues"
    echo
    
    if [ "$1" = "--auto" ]; then
        log "Running automated full diagnostic..."
        system_info
        monitor_detection
        performance_analysis
        setup_monitors
        auto_fix
    else
        interactive_menu
    fi
}

# Check if running with sufficient permissions for some operations
if [ "$EUID" -eq 0 ]; then
    warn "Running as root - some operations may behave differently"
fi

main "$@"