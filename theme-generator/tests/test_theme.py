import tempfile
import unittest
from pathlib import Path

from theme_generator.render import DEFAULT_THEME_PATH
from theme_generator.theme import ThemeError, darken, flatten, lighten, load_theme


ROOT = Path(__file__).resolve().parents[1]
THEMES_ROOT = ROOT.parent / "themes"


class LoadThemeTests(unittest.TestCase):
    def test_nested_derivations_resolve_before_color_functions(self):
        theme = flatten(
            load_theme(THEMES_ROOT / "hyprkarl" / "theme.yaml", DEFAULT_THEME_PATH)
        )

        self.assertEqual(theme["base.layer0"], "#1b1519")
        self.assertEqual(theme["base.layer1"], lighten("#1b1519", 3))
        self.assertEqual(theme["base.layer2"], lighten("#1b1519", 7))
        self.assertEqual(theme["base.layer3"], lighten("#1b1519", 10))
        self.assertEqual(theme["base.layer4"], lighten("#1b1519", 14))
        self.assertEqual(theme["base.surface"], theme["base.layer2"])
        self.assertEqual(theme["base.foreground_muted"], darken("#d2ccd2", 13))

    def test_custom_tokens_resolve_with_native_types(self):
        source = (THEMES_ROOT / "hyprkarl" / "theme.yaml").read_text()
        source += """

custom_vocabulary:
  unit: 2
  ratio: 1.5
  enabled: true
  family: "Custom UI"
  border: "{{custom_vocabulary.unit * 2}}"
  scale: "{{custom_vocabulary.ratio + 0.25}}"
  visible: "{{custom_vocabulary.enabled}}"
  label: "{{custom_vocabulary.family}}"

shell:
  metrics:
    borderWidth: "{{custom_vocabulary.border}}"
"""
        with tempfile.TemporaryDirectory(prefix="typed-theme-") as temporary_directory:
            theme_path = Path(temporary_directory) / "theme.yaml"
            theme_path.write_text(source)
            theme = load_theme(theme_path, DEFAULT_THEME_PATH)

        self.assertEqual(theme["custom_vocabulary"]["border"], 4)
        self.assertEqual(theme["custom_vocabulary"]["scale"], 1.75)
        self.assertIs(theme["custom_vocabulary"]["visible"], True)
        self.assertEqual(theme["custom_vocabulary"]["label"], "Custom UI")
        self.assertEqual(theme["shell"]["metrics"]["borderWidth"], 4)

    def test_unresolved_expression_is_rejected_at_the_theme_boundary(self):
        source = (THEMES_ROOT / "hyprkarl" / "theme.yaml").read_text()
        with tempfile.TemporaryDirectory(prefix="bad-palette-") as temporary_directory:
            theme_path = Path(temporary_directory) / "theme.yaml"
            theme_path.write_text(source.replace("#1b1519", "{{missing.color}}", 1))

            with self.assertRaises(ThemeError):
                load_theme(theme_path, DEFAULT_THEME_PATH)


if __name__ == "__main__":
    unittest.main()
