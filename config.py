"""Vinay's Qtile Config

See README.md for instructions
"""

from __future__ import annotations
import json
import os
import subprocess
import datetime
from pathlib import Path
from libqtile.core.manager import Qtile
from libqtile import bar, layout, widget, hook
from libqtile.config import Key, Group, Screen, Match, Click, Drag, ScratchPad, DropDown
from libqtile.lazy import lazy

colors = {
    "burgandy": "#b84d57",
    "midnight": "#1e2030",
    "light_blue_grey": "#d6dae8",
    "light_blue": "#8fafc7",
    "dark_slate_blue": "#2e3448",
}
colors["sys_tray"] = colors["dark_slate_blue"]
colors["bar"] = colors["dark_slate_blue"]
images = {
    "python": os.path.expanduser("~/.config/qtile/assets/python-logo-only.svg"),
    "straw-hat": os.path.expanduser("~/.config/qtile/assets/strawhat.png"),
    "linux-mint": os.path.expanduser("~/.config/qtile/assets/Linux_Mint.svg"),
    "cpu": os.path.expanduser("~/.config/qtile/assets/cpu.png"),
    "gpu": os.path.expanduser("~/.config/qtile/assets/gpu.png"),
    "ram": os.path.expanduser("~/.config/qtile/assets/ram.png"),
}
mod = "mod4"  # super key is modifier
terminal = "alacritty"


def get_screenshot_filename():
    """Generate screenshot filename using pathlib"""
    screenshots_dir = Path.home() / "Pictures" / "screenshots"
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    return str(screenshots_dir / f"{timestamp}.png")


def multimedia_cmd(
    command, notification_title, notification_body=None, get_status_cmd=None
):
    """Execute multimedia command and show notification with current status"""

    def execute(qtile=None):
        try:
            # Execute the main command
            subprocess.run(command, shell=True, check=True, capture_output=True)

            # Get current status if status command provided
            if get_status_cmd:
                try:
                    result = subprocess.run(
                        get_status_cmd,
                        shell=True,
                        capture_output=True,
                        text=True,
                        timeout=2,
                    )
                    if result.returncode == 0:
                        status = result.stdout.strip()
                        body = (
                            f"{notification_body}: {status}"
                            if notification_body
                            else status
                        )
                    else:
                        body = notification_body or "Status updated"
                except Exception:
                    body = notification_body or "Status updated"
            else:
                body = notification_body or "Action completed"

            # Show notification
            subprocess.run(
                [
                    "notify-send",
                    "-t",
                    "1500",  # 1.5 second timeout
                    "-u",
                    "low",  # low urgency
                    notification_title,
                    body,
                ],
                capture_output=True,
            )

        except Exception as e:
            # Show error notification
            subprocess.run(
                [
                    "notify-send",
                    "-t",
                    "2000",
                    "-u",
                    "critical",
                    "Error",
                    f"Failed to execute {notification_title}: {str(e)}",
                ],
                capture_output=True,
            )

    return execute


@lazy.function
def move_mouse_to_next_monitor(qtile: Qtile):
    """Switch to next screen and move mouse to center."""
    qtile.cmd_next_screen()

    # Save current window focus before moving mouse
    current_window = qtile.current_window

    # Move mouse to center of the new screen (single movement, no wiggle)
    current_screen = qtile.current_screen
    x = current_screen.x + current_screen.width // 2
    y = current_screen.y + current_screen.height // 2
    qtile.core.warp_pointer(x, y)

    # Restore focus to the window that should be active
    if current_window:
        qtile.current_group.focus(current_window)


@lazy.function
def move_group_to_next_screen(qtile: Qtile):
    """Move current workspace to next screen."""
    if len(qtile.screens) > 1:
        current_screen_index = qtile.screens.index(qtile.current_screen)
        next_screen_index = (current_screen_index + 1) % len(qtile.screens)
        qtile.current_group.toscreen(next_screen_index)


@lazy.function
def highlight_mouse_cursor(qtile: Qtile):
    """Highlight mouse cursor by moving it in a small spiral and back to original position."""
    import time
    import math

    # Get current mouse position using qtile's core
    try:
        # Get mouse position from qtile core
        orig_x, orig_y = qtile.core.get_mouse_position()
    except Exception:
        # Fallback: use center of current screen
        screen = qtile.current_screen
        orig_x = screen.x + screen.width // 2
        orig_y = screen.y + screen.height // 2

    # Create spiral pattern: 8 points going outward, then 8 points going back
    spiral_points = []
    max_radius = 20

    # Outward spiral (8 points)
    for i in range(8):
        angle = (i * math.pi * 2) / 8  # 8 points around circle
        radius = (i + 1) * (max_radius / 8)  # Increasing radius
        x = orig_x + int(radius * math.cos(angle))
        y = orig_y + int(radius * math.sin(angle))
        spiral_points.append((x, y))

    # Inward spiral (8 points) - reverse the outward pattern
    for i in range(7, -1, -1):
        angle = (i * math.pi * 2) / 8
        radius = (i + 1) * (max_radius / 8)
        x = orig_x + int(radius * math.cos(angle))
        y = orig_y + int(radius * math.sin(angle))
        spiral_points.append((x, y))

    # Add original position at the end
    spiral_points.append((orig_x, orig_y))

    # Move through spiral points with timing for 300ms total
    delay_per_point = 300 / len(spiral_points) / 1000  # Convert to seconds

    for x, y in spiral_points:
        qtile.core.warp_pointer(x, y)
        time.sleep(delay_per_point)


# keymaps
keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key(
        [mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"
    ),
    Key(
        [mod, "shift"],
        "l",
        lazy.layout.shuffle_right(),
        desc="Move window to the right",
    ),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key(
        [mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"
    ),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    Key(
        [mod],
        "f",
        lazy.window.toggle_fullscreen(),
        desc="Toggle fullscreen on the focused window",
    ),
    Key(
        [mod],
        "t",
        lazy.window.toggle_floating(),
        desc="Toggle floating on the focused window",
    ),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    # Rofi mod-r
    Key(
        [mod],
        "r",
        lazy.spawn("rofi -show combi -combi-modes 'window,ssh,drun'"),
        desc="App launcher",
    ),
    Key([mod], "period", move_mouse_to_next_monitor(), desc="Focus next screen"),
    Key([mod, "shift"], "period", move_group_to_next_screen(), desc="Move workspace to next screen"),
    Key(
        [mod, "shift"], "slash", lazy.group["scratchpad"].dropdown_toggle("help"), desc="Toggle help popup"
    ),
    Key(
        [mod, "shift"],
        "p",
        lazy.spawn(os.path.expanduser("~/.config/qtile/install/rofi/screenshot.sh")),
        desc="Screenshot",
    ),
    Key(
        [mod, "mod1"],
        "l",
        lazy.spawn("cinnamon-screensaver-command --lock"),
        desc="Lock screen",
    ),
    Key(
        [mod, "shift"],
        "e",
        lazy.spawn(os.path.expanduser("~/.config/qtile/install/rofi/powermenu.sh")),
        desc="Power menu",
    ),
    Key(
        [mod, "shift"],
        "m",
        lazy.spawn(
            os.path.expanduser(
                "~/.config/qtile/install/monitor-manager/monitor-menu.sh"
            )
        ),
        desc="Monitor configuration menu",
    ),
    Key(
        [mod, "shift"],
        "n",
        lazy.spawn(
            os.path.expanduser("~/.config/qtile/install/rofi/notification-history.sh")
        ),
        desc="Notification history",
    ),
    # Test key binding - use a regular key we know works
    Key(
        [mod],
        "F1",
        lazy.spawn("notify-send 'Key Test' 'Mod+F1 pressed - key bindings work'"),
        desc="Test key binding",
    ),
    # Multimedia keys with notifications - try actual detected keys
    Key(
        [],
        "XF86AudioMute",
        lazy.spawn(
            'sh -c \'pactl set-sink-mute @DEFAULT_SINK@ toggle; mute_status=$(pactl get-sink-mute @DEFAULT_SINK@ | cut -d" " -f2); if [ "$mute_status" = "yes" ]; then dunstify -a "volume" -u low -r 9991 "🔇 Audio" "Muted"; else volume=$(pactl get-sink-volume @DEFAULT_SINK@ | head -1 | cut -d"/" -f2 | tr -d " %"); dunstify -a "volume" -u low -r 9991 -h int:value:"$volume" "🔊 Audio" "Unmuted - $volume%"; fi\''
        ),
        desc="Toggle mute",
    ),
    Key(
        [],
        "XF86AudioLowerVolume",
        lazy.spawn(
            'sh -c \'pactl set-sink-mute @DEFAULT_SINK@ 0; current=$(pactl get-sink-volume @DEFAULT_SINK@ | head -1 | cut -d"/" -f2 | tr -d " %"); new=$((current - 5)); [ $new -lt 0 ] && new=0; pactl set-sink-volume @DEFAULT_SINK@ ${new}%; dunstify -a "volume" -u low -r 9991 -h int:value:"$new" "🔉 Volume" "${new}%"\''
        ),
        desc="Lower volume and unmute",
    ),
    Key(
        [],
        "XF86AudioRaiseVolume",
        lazy.spawn(
            'sh -c \'pactl set-sink-mute @DEFAULT_SINK@ 0; current=$(pactl get-sink-volume @DEFAULT_SINK@ | head -1 | cut -d"/" -f2 | tr -d " %"); new=$((current + 5)); [ $new -gt 100 ] && new=100; pactl set-sink-volume @DEFAULT_SINK@ ${new}%; dunstify -a "volume" -u low -r 9991 -h int:value:"$new" "🔊 Volume" "${new}%"\''
        ),
        desc="Raise volume and unmute",
    ),
    # F20 key not recognized by X server - commented out
    # Key(
    #     [],
    #     "F20",
    #     lazy.spawn(
    #         'sh -c \'pactl set-source-mute @DEFAULT_SOURCE@ toggle; mic_status=$(pactl get-source-mute @DEFAULT_SOURCE@ | cut -d" " -f2); if [ "$mic_status" = "yes" ]; then notify-send "🎤 Microphone" "Muted"; else notify-send "🎤 Microphone" "Unmuted"; fi\''
    #     ),
    #     desc="Toggle microphone mute",
    # ),
    Key(
        [mod, "shift"],
        "b",
        lazy.spawn(os.path.expanduser("~/.config/qtile/install/rofi/brightness.sh")),
        desc="Brightness menu",
    ),
    Key(
        [],
        "XF86Launch3",
        lazy.function(
            multimedia_cmd("rofi -show drun", "🚀 Launcher", "Application menu opened")
        ),
        desc="Launch application menu",
    ),
    Key(
        [],
        "XF86Launch4",
        lazy.function(
            multimedia_cmd("rofi -show window", "🪟 Windows", "Window switcher opened")
        ),
        desc="Show window switcher",
    ),
    Key([mod], "z", lazy.screen.toggle_group(), desc="Toggle to last used workspace"),
    Key([mod], "grave", lazy.group["scratchpad"].dropdown_toggle("btop"), desc="Toggle btop"),
]

workspace_configs = [
    ("1", "1🏠"),     # General workspace
    ("2", "2🌐"),     # Websites
    ("3", "3💻"),     # Terminal/Development
    ("4", "4👥"),     # Socials
    ("5", "5💬"),     # Chat
    ("6", "6🎨"),     # Creative
    ("7", "7🎵"),     # Media/Entertainment
    ("8", "8📁"),     # Files/Documents
    ("9", "9⚙️"),     # Settings/System
    ("0", "0🔧"),     # Utilities
]

groups = [Group(name=key, label=emoji) for key, emoji in workspace_configs]

# Add scratchpad for btop and help
groups.append(
    ScratchPad("scratchpad", [
        DropDown("btop", f"{terminal} -e btop",
                 width=0.8,
                 height=0.85,
                 x=0.1,
                 y=0.075,
                 opacity=0.95),
        DropDown("help", f"{terminal} -e glow -p {os.path.expanduser('~/.config/qtile/SHORTCUTS.md')}",
                 width=0.8,
                 height=0.85,
                 x=0.1,
                 y=0.075,
                 opacity=0.95)
    ])
)

for i in groups:
    # Skip scratchpad when creating workspace keybindings
    if isinstance(i, ScratchPad):
        continue
    keys.extend(
        [
            Key(
                [mod],
                i.name,
                lazy.group[i.name].toscreen(),
                desc=f"Switch to group {i.name}",
            ),
            Key(
                [mod, "shift"],
                i.name,
                lazy.window.togroup(i.name),
                desc=f"Move window to group {i.name}",
            ),
        ]
    )

layouts = [
    layout.Columns(
        border_focus_stack=[colors["burgandy"], "#8f3d3d"], border_width=2, margin=2
    ),
    layout.Tile(border_focus=colors["burgandy"], border_width=2, margin=2),
    layout.Max(),
]

widget_defaults = dict(
    font="JetBrainsMono Nerd Font",
    fontsize=18,
    padding=3,
)
extension_defaults = widget_defaults.copy()


def amdgpu_metadata():
    """Retrieves the amdgpu metadata"""
    try:
        output = subprocess.check_output(
            "amdgpu_top -J -d".split(), stderr=subprocess.DEVNULL
        )
        return json.loads(output)
    except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError):
        return None


def get_vram_usage():
    data = amdgpu_metadata()
    if not data:
        return "GPU: N/A"

    parts = []
    for ix, gpu in enumerate(data):
        name = gpu.get("DeviceName", "GPU")
        if name == "AMD Radeon Graphics":
            name = "On-Chip"
        else:
            name = name.replace("AMD Radeon", "").strip()

        vram = gpu.get("VRAM", {})
        total = vram.get("Total VRAM", {}).get("value")
        used = vram.get("Total VRAM Usage", {}).get("value")
        if total is not None and used is not None:
            parts.append(f"[{name}]: {used}/{total} MiB")
        else:
            parts.append("[GPU]: N/A")
    return "\n".join(parts)


def sep(*, foreground=colors["burgandy"], background=None):
    """Returns a custom separator"""
    if background:
        return widget.TextBox(
            "⋮", foreground=foreground, background=background, padding=10
        )
    else:
        return widget.TextBox("⋮", foreground=foreground, padding=10)


def get_ip_address():
    """Get the current IP address from WiFi or Ethernet connection"""
    import subprocess
    import re

    try:
        # Get IP from active network interfaces (excluding loopback)
        result = subprocess.run(
            ["ip", "route", "get", "8.8.8.8"], capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            # Extract IP from output like "8.8.8.8 via 192.168.1.1 dev wlan0 src 192.168.1.100"
            match = re.search(r"src\s+(\d+\.\d+\.\d+\.\d+)", result.stdout)
            if match:
                ip = match.group(1)
                # Get interface name
                dev_match = re.search(r"dev\s+(\w+)", result.stdout)
                interface = dev_match.group(1) if dev_match else "unknown"
                return f"IP: {ip} ({interface})"

        return "IP: No connection"
    except Exception:
        return "IP: Error"


def get_ip_ssid_info():
    """Get IP and SSID information stacked"""
    import subprocess
    import re

    # Get IP address
    ip_info = "No connection"
    try:
        result = subprocess.run(
            ["ip", "route", "get", "8.8.8.8"], capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            match = re.search(r"src\s+(\d+\.\d+\.\d+\.\d+)", result.stdout)
            if match:
                ip = match.group(1)
                dev_match = re.search(r"dev\s+(\w+)", result.stdout)
                interface = dev_match.group(1) if dev_match else "unknown"
                ip_info = f"{ip} ({interface})"
    except Exception:
        ip_info = "Error"

    # Get SSID
    ssid_info = "No WiFi"
    try:
        # Try nmcli first
        result = subprocess.run(
            ["nmcli", "-t", "-f", "active,ssid", "dev", "wifi"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode == 0:
            for line in result.stdout.strip().split("\n"):
                if line.startswith("yes:"):
                    ssid = line.split(":", 1)[1]
                    ssid_info = ssid if ssid else "No SSID"
                    break

        # Fallback to iwgetid if nmcli didn't work
        if ssid_info == "No WiFi":
            result = subprocess.run(
                ["iwgetid", "-r"], capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0 and result.stdout.strip():
                ssid_info = result.stdout.strip()
    except Exception:
        ssid_info = "Error"

    # Calculate padding for left alignment
    lines = [ip_info, ssid_info]
    max_length = max(len(line) for line in lines)

    # Pad shorter lines to match the longest line
    padded_lines = [line.ljust(max_length) for line in lines]

    return "\n".join(padded_lines)


def get_hostname():
    """Get the system hostname"""
    import socket

    try:
        return f"Host: {socket.gethostname()}"
    except Exception:
        return "Host: Error"


def screen(main=False):
    """Returns a default screen with a bar."""
    bottom_widgets = [
        widget.Image(filename=images["cpu"], margin=8),
        widget.ThermalSensor(
            format="{temp:.1f}{unit}",
            tag_sensor="Tctl",
            sensors_chip="k10temp-pci-00c3",
        ),
        sep(),
        widget.Image(filename=images["gpu"], margin=5),
        widget.ThermalSensor(
            format="{temp:.1f}{unit}",
            tag_sensor="edge",
            sensors_chip="amdgpu-pci-1800",
        ),
        widget.GenPollText(func=get_vram_usage, update_interval=3, fontsize=10)
        if main
        else widget.Spacer(length=1),
        sep(),
        widget.CPU(),
        sep(),
        widget.Image(filename=images["ram"], margin=5),
        widget.Memory(),
    ]

    # Add IP address and hostname widgets only for main screen
    if main:
        bottom_widgets.extend(
            [
                sep(),
                widget.GenPollText(
                    func=get_hostname, update_interval=3600, fontsize=16
                ),
                sep(),
                widget.GenPollText(
                    func=get_ip_ssid_info, update_interval=15, fontsize=10
                ),
            ]
        )

    bottom_widgets.extend(
        [
            widget.Spacer(stretch=True),
            widget.Clock(format="[%Y-%m-%d %H:%M:%S]"),
        ]
    )

    bottom = bar.Bar(bottom_widgets, 36, margin=5, background=colors["bar"], opacity=1.0)
    top = bar.Bar(
        [
            widget.Image(filename=images["linux-mint"], margin=5)
            if main
            else widget.Image(filename=images["python"], margin=5),
            sep(),
            widget.TextBox(
                text="✂️",
                name="screenshot_button",
                mouse_callbacks={
                    "Button1": lazy.spawn(
                        [
                            "sh",
                            "-c",
                            "sleep 0.2 && scrot --select --line mode=edge ~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && notify-send 'Screenshot' 'Region saved'",
                        ]
                    )
                },
                fontsize=20,
                padding=8,
                background=colors["dark_slate_blue"],
                foreground="#ffffff",
            ),
            sep(),
            widget.CurrentLayout(mode="both", icon_first=False),
            sep(),
            widget.CurrentScreen(
                active_text="🟢",
                inactive_text="⚫",
                active_color=colors["burgandy"],
                inactive_color="#666666",
            ),
            widget.GroupBox(
                highlight_method="block",
                disable_drag=True,
                hide_unused=True,
            ),
            sep(),
            widget.TaskList(
                stretch=True,
                highlight_method="block",
                max_title_width=250,
            ),
            sep(background=colors["sys_tray"]) if main else widget.Spacer(length=1),
            widget.Systray(background=colors["sys_tray"])
            if main
            else widget.Spacer(length=1),
            sep(),
            widget.Image(filename=images["straw-hat"]),
        ],
        36,
        margin=5,
        background=colors["bar"],
        opacity=1.0,
    )
    if main:
        return Screen(top=top, bottom=bottom)
    else:
        return Screen(top=top)


def count_monitors():
    """Returns the number of monitors"""
    try:
        output = subprocess.check_output(["xrandr", "--query"]).decode()
        monitors = [line for line in output.splitlines() if " connected" in line]
        return len(monitors)
    except Exception as e:
        print(f"Error: {e}")
        return 0


screens = [
    screen(main=True),
]
for _ in range(count_monitors() - 1):
    screens.append(screen())

# Drag floating layouts.
mouse = [
    Drag(
        [mod],
        "Button1",
        lazy.window.set_position_floating(),
        start=lazy.window.get_position(),
    ),
    Drag(
        [mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()
    ),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]
dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
        Match(wm_class="Conky"),  # conky desktop widget
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
auto_minimize = True

wmname = "LG3D"


@hook.subscribe.startup_once
def startup_once():
    """Starts the first time qtile starts, don't start this on every reload since some of the services shouldn't reload"""
    subprocess.call(os.path.expanduser("~/.config/qtile/autostart.sh"))


@hook.subscribe.startup
def startup_always():
    """Runs every time qtile is started/reloaded"""
    subprocess.call(os.path.expanduser("~/.config/qtile/reload.sh"))
