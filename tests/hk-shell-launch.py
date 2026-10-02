#!/usr/bin/env python3
"""Check that shell-launched applications survive stopping their shell."""

from pathlib import Path
import os
import shlex
import shutil
import subprocess
import tempfile
import time
import uuid

repo = Path(__file__).resolve().parents[1]
name = "hk-launch-check-" + uuid.uuid4().hex[:8]
unit = name + ".service"
desktop = (
    Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    / "applications"
    / (name + ".desktop")
)
children = []
with tempfile.TemporaryDirectory(prefix=name + "-") as temp:
    p = Path(temp)
    shell = p / "repo/config/quickshell"
    shutil.copytree(repo / "config/quickshell", shell)
    shutil.copytree(repo / "defaults", p / "repo/defaults")
    helper = p / "record-and-wait"
    helper.write_text(
        '#!/bin/bash\nprintf "%s:%s" "$BASHPID" "${HYPRKARL_OUTPUT:-}" > '
        + shlex.quote(str(p))
        + '/"$1"\nexec sleep 30\n'
    )
    helper.chmod(0o755)
    desktop.write_text(
        "[Desktop Entry]\nType=Application\nName=Hyprkarl launch check\nExec="
        + str(helper)
        + " launcher\n"
    )
    (shell / "launch-check.qml").write_text("""import QtQuick
import Quickshell
import Quickshell.Io
import "config"
import "modules/applications"
import "ui/controls"
ShellRoot {
        Theme {id: currentTheme}
        LazyLoader {
                id: trigger
                active: currentTheme.ready
                ShellButton {
                        theme: currentTheme; edge: "top"; panelHost: null
                        barWindow: ({"screen":{"name":"launch-check-output"}})
                }
        }
        IpcHandler {
                target: "check"
                function launcher(id: string): void {
                        ApplicationPickerState.openLauncher("test")
                        ApplicationPickerState.activate({"id":id})
                }
                function widget(command: string): void {trigger.item.runCommand(command)}
        }
}""")
    try:
        subprocess.run(
            [
                "systemd-run",
                "--user",
                "--unit=" + unit,
                "--collect",
                "env",
                "QT_QPA_PLATFORM=offscreen",
                "QML_IMPORT_PATH=" + str(shell),
                "qs",
                "-p",
                str(shell / "launch-check.qml"),
            ],
            check=True,
            capture_output=True,
        )
        for _ in range(50):
            r = subprocess.run(
                ["qs", "-p", str(shell / "launch-check.qml"), "ipc", "show"],
                capture_output=True,
                text=True,
            )
            if "target check" in r.stdout:
                break
            time.sleep(0.1)
        else:
            raise RuntimeError("fixture shell did not start")
        subprocess.run(
            [
                "qs",
                "-p",
                str(shell / "launch-check.qml"),
                "ipc",
                "call",
                "check",
                "launcher",
                name,
            ],
            check=True,
            capture_output=True,
        )
        subprocess.run(
            [
                "qs",
                "-p",
                str(shell / "launch-check.qml"),
                "ipc",
                "call",
                "check",
                "widget",
                shlex.quote(str(helper)) + " widget",
            ],
            check=True,
            capture_output=True,
        )
        for tag in ["launcher", "widget"]:
            for _ in range(50):
                if (p / tag).exists():
                    break
                time.sleep(0.1)
            else:
                raise RuntimeError(tag + " did not launch")
            pid, output = (p / tag).read_text().split(":", 1)
            pid = int(pid)
            children.append(pid)
            group = Path("/proc") / str(pid) / "cgroup"
            assert unit not in group.read_text(), (tag, group.read_text())
            if tag == "widget":
                assert output == "launch-check-output", output
            print(tag, "runs outside shell:", group.read_text().strip())
        subprocess.run(["systemctl", "--user", "stop", unit], check=True)
        for pid in children:
            os.kill(pid, 0)
        print(
            "PASS: launcher and widget applications survive stopping their shell; output context is preserved"
        )
    finally:
        subprocess.run(["systemctl", "--user", "stop", unit], capture_output=True)
        for pid in children:
            try:
                os.kill(pid, 15)
            except ProcessLookupError:
                pass
        desktop.unlink()
