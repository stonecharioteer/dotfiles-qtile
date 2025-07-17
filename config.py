"""Vinay's Qtile Config

See README.md for instructions
"""

from __future__ import annotations
import json
import os
import subprocess
from libqtile.core.manager import Qtile
from libqtile import bar, layout, widget, hook
from libqtile.config import Key, Group, Screen, Match, Click, Drag
from libqtile.lazy import lazy

colors = {
    "burgandy": "#b84d57",
    "midnight": "#1e2030",
    "light_blue_grey": "#d6dae8",
    "light_blue": "#8fafc7",
    "dark_slate_blue": "#2e3448"
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


@lazy.function
def move_mouse_to_next_monitor(qtile: Qtile):
    """Moves the mouse position to the next screen by calculating the position of the centre of the screen."""
    screen_count = len(qtile.screens)
    current_screen = qtile.current_screen
    current_index = next(
        (i for i, s in enumerate(qtile.screens) if s == current_screen), 0
    )
    next_index = (current_index + 1) % screen_count
    next_screen = qtile.screens[next_index]
    x = next_screen.x + next_screen.width // 2
    y = next_screen.y + next_screen.height // 2
    qtile.core.warp_pointer(x, y)


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
    Key(
        [mod, "shift"],
        "p",
        lazy.spawn(os.path.expanduser("~/.config/qtile/install/rofi/screenshot.sh")),
        desc="Screenshot",
    ),
    Key(
        [mod, "shift"],
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
]

groups = [Group(str(i)) for i in range(1, 10)]
for i in groups:
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
    layout.MonadTall(border_focus=colors["burgandy"], border_width=2, margin=8),
    layout.Columns(border_focus_stack=[colors["burgandy"], "#8f3d3d"], border_width=4),
    layout.Tile(),
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
    output = subprocess.check_output(
        "amdgpu_top -J -d".split(), stderr=subprocess.DEVNULL
    )
    return json.loads(output)


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


def sep(*,foreground=colors["burgandy"], background=None):
    """Returns a custom separator"""
    if background:
        return widget.TextBox("⋮", foreground=foreground, background=background,padding=10)
    else:
        return widget.TextBox("⋮", foreground=foreground, padding=10)


def has_battery():
    """Check if the system has a battery"""
    import glob
    return bool(glob.glob("/sys/class/power_supply/BAT*"))


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
    
    # Add battery widget if battery is detected
    if has_battery():
        bottom_widgets.extend([
            sep(),
            widget.Battery(
                format="{char} {percent:2.0%}",
                charge_char="⚡",
                discharge_char="🔌",
                low_percentage=0.3,
                low_foreground="ff0000",
            ),
        ])
    
    bottom_widgets.extend([
        widget.Spacer(stretch=True),
        widget.Clock(format="[%Y-%m-%d %H:%M:%S]"),
    ])
    
    bottom = bar.Bar(bottom_widgets, 36, margin=5, background=colors["bar"])
    top = bar.Bar(
        [
            widget.Image(filename=images["linux-mint"], margin=5)
            if main
            else widget.Image(filename=images["python"], margin=5),
            sep(),
            # widget.Spacer(15),
            widget.CurrentLayoutIcon(),
            sep(),
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
            widget.Systray(background=colors["sys_tray"]) if main else widget.Spacer(length=1),
            sep(),
            widget.Image(filename=images["straw-hat"]),
        ],
        36,
        margin=5,
        background=colors["bar"],
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
