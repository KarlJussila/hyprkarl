import json
import tempfile
import unittest
from pathlib import Path

from theme_generator.render import THEMES_DIR, GenerationError, build_theme


class SourceLayerTests(unittest.TestCase):
    def test_personal_graph_merges_before_expression_resolution(self):
        with tempfile.TemporaryDirectory(prefix="theme-overlay-") as temporary_directory:
            root = Path(temporary_directory)
            overlay = root / "overlay"
            output = root / "output"
            overlay.mkdir()
            (overlay / "theme.yaml").write_text(
                """
personal:
  border_width: 5

shell:
  metrics:
    borderWidth: "{{personal.border_width}}"
"""
            )

            build_theme("hyprkarl", output, overlay_source=overlay)

            shell_theme = json.loads((output / "quickshell.json").read_text())
            self.assertEqual(shell_theme["metrics"]["borderWidth"], 5)

    def test_personal_overrides_and_assets_win_over_built_in_sources(self):
        with tempfile.TemporaryDirectory(prefix="theme-assets-") as temporary_directory:
            root = Path(temporary_directory)
            built_in = root / "built-in"
            overlay = root / "overlay"
            output = root / "output"
            built_in.mkdir()
            overlay.mkdir()
            (built_in / "theme.yaml").write_text(
                (THEMES_DIR / "hyprkarl" / "theme.yaml").read_text()
            )
            for source, icon_name, wallpaper in (
                (built_in, "Built In Icons", "built-in"),
                (overlay, "Personal Icons", "personal"),
            ):
                (source / "overrides").mkdir()
                (source / "overrides" / "icons.theme").write_text(icon_name)
                (source / "wallpapers").mkdir()
                (source / "wallpapers" / "shared.txt").write_text(wallpaper)

            build_theme(built_in, output, overlay_source=overlay)

            self.assertEqual((output / "icons.theme").read_text(), "Personal Icons")
            self.assertEqual(
                (output / "wallpapers" / "shared.txt").read_text(),
                "personal",
            )

    def test_same_name_overlay_may_contain_only_overrides_and_assets(self):
        with tempfile.TemporaryDirectory(prefix="theme-overlay-only-") as temporary_directory:
            root = Path(temporary_directory)
            overlay = root / "hyprkarl"
            output = root / "output"
            (overlay / "wallpapers").mkdir(parents=True)
            (overlay / "wallpapers" / "personal.txt").write_text("personal")

            build_theme("hyprkarl", output, overlay_source=overlay)

            self.assertTrue((output / "wallpapers" / "personal.txt").is_file())

    def test_user_only_theme_requires_theme_yaml(self):
        with tempfile.TemporaryDirectory(prefix="theme-user-only-") as temporary_directory:
            root = Path(temporary_directory)
            overlay = root / "personal"
            output = root / "output"
            overlay.mkdir()

            with self.assertRaises(GenerationError):
                build_theme("not-a-built-in", output, overlay_source=overlay)

            (overlay / "theme.yaml").write_text(
                (THEMES_DIR / "hyprkarl" / "theme.yaml").read_text()
            )
            build_theme("not-a-built-in", output, overlay_source=overlay)
            self.assertTrue((output / "quickshell.json").is_file())

    def test_wallpaper_disable_marker_removes_inherited_asset(self):
        with tempfile.TemporaryDirectory(prefix="theme-wallpapers-") as temporary_directory:
            root = Path(temporary_directory)
            built_in = root / "built-in"
            overlay = root / "overlay"
            output = root / "output"
            (built_in / "wallpapers").mkdir(parents=True)
            overlay.mkdir()
            (built_in / "theme.yaml").write_text(
                (THEMES_DIR / "hyprkarl" / "theme.yaml").read_text()
            )
            (built_in / "wallpapers" / "keep.txt").write_text("keep")
            (built_in / "wallpapers" / "remove.txt").write_text("remove")
            (overlay / ".wallpapers-disabled").write_text("remove.txt\n")

            build_theme(built_in, output, overlay_source=overlay)

            self.assertTrue((output / "wallpapers" / "keep.txt").is_file())
            self.assertFalse((output / "wallpapers" / "remove.txt").exists())

    def test_failed_complete_bundle_validation_preserves_destination(self):
        with tempfile.TemporaryDirectory(prefix="theme-preserve-") as temporary_directory:
            root = Path(temporary_directory)
            overlay = root / "overlay"
            output = root / "output"
            (overlay / "overrides").mkdir(parents=True)
            (overlay / "overrides" / "quickshell.json").write_text("{invalid")
            output.mkdir()
            (output / "keep.txt").write_text("original")

            with self.assertRaises(GenerationError):
                build_theme("hyprkarl", output, overlay_source=overlay)

            self.assertEqual((output / "keep.txt").read_text(), "original")

    def test_light_mode_builds_light_colloid_and_settings(self):
        with tempfile.TemporaryDirectory(prefix="theme-light-") as temporary_directory:
            root = Path(temporary_directory)
            overlay = root / "overlay"
            light_output = root / "light"
            dark_output = root / "dark"
            overlay.mkdir()
            (overlay / "theme.yaml").write_text("mode: light\n")

            build_theme("hyprkarl", light_output, overlay_source=overlay)
            build_theme("hyprkarl", dark_output)

            gtk3_light = (light_output / "gtk-3.0" / "gtk.css").read_text()
            gtk4_light = (light_output / "gtk-4.0" / "gtk.css").read_text()
            self.assertTrue((light_output / "light.mode").is_file())
            self.assertFalse((dark_output / "light.mode").exists())
            self.assertNotEqual(
                gtk3_light,
                (dark_output / "gtk-3.0" / "gtk.css").read_text(),
            )
            self.assertNotEqual(
                gtk4_light,
                (dark_output / "gtk-4.0" / "gtk.css").read_text(),
            )
            self.assertEqual(
                gtk3_light,
                (light_output / "gtk-3.0" / "gtk-dark.css").read_text(),
            )
            self.assertEqual(
                gtk4_light,
                (light_output / "gtk-4.0" / "gtk-dark.css").read_text(),
            )


if __name__ == "__main__":
    unittest.main()
