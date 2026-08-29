import json
import shutil
import tempfile
import unittest
from pathlib import Path

from theme_generator.render import THEMES_DIR, GenerationError, build_theme, iter_theme_names
from theme_generator.validation import validate_repository


class RepositoryValidationTests(unittest.TestCase):
    def test_every_theme_generates_cleanly(self):
        issues = validate_repository()
        if issues:
            self.fail("\n".join(f"{issue.theme}: {issue.message}" for issue in issues))

    @unittest.skipUnless(shutil.which("sassc"), "sassc is required for Colloid integration tests")
    def test_every_theme_builds_complete_bundle(self):
        for theme_name in iter_theme_names():
            with self.subTest(theme=theme_name):
                with tempfile.TemporaryDirectory(prefix=f"test-{theme_name}-") as temporary_directory:
                    output_root = Path(temporary_directory) / theme_name
                    build_theme(theme_name, output_root)

                    self.assertTrue((output_root / "theme.yaml").is_file())
                    self.assertTrue((output_root / "quickshell.json").is_file())
                    self.assertTrue((output_root / "gtk-3.0" / "gtk.css").is_file())
                    self.assertTrue((output_root / "gtk-4.0" / "gtk.css").is_file())
                    self.assertTrue((output_root / "gtk-theme" / "index.theme").is_file())
                    self.assertEqual(list(output_root.rglob(".internal")), [])

    def test_quickshell_theme_is_semantic_and_palette_derived(self):
        with tempfile.TemporaryDirectory(prefix="test-shell-theme-") as temporary_directory:
            hyprkarl_output = Path(temporary_directory) / "hyprkarl"
            gruvbox_output = Path(temporary_directory) / "gruvbox"
            build_theme("hyprkarl", hyprkarl_output)
            build_theme("gruvbox", gruvbox_output)

            hyprkarl = json.loads((hyprkarl_output / "quickshell.json").read_text())
            gruvbox = json.loads((gruvbox_output / "quickshell.json").read_text())

            self.assertEqual(hyprkarl["palette"]["foreground"], "#c7a3bf")
            self.assertEqual(hyprkarl["surfaces"]["bar"], "#1b1519")
            self.assertEqual(hyprkarl["surfaces"]["notification"], "#1b1519")
            self.assertNotEqual(hyprkarl["palette"]["accent"], gruvbox["palette"]["accent"])
            self.assertEqual(hyprkarl["bar"]["widgetPadding"], {"main": 6, "cross": 3})
            self.assertEqual(hyprkarl["metrics"]["borderWidth"], 2)
            self.assertEqual(
                hyprkarl["switch"],
                {
                    "trackLength": 24,
                    "trackHeight": 12,
                    "trackRadius": 6,
                    "thumbSize": 16,
                    "thumbRadius": 8,
                    "thumbPadding": 7,
                    "borderWidth": 2,
                    "markFilled": False,
                    "fontFamily": "JetBrains Mono Nerd Font Propo",
                    "fontSize": 9,
                    "onGlyphOffset": [0, 0],
                    "offGlyphOffset": [0, 0],
                    "transitionDuration": 140,
                },
            )
            self.assertEqual(hyprkarl["panel"]["outerBorderWidth"], 2)
            self.assertEqual(hyprkarl["panel"]["innerBorderWidth"], 2)
            self.assertEqual(hyprkarl["panel"]["selectionBorderWidth"], 1)
            self.assertEqual(hyprkarl["menu"]["selectionBorderWidth"], 1)
            self.assertEqual(hyprkarl["applicationPicker"]["iconSize"], 32)
            self.assertEqual(hyprkarl["calculator"]["width"], 480)
            self.assertEqual(
                hyprkarl["wallpaperPicker"],
                {
                    "widthScreenFraction": 0.82,
                    "previewHeightScreenFraction": 0.42,
                    "previewAspectRatio": 1.7777777778,
                    "carouselRadiusWidthFraction": 0.48,
                    "sideScale": 0.78,
                    "sideOpacity": 0.55,
                    "gap": 14,
                },
            )
            self.assertEqual(hyprkarl["notification"]["indicatorScale"], 1.5)
            self.assertEqual(hyprkarl["notification"]["stackSpacing"], 0)
            self.assertEqual(hyprkarl["notification"]["transitionDuration"], 140)
            self.assertEqual(hyprkarl["polkit"]["width"], 440)

    def test_custom_typed_vocabulary_reaches_generated_quickshell(self):
        with tempfile.TemporaryDirectory(prefix="test-custom-tokens-") as temporary_directory:
            temporary_root = Path(temporary_directory)
            source_root = temporary_root / "source"
            output_root = temporary_root / "output"
            source_root.mkdir()
            source = (THEMES_DIR / "hyprkarl" / "theme.yaml").read_text()
            source += """

widths:
  unit: 2
  standard_border: "{{widths.unit * 2}}"

shell:
  metrics:
    borderWidth: "{{widths.standard_border}}"
"""
            (source_root / "theme.yaml").write_text(source)

            build_theme(source_root, output_root)

            shell_theme = json.loads((output_root / "quickshell.json").read_text())
            resolved_theme = (output_root / "theme.yaml").read_text()
            self.assertEqual(shell_theme["metrics"]["borderWidth"], 4)
            self.assertIn("standard_border: 4", resolved_theme)

    def test_rebuild_replaces_stale_output(self):
        with tempfile.TemporaryDirectory(prefix="test-clean-build-") as temporary_directory:
            output_root = Path(temporary_directory) / "hyprkarl"
            output_root.mkdir()
            (output_root / "stale.conf").write_text("stale")

            build_theme("hyprkarl", output_root)

            self.assertFalse((output_root / "stale.conf").exists())

    def test_explicit_theme_name_reaches_generated_consumers(self):
        with tempfile.TemporaryDirectory(prefix="test-theme-name-") as temporary_directory:
            output_root = Path(temporary_directory) / "renamed"
            build_theme("hyprkarl", output_root, "renamed")

            self.assertIn("Name=renamed", (output_root / "gtk-theme" / "index.theme").read_text())

    def test_theme_icon_choice_reaches_desktop_consumers(self):
        with tempfile.TemporaryDirectory(prefix="test-theme-icons-") as temporary_directory:
            root = Path(temporary_directory)
            for theme_name, icon_theme in (
                ("loam", "Yaru-olive-dark"),
                ("tokyo-night", "Yaru-blue-dark"),
            ):
                with self.subTest(theme=theme_name):
                    output = root / theme_name
                    build_theme(theme_name, output)
                    self.assertEqual((output / "icons.theme").read_text().strip(), icon_theme)
                    self.assertIn(
                        f"IconTheme={icon_theme}",
                        (output / "gtk-theme" / "index.theme").read_text(),
                    )

    def test_theme_without_wallpaper_assets_still_builds_complete_bundle(self):
        with tempfile.TemporaryDirectory(prefix="test-no-wallpapers-") as temporary_directory:
            source_root = Path(temporary_directory) / "source"
            output_root = Path(temporary_directory) / "output"
            source_root.mkdir()
            shutil.copy2(THEMES_DIR / "hyprkarl" / "theme.yaml", source_root / "theme.yaml")

            build_theme(source_root, output_root)

            self.assertTrue((output_root / "wallpapers").is_dir())
            self.assertEqual(list((output_root / "wallpapers").iterdir()), [])

    def test_qt_color_schemes_are_palette_derived(self):
        with tempfile.TemporaryDirectory(prefix="test-qt-themes-") as temporary_directory:
            hyprkarl_root = Path(temporary_directory) / "hyprkarl"
            gruvbox_root = Path(temporary_directory) / "gruvbox"
            build_theme("hyprkarl", hyprkarl_root)
            build_theme("gruvbox", gruvbox_root)

            self.assertNotEqual(
                (hyprkarl_root / "qt5ct" / "style-colors.conf").read_text(),
                (gruvbox_root / "qt5ct" / "style-colors.conf").read_text(),
            )
            self.assertNotEqual(
                (hyprkarl_root / "qt6ct" / "style-colors.conf").read_text(),
                (gruvbox_root / "qt6ct" / "style-colors.conf").read_text(),
            )


if __name__ == "__main__":
    unittest.main()
