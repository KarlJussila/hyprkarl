"""Shared fingerprint names, labels, and fprintd state."""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

FINGERPRINT_NAMES = (
    "left-thumb",
    "left-index-finger",
    "left-middle-finger",
    "left-ring-finger",
    "left-little-finger",
    "right-thumb",
    "right-index-finger",
    "right-middle-finger",
    "right-ring-finger",
    "right-little-finger",
)


def fingerprint_label(finger: str) -> str:
    return finger.replace("-", " ").title()


def fingerprint_is_setup() -> bool:
    if shutil.which("fprintd-list") is None:
        return False
    try:
        return "pam_fprintd.so" in Path("/etc/pam.d/sudo").read_text()
    except OSError:
        return False


def enrolled_fingers() -> list[str]:
    result = subprocess.run(
        ["fprintd-list", os.environ["USER"]],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(
            result.stderr.strip() or "could not list enrolled fingerprints"
        )

    return [
        line.split(": ", 1)[1]
        for line in result.stdout.splitlines()
        if line.startswith(" - #") and ": " in line
    ]
