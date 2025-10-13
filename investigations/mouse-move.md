# Monitor Switching Focus Issue Investigation

## Problem

When switching between monitors using `mod+period`, terminal windows would become unresponsive after the switch. The screen would activate and focus would appear to shift, but the terminal would not accept input until the layout was cycled.

## Root Cause

The issue was caused by the interaction between:
1. **`follow_mouse_focus = True`** in qtile config
2. **`qtile.core.warp_pointer()`** calls in the monitor switching function

When `follow_mouse_focus` is enabled, every mouse movement triggers a focus recalculation. Even a single `warp_pointer()` call causes qtile to re-evaluate which window should have focus based on the mouse position. This focus recalculation was breaking the terminal's input focus.

### Why Mouse Wiggling Made It Worse

Initial attempts to fix empty workspace activation added a "wiggle" animation (multiple rapid `warp_pointer()` calls). This caused even more focus recalculations (one per warp), making the problem more severe.

### Why It Affected Terminals Specifically

The issue affected terminals even when the mouse stayed over the terminal window throughout the entire animation. This ruled out "clicking empty space" theories and confirmed the root cause was the focus recalculation itself.

## Solution

The fix requires explicitly managing window focus around mouse movements:

```python
@lazy.function
def move_mouse_to_next_monitor(qtile: Qtile):
    """Switch to next screen and move mouse to center."""
    qtile.cmd_next_screen()

    # Save current window focus before moving mouse
    current_window = qtile.current_window

    # Move mouse to center of the new screen (single movement)
    current_screen = qtile.current_screen
    x = current_screen.x + current_screen.width // 2
    y = current_screen.y + current_screen.height // 2
    qtile.core.warp_pointer(x, y)

    # Restore focus to the window that should be active
    if current_window:
        qtile.current_group.focus(current_window)
```

### Key Points

1. **Save focus before mouse movement**: Capture `qtile.current_window` immediately after screen switch
2. **Single mouse warp**: Move directly to target position, no wiggling or animation
3. **Explicit focus restoration**: Call `qtile.current_group.focus(current_window)` to restore input focus

This prevents `follow_mouse_focus` from interfering with the intended focus flow during monitor switches.

## Additional Enhancement

Added `widget.CurrentScreen` to the top bar to provide visual feedback about which screen is currently active:

```python
widget.CurrentScreen(
    active_text="🟢",
    inactive_text="⚫",
    active_color=colors["burgandy"],
    inactive_color="#666666",
)
```

## Lessons Learned

- With `follow_mouse_focus = True`, any `warp_pointer()` call can disrupt focus state
- Mouse movement animations (wiggles, spirals) cause multiple focus recalculations
- Always explicitly save and restore window focus when programmatically moving the mouse
- The same issue affects `highlight_mouse_cursor()` function - may need similar fix if focus issues arise

## Related Functions

The `highlight_mouse_cursor()` function (mod+shift+/) uses a spiral animation with 16 `warp_pointer()` calls. If similar focus issues occur with that function, apply the same save/restore focus pattern.
