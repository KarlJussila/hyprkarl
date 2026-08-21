#!/usr/bin/env python3
"""Focused tests for package planning and atomic update state."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "update_packages", ROOT / "bin/lib/update_packages.py"
)
assert SPEC and SPEC.loader
update_packages = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(update_packages)


class PackageUpdateStateTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.packages = self.root / "packages"
        self.packages.mkdir()
        self.state = self.root / "state/packages.json"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_lists(self, pacman: str, aur: str, remove: str) -> None:
        (self.packages / "pacman.txt").write_text(pacman)
        (self.packages / "aur.txt").write_text(aur)
        (self.packages / "remove.txt").write_text(remove)

    def test_reviewed_removals_are_not_presented_again(self) -> None:
        self.write_lists("alpha\nbeta\n", "gamma\n", "old # superseded\n")
        first = update_packages.plan(self.packages, self.state)
        self.assertEqual(first["additions"]["pacman"], ["alpha", "beta"])
        self.assertEqual(
            first["removals"], [{"package": "old", "reason": "superseded"}]
        )

        update_packages.record(self.packages, self.state, "removalsReviewed")
        self.assertEqual(update_packages.plan(self.packages, self.state)["removals"], [])

    def test_moves_and_remove_comments_produce_one_correct_entry(self) -> None:
        self.write_lists("alpha\nbeta\n", "gamma\n", "")
        update_packages.record(self.packages, self.state, "applied")
        update_packages.record(self.packages, self.state, "removalsReviewed")

        self.write_lists("beta\n", "gamma\n", "alpha # replaced upstream\n")
        plan = update_packages.plan(self.packages, self.state)
        self.assertEqual(
            plan["removals"],
            [{"package": "alpha", "reason": "replaced upstream"}],
        )

        self.write_lists("beta\n", "alpha\ngamma\n", "")
        plan = update_packages.plan(self.packages, self.state)
        self.assertEqual(plan["removals"], [])
        self.assertEqual(plan["additions"]["aur"], ["alpha"])

    def test_review_removes_dropped_entries_from_applied_cursor(self) -> None:
        self.write_lists("alpha\nbeta\n", "", "")
        update_packages.record(self.packages, self.state, "applied")
        update_packages.record(self.packages, self.state, "removalsReviewed")

        self.write_lists("beta\n", "", "")
        update_packages.record(self.packages, self.state, "removalsReviewed")
        state = json.loads(self.state.read_text())
        self.assertEqual(state["applied"]["pacman"], ["beta"])

        self.write_lists("alpha\nbeta\n", "", "")
        self.assertEqual(
            update_packages.plan(self.packages, self.state)["additions"]["pacman"],
            ["alpha"],
        )

    def test_atomic_replacement_leaves_no_partial_state(self) -> None:
        self.write_lists("alpha\n", "", "")
        update_packages.record(self.packages, self.state, "applied")
        first = json.loads(self.state.read_text())

        stray = self.state.parent / ".packages.interrupted"
        stray.write_text("partial")
        self.assertEqual(json.loads(self.state.read_text()), first)

        self.write_lists("alpha\nbeta\n", "", "")
        update_packages.record(self.packages, self.state, "applied")
        self.assertEqual(
            json.loads(self.state.read_text())["applied"]["pacman"],
            ["alpha", "beta"],
        )


if __name__ == "__main__":
    unittest.main()
