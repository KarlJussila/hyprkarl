"""Read and format the live Hyprland keybinding registry."""

from __future__ import annotations

import json
import re
import subprocess

MODIFIERS = {
    0: "",
    1: "SHIFT",
    4: "CTRL",
    5: "SHIFT CTRL",
    8: "ALT",
    9: "SHIFT ALT",
    12: "CTRL ALT",
    13: "SHIFT CTRL ALT",
    64: "SUPER",
    65: "SUPER SHIFT",
    68: "SUPER CTRL",
    69: "SUPER SHIFT CTRL",
    72: "SUPER ALT",
    73: "SUPER SHIFT ALT",
    76: "SUPER CTRL ALT",
    77: "SUPER SHIFT CTRL ALT",
}

POINTER_BUTTONS = {
    "mouse:272": "LEFT MOUSE BUTTON",
    "mouse:273": "RIGHT MOUSE BUTTON",
    "mouse:274": "MIDDLE MOUSE BUTTON",
}


def live_bindings() -> list[dict]:
    result = subprocess.run(
        ["hyprctl", "-j", "binds"],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "could not read Hyprland bindings")

    try:
        bindings = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError("Hyprland returned invalid binding data") from error
    if not isinstance(bindings, list):
        raise TypeError("Hyprland returned invalid binding data")
    return bindings


def binding_label(binding: dict) -> str | None:
    modmask = binding.get("modmask") or 0
    modifiers = MODIFIERS.get(modmask, str(modmask))

    key = binding.get("key") or ""
    keycode = binding.get("keycode") or 0
    if not key and keycode:
        key = f"code:{keycode}"
    key = POINTER_BUTTONS.get(key, key)

    combo = " + ".join(part for part in (modifiers, key) if part).strip()
    description = binding.get("description") or ""
    if description:
        action = description
    else:
        dispatcher = binding.get("dispatcher") or ""
        argument = binding.get("arg") or ""
        action = (
            argument
            if dispatcher == "exec"
            else ",".join(part for part in (dispatcher, argument) if part)
        )

    action = action.replace("uwsm app -- ", "").replace("uwsm-app -- ", "").strip()
    if not action:
        return None
    return f"{combo:<35} → {action}"


def binding_priority(label: str) -> int:
    priority = 50
    if "Terminal" in label:
        priority = 1
    if "Launch apps" in label:
        priority = 3
    if "Main menu" in label:
        priority = 4
    if "Browser" in label and "private" not in label:
        priority = 5
    if "File manager" in label and "Alternative" not in label:
        priority = 7
    if "Alternative file manager" in label:
        priority = 8
    if "Close window" in label:
        priority = 9
    if "Force kill window" in label:
        priority = 10
    if "Full screen" in label:
        priority = 11
    if "Toggle window floating" in label:
        priority = 12
    if "Toggle window split" in label:
        priority = 13
    if "Power menu" in label:
        priority = 14
    if "Wallpaper menu" in label:
        priority = 15
    if "Screenshot" in label:
        priority = 16
    if "notification" in label:
        priority = 17
    if "Switch to workspace" in label:
        priority = 18
    if "Move window to workspace" in label and "silently" not in label:
        priority = 20
    if re.search(r"Toggle scratchpad|Move window.*scratchpad", label):
        priority = 22
    if "XF86" in label or "Lid Switch" in label:
        priority = 99
    return priority


def keybinding_labels() -> list[str]:
    labels = {
        label
        for binding in live_bindings()
        if (label := binding_label(binding)) is not None
    }
    return sorted(labels, key=lambda label: (binding_priority(label), label))
