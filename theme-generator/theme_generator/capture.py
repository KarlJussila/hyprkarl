import json
import os
import shutil
import subprocess
import tempfile
import time
from pathlib import Path

from .preview import render_theme_preview

CAPTURE_FILENAMES = ("palette.png", "busy.png", "launcher.png", "menu.png", "wallpapers.png")
DEFAULT_CAPTURE_WORKSPACE = 4
PROJECT_ROOT = Path(__file__).resolve().parents[2]


class CaptureError(RuntimeError):
    pass


def _run(
    command: list[str],
    *,
    env: dict[str, str] | None = None,
    check: bool = True,
) -> subprocess.CompletedProcess:
    try:
        return subprocess.run(
            command,
            check=check,
            env=env,
            text=True,
            capture_output=True,
        )
    except subprocess.CalledProcessError as error:
        detail = (error.stderr or error.stdout or "").strip()
        raise CaptureError(detail or str(error)) from error


def _hyprland_json(command: str) -> list[dict]:
    return json.loads(_run(["hyprctl", "-j", command]).stdout)


def _focused_monitor() -> dict:
    monitors = _hyprland_json("monitors")
    return next(monitor for monitor in monitors if monitor["focused"])


def _workspace_selector(name: str) -> str:
    return name if name.lstrip("-").isdigit() else f"name:{name}"


def _focus_workspace(workspace: str) -> None:
    dispatcher = f"hl.dsp.focus({{ workspace = {json.dumps(workspace)} }})"
    _run(["hyprctl", "dispatch", dispatcher])


def _focus_window(address: str) -> None:
    window = f"address:{address}"
    dispatcher = f"hl.dsp.focus({{ window = {json.dumps(window)} }})"
    _run(["hyprctl", "dispatch", dispatcher])


def _workspace_clients(workspace_name: str) -> list[dict]:
    return [
        client
        for client in _hyprland_json("clients")
        if client["workspace"]["name"] == workspace_name
    ]


def _wait_for_client_count(workspace_name: str, count: int, timeout: float = 12.0) -> None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if len(_workspace_clients(workspace_name)) == count:
            return
        time.sleep(0.1)
    raise CaptureError(f"Theme preview workspace did not reach {count} windows")


def _wait_for_client(
    workspace_name: str,
    window_class: str,
    timeout: float = 12.0,
) -> dict:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        for client in _workspace_clients(workspace_name):
            if client["class"] == window_class:
                return client
        time.sleep(0.1)
    raise CaptureError(f"Theme preview window did not open: {window_class}")


def _cursor_position() -> tuple[int, int]:
    position = json.loads(_run(["hyprctl", "-j", "cursorpos"]).stdout)
    return position["x"], position["y"]


def _move_cursor(x: int, y: int) -> None:
    dispatcher = f"hl.dsp.cursor.move({{ x = {x}, y = {y} }})"
    _run(["hyprctl", "dispatch", dispatcher])


def _monitor_point(
    monitor: dict,
    x_fraction: float,
    y_fraction: float,
) -> tuple[int, int]:
    logical_width = monitor["width"] / monitor["scale"]
    logical_height = monitor["height"] / monitor["scale"]
    x = round(monitor["x"] + logical_width * x_fraction)
    y = round(monitor["y"] + logical_height * y_fraction)
    return x, y


def _move_cursor_on_monitor(monitor: dict, x_fraction: float, y_fraction: float) -> None:
    _move_cursor(*_monitor_point(monitor, x_fraction, y_fraction))


def _place_cursor_on_monitor(
    monitor: dict,
    x_fraction: float,
    y_fraction: float,
    pointer_environment: dict[str, str],
) -> None:
    x, y = _monitor_point(monitor, x_fraction, y_fraction)
    _move_cursor(x, y)
    time.sleep(0.1)
    _run(
        ["ydotool", "mousemove", "--", "15", "0"],
        env=pointer_environment,
    )
    time.sleep(0.1)
    _run(
        ["ydotool", "mousemove", "--", "-15", "0"],
        env=pointer_environment,
    )


def _start_pointer_input(
    socket_path: Path,
) -> tuple[subprocess.Popen, dict[str, str]]:
    daemon = subprocess.Popen(
        [
            "ydotoold",
            "--socket-path",
            str(socket_path),
            "--keyboard-off",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    deadline = time.monotonic() + 3
    while not socket_path.exists():
        if daemon.poll() is not None or time.monotonic() >= deadline:
            daemon.terminate()
            daemon.wait(timeout=3)
            raise CaptureError("Could not start the theme capture pointer device")
        time.sleep(0.05)
    environment = dict(os.environ)
    environment["YDOTOOL_SOCKET"] = str(socket_path)
    return daemon, environment


def _close_workspace_clients(workspace_name: str) -> None:
    for client in _workspace_clients(workspace_name):
        window = f"address:{client['address']}"
        dispatcher = f"hl.dsp.window.close({{ window = {json.dumps(window)} }})"
        _run(
            ["hyprctl", "dispatch", dispatcher],
            check=False,
        )


def _capture_output(monitor_name: str, destination: Path) -> None:
    _run(["grim", "-o", monitor_name, str(destination)])


def _capture_surface(
    monitor: dict,
    monitor_name: str,
    destination: Path,
    open_command: list[str],
    close_command: list[str],
    cursor_position: tuple[float, float],
    pointer_environment: dict[str, str],
    settle_time: float,
) -> None:
    env = dict(os.environ)
    env["HYPRKARL_OUTPUT"] = monitor_name
    _run(open_command, env=env)
    time.sleep(settle_time / 2)
    _place_cursor_on_monitor(
        monitor,
        *cursor_position,
        pointer_environment,
    )
    time.sleep(settle_time / 2)
    _capture_output(monitor_name, destination)
    _run(close_command, env=env)
    time.sleep(settle_time / 2)


def _publish_previews(staging: Path, output: Path) -> None:
    output.mkdir(parents=True, exist_ok=True)
    for filename in CAPTURE_FILENAMES:
        destination = output / filename
        next_path = output / f".{filename}.next"
        shutil.copy2(staging / filename, next_path)
        os.replace(next_path, destination)


def capture_theme_previews(
    theme_name: str,
    theme: dict,
    output_directory: Path,
    settle_time: float = 1.0,
    workspace: int = DEFAULT_CAPTURE_WORKSPACE,
) -> Path:
    monitor = _focused_monitor()
    monitor_name = monitor["name"]
    previous_workspace = monitor["activeWorkspace"]["name"]
    previous_cursor = _cursor_position()
    workspace_name = str(workspace)
    workspace_selector = _workspace_selector(workspace_name)

    if _workspace_clients(workspace_name):
        raise CaptureError(f"Workspace {workspace_name} must be empty for theme capture")

    with tempfile.TemporaryDirectory(prefix=f"{theme_name}-previews-") as temporary_directory:
        staging = Path(temporary_directory)
        render_theme_preview(theme, theme_name, staging / "palette.png")

        pointer_daemon, pointer_environment = _start_pointer_input(
            staging / "pointer.sock"
        )
        try:
            _run(["hk-theme", "set", theme_name])
            time.sleep(settle_time)
            _focus_workspace(workspace_selector)
            time.sleep(settle_time)

            subprocess.Popen(
                [
                    "foot",
                    "-T",
                    "fastfetch",
                    "-a",
                    "hyprkarl-theme-fastfetch",
                    "-H",
                    "fastfetch",
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            fastfetch = _wait_for_client(
                workspace_name,
                "hyprkarl-theme-fastfetch",
            )
            subprocess.Popen(
                [
                    "foot",
                    "-T",
                    "btop",
                    "-a",
                    "hyprkarl-theme-btop",
                    "btop",
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            _wait_for_client(workspace_name, "hyprkarl-theme-btop")
            _focus_window(fastfetch["address"])
            subprocess.Popen(
                [
                    "nautilus",
                    "--new-window",
                    "--select",
                    str(PROJECT_ROOT / "packages"),
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            _wait_for_client(workspace_name, "org.gnome.Nautilus")
            _wait_for_client_count(workspace_name, 3)
            _move_cursor_on_monitor(monitor, 0.18, 0.67)
            time.sleep(settle_time / 2)
            _focus_window(fastfetch["address"])
            notification_id = _run(
                [
                    "notify-send",
                    "--print-id",
                    "-a",
                    "Hyprkarl",
                    "-i",
                    "preferences-desktop-theme",
                    "Theme preview ready",
                    f"{theme_name} with {theme['desktop']['icon_theme']}",
                    "-t",
                    "8000",
                ]
            ).stdout.strip()
            env = dict(os.environ)
            env["HYPRKARL_OUTPUT"] = monitor_name
            _run(["hk-shell", "osd", "volume", "40"], env=env)
            time.sleep(settle_time)
            _capture_output(monitor_name, staging / "busy.png")
            _run(
                [
                    "gdbus",
                    "call",
                    "--session",
                    "--dest",
                    "org.freedesktop.Notifications",
                    "--object-path",
                    "/org/freedesktop/Notifications",
                    "--method",
                    "org.freedesktop.Notifications.CloseNotification",
                    notification_id,
                ],
                check=False,
            )

            _close_workspace_clients(workspace_name)
            _wait_for_client_count(workspace_name, 0)
            time.sleep(max(settle_time, 2.5))

            _capture_surface(
                monitor,
                monitor_name,
                staging / "launcher.png",
                ["hk-shell", "launcher", "open"],
                ["hk-shell", "launcher", "close"],
                (0.5, 0.41),
                pointer_environment,
                settle_time,
            )
            _capture_surface(
                monitor,
                monitor_name,
                staging / "menu.png",
                ["hk-shell", "menu", "open", "main"],
                ["hk-shell", "menu", "close"],
                (0.5, 0.455),
                pointer_environment,
                settle_time,
            )
            _capture_surface(
                monitor,
                monitor_name,
                staging / "wallpapers.png",
                ["hk-shell", "wallpaper", "set"],
                ["hk-shell", "wallpaper", "close"],
                (0.08, 0.5),
                pointer_environment,
                settle_time,
            )
            _publish_previews(staging, output_directory)
        finally:
            env = dict(os.environ)
            env["HYPRKARL_OUTPUT"] = monitor_name
            _run(["hk-shell", "launcher", "close"], env=env, check=False)
            _run(["hk-shell", "menu", "close"], env=env, check=False)
            _run(["hk-shell", "wallpaper", "close"], env=env, check=False)
            _close_workspace_clients(workspace_name)
            _focus_workspace(_workspace_selector(previous_workspace))
            _move_cursor(*previous_cursor)
            pointer_daemon.terminate()
            pointer_daemon.wait(timeout=3)

    return output_directory
