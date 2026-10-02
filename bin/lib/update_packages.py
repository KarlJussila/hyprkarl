#!/usr/bin/env python3
"""Build and atomically record Hyprkarl package update state."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Any


def parse_list(text: str) -> tuple[list[str], dict[str, str]]:
    packages: list[str] = []
    reasons: dict[str, str] = {}
    for raw_line in text.splitlines():
        value, _, comment = raw_line.partition("#")
        package = value.strip()
        if not package:
            continue
        packages.append(package)
        if comment.strip():
            reasons[package] = comment.strip()
    return sorted(set(packages)), reasons


def current_lists(packages_dir: Path) -> tuple[dict[str, list[str]], dict[str, str]]:
    lists: dict[str, list[str]] = {}
    remove_reasons: dict[str, str] = {}
    for name in ("pacman", "aur", "remove"):
        entries, reasons = parse_list((packages_dir / f"{name}.txt").read_text())
        lists[name] = entries
        if name == "remove":
            remove_reasons = reasons
    return lists, remove_reasons


def empty_state() -> dict[str, Any]:
    return {
        "schema": 1,
        "applied": {"pacman": [], "aur": []},
        "removalsReviewed": {"pacman": [], "aur": [], "remove": []},
    }


def load_state(path: Path) -> dict[str, Any]:
    if not path.exists():
        return empty_state()
    return json.loads(path.read_text())


def write_state(path: Path, state: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n")


def plan(packages_dir: Path, state_path: Path) -> dict[str, Any]:
    current, reasons = current_lists(packages_dir)
    state = load_state(state_path)
    applied = state["applied"]
    reviewed = state["removalsReviewed"]
    current_required = set(current["pacman"]) | set(current["aur"])
    old_required = set(reviewed["pacman"]) | set(reviewed["aur"])

    removals: dict[str, str] = {
        package: "No longer required"
        for package in sorted(old_required - current_required)
    }
    for package in sorted(set(current["remove"]) - set(reviewed["remove"])):
        removals[package] = reasons.get(package, "Added to the removal list")

    return {
        "current": current,
        "additions": {
            name: sorted(set(current[name]) - set(applied[name]))
            for name in ("pacman", "aur")
        },
        "removals": [
            {"package": package, "reason": reason}
            for package, reason in removals.items()
        ],
    }


def record(packages_dir: Path, state_path: Path, section: str) -> None:
    current, _ = current_lists(packages_dir)
    state = load_state(state_path)
    if section == "applied":
        state[section] = {name: current[name] for name in ("pacman", "aur")}
    else:
        state[section] = current
    if section == "removalsReviewed":
        for name in ("pacman", "aur"):
            state["applied"][name] = sorted(
                set(state["applied"][name]) & set(current[name])
            )
    write_state(state_path, state)


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    plan_parser = subparsers.add_parser("plan")
    plan_parser.add_argument("packages_dir", type=Path)
    plan_parser.add_argument("state", type=Path)

    record_parser = subparsers.add_parser("record")
    record_parser.add_argument("section", choices=("applied", "removalsReviewed"))
    record_parser.add_argument("packages_dir", type=Path)
    record_parser.add_argument("state", type=Path)

    args = parser.parse_args()
    if args.command == "plan":
        json.dump(plan(args.packages_dir, args.state), sys.stdout, separators=(",", ":"))
        print()
    else:
        record(args.packages_dir, args.state, args.section)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
