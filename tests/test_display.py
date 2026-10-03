#!/usr/bin/env python3
"""Focused tests for display geometry and persistent arrangement changes."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("display", ROOT / "bin/lib/display.py")
assert SPEC and SPEC.loader
display = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(display)


def monitor(
    name: str,
    x: int,
    y: int,
    *,
    width: int = 2560,
    height: int = 1440,
    scale: float = 1.0,
    transform: int = 0,
) -> dict[str, object]:
    return {
        "name": name,
        "description": f"Display {name}",
        "disabled": False,
        "focused": name == "DP-1",
        "x": x,
        "y": y,
        "width": width,
        "height": height,
        "refreshRate": 143.999,
        "availableModes": [
            f"{width}x{height}@143.999Hz",
            f"{width}x{height}@60.00Hz",
        ],
        "scale": scale,
        "transform": transform,
    }


class DisplayArrangementTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        state_home = Path(self.temporary.name)
        self.state_path = state_home / "layout.json"
        self.lua_path = state_home / "monitors.lua"
        self.pending_path = state_home / "pending.json"
        self.lock_path = state_home / "pending.lock"
        self.path_patch = mock.patch.multiple(
            display,
            STATE_HOME=state_home,
            STATE_PATH=self.state_path,
            LUA_PATH=self.lua_path,
            PENDING_PATH=self.pending_path,
            LOCK_PATH=self.lock_path,
        )
        self.path_patch.start()

    def tearDown(self) -> None:
        self.path_patch.stop()
        self.temporary.cleanup()

    def test_state_reports_logical_arranger_geometry(self) -> None:
        current = [
            monitor("DP-1", 0, 0, scale=2.0),
            monitor(
                "DP-2",
                1280,
                -1080,
                width=1920,
                height=1080,
                transform=1,
            ),
        ]
        with (
            mock.patch.object(display, "monitors", return_value=current),
            mock.patch.object(
                display,
                "brightness",
                return_value={"available": False, "percent": 0},
            ),
        ):
            state = display.display_state("DP-1")

        self.assertEqual(
            [
                (
                    output["name"],
                    output["x"],
                    output["y"],
                    output["logicalWidth"],
                    output["logicalHeight"],
                )
                for output in state["outputs"]
            ],
            [
                ("DP-1", 0, 0, 1280, 720),
                ("DP-2", 1280, -1080, 1080, 1920),
            ],
        )
        first = state["outputs"][0]
        self.assertEqual(first["mode"], "2560x1440@143.999")
        self.assertEqual(first["position"], "0x0")
        self.assertEqual(
            [mode["value"] for mode in first["modes"]],
            ["2560x1440@143.999", "2560x1440@60"],
        )

    def test_arrange_changes_positions_and_rotation_in_one_layout(self) -> None:
        current = [monitor("DP-1", 0, 0), monitor("DP-2", 2560, 0)]
        with (
            mock.patch.object(display, "monitors", return_value=current),
            mock.patch.object(display, "run", return_value="ok") as run,
        ):
            result = display.arrange(
                {
                    "DP-1": {"x": 2560, "y": 120, "transform": 1},
                    "DP-2": {"x": 0, "y": 0, "transform": 0},
                }
            )

        self.assertEqual(
            result,
            {
                "DP-1": {"x": 2560, "y": 120, "transform": 1},
                "DP-2": {"x": 0, "y": 0, "transform": 0},
            },
        )
        saved = json.loads(self.state_path.read_text())
        self.assertEqual(saved["outputs"]["DP-1"]["position"], "2560x120")
        self.assertEqual(saved["outputs"]["DP-2"]["position"], "0x0")
        self.assertEqual(saved["outputs"]["DP-1"]["mode"], "2560x1440@143.999")
        self.assertEqual(saved["outputs"]["DP-1"]["scale"], 1.0)
        self.assertEqual(saved["outputs"]["DP-1"]["transform"], 1)
        command = run.call_args.args[0]
        self.assertEqual(command[:2], ["hyprctl", "eval"])
        self.assertIn('output = "DP-1"', command[2])
        self.assertIn('position = "2560x120"', command[2])
        self.assertIn("transform = 1", command[2])
        self.assertIn('output = "DP-2"', command[2])

    def test_arrange_requires_every_active_output(self) -> None:
        current = [monitor("DP-1", 0, 0), monitor("DP-2", 2560, 0)]
        with mock.patch.object(display, "monitors", return_value=current):
            with self.assertRaisesRegex(
                RuntimeError, "Arrangement must cover every active display"
            ):
                display.arrange(
                    {"DP-1": {"x": 0, "y": 0, "transform": 0}}
                )

    def test_arrange_rejects_overlap_after_rotation(self) -> None:
        current = [
            monitor("DP-1", 0, 0, transform=1),
            monitor("DP-2", 1440, 0),
        ]
        with mock.patch.object(display, "monitors", return_value=current):
            with self.assertRaisesRegex(
                RuntimeError, "rectangles overlap: DP-1 and DP-2"
            ):
                display.arrange(
                    {
                        "DP-1": {"x": 0, "y": 0, "transform": 0},
                        "DP-2": {"x": 1440, "y": 0, "transform": 0},
                    }
                )

    def test_preview_rejects_disabling_every_display(self) -> None:
        current = [monitor("DP-1", 0, 0), monitor("DP-2", 2560, 0)]
        layout = {
            "outputs": {
                "DP-1": {"enabled": False},
                "DP-2": {"enabled": False},
            },
        }
        with mock.patch.object(display, "monitors", return_value=current):
            with self.assertRaisesRegex(RuntimeError, "at least one display"):
                display.preview_layout(layout, now=100)

    def test_preview_applies_without_persisting_and_starts_watchdog(self) -> None:
        current = [monitor("DP-1", 0, 0), monitor("DP-2", 2560, 0)]
        previous = display.capture_layout(current, {"outputs": {}})
        display.save_layout(previous)
        proposed = json.loads(json.dumps(previous))
        proposed["outputs"]["DP-1"]["scale"] = 1.5

        with (
            mock.patch.object(display, "monitors", return_value=current),
            mock.patch.object(display, "apply_monitors") as apply,
            mock.patch.object(display, "spawn_watchdog") as spawn,
            mock.patch.object(display.uuid, "uuid4", return_value="trial-token"),
        ):
            result = display.preview_layout(proposed, timeout=10, now=100)

        self.assertEqual(result, {"token": "trial-token", "deadline": 110000})
        self.assertEqual(json.loads(self.state_path.read_text()), previous)
        apply.assert_called_once_with(proposed["outputs"])
        spawn.assert_called_once_with("trial-token", 110000)
        pending = json.loads(self.pending_path.read_text())
        self.assertEqual(pending["previousLayout"], previous)
        self.assertEqual(pending["proposedLayout"], proposed)

    def test_preview_preserves_disabled_display_settings(self) -> None:
        current = [monitor("DP-1", 0, 0), monitor("DP-2", 2560, 0)]
        previous = display.capture_layout(current, {"outputs": {}})
        proposed = json.loads(json.dumps(previous))
        proposed["outputs"]["DP-2"] = {"enabled": False}

        with (
            mock.patch.object(display, "monitors", return_value=current),
            mock.patch.object(display, "apply_monitors"),
            mock.patch.object(display, "spawn_watchdog"),
        ):
            display.preview_layout(proposed, timeout=10, now=100)

        disabled = json.loads(self.pending_path.read_text())["proposedLayout"][
            "outputs"
        ]["DP-2"]
        self.assertEqual(
            disabled,
            {
                "enabled": False,
                "mode": "2560x1440@143.999",
                "position": "2560x0",
                "scale": 1.0,
                "transform": 0,
            },
        )

    def test_apply_enables_outputs_before_disabling_others(self) -> None:
        configs = {
            "DP-1": {"enabled": False},
            "DP-2": {
                "enabled": True,
                "mode": "preferred",
                "position": "auto",
                "scale": "auto",
                "transform": 0,
            },
        }
        with mock.patch.object(display, "run", return_value="ok") as run:
            display.apply_monitors(configs)

        code = run.call_args.args[0][2]
        self.assertLess(code.index('output = "DP-2"'), code.index('output = "DP-1"'))

    def test_confirm_persists_proposed_layout_and_clears_trial(self) -> None:
        current = [monitor("DP-1", 0, 0)]
        previous = display.capture_layout(current, {"outputs": {}})
        display.save_layout(previous)
        proposed = json.loads(json.dumps(previous))
        proposed["outputs"]["DP-1"]["transform"] = 1

        with (
            mock.patch.object(display, "monitors", return_value=current),
            mock.patch.object(display, "apply_monitors"),
            mock.patch.object(display, "spawn_watchdog"),
            mock.patch.object(display.uuid, "uuid4", return_value="trial-token"),
        ):
            display.preview_layout(proposed, timeout=10, now=100)

        display.confirm_layout("trial-token", now=105)

        self.assertEqual(json.loads(self.state_path.read_text()), proposed)
        self.assertFalse(self.pending_path.exists())

    def test_revert_restores_previous_live_and_persistent_layout(self) -> None:
        current = [monitor("DP-1", 0, 0), monitor("DP-2", 2560, 0)]
        previous = display.capture_layout(current, {"outputs": {}})
        display.save_layout(previous)
        proposed = json.loads(json.dumps(previous))
        proposed["outputs"]["DP-2"]["enabled"] = False

        with (
            mock.patch.object(display, "monitors", return_value=current),
            mock.patch.object(display, "apply_monitors"),
            mock.patch.object(display, "spawn_watchdog"),
            mock.patch.object(display.uuid, "uuid4", return_value="trial-token"),
        ):
            display.preview_layout(proposed, timeout=10, now=100)

        with mock.patch.object(display, "apply_monitors") as apply:
            display.revert_layout("trial-token")

        self.assertEqual(json.loads(self.state_path.read_text()), previous)
        apply.assert_called_once_with(previous["outputs"])
        self.assertFalse(self.pending_path.exists())


if __name__ == "__main__":
    unittest.main()
