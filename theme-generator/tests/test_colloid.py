import tempfile
import unittest
from pathlib import Path

from theme_generator.gtk import (
    COLLOID_INTERNAL_TEMPLATE,
    render_internal_colloid_palette,
    resolve_internal_template,
)
from theme_generator.render import DEFAULT_THEME_PATH, TEMPLATES_DIR, collect_templates
from theme_generator.theme import load_theme


ROOT = Path(__file__).resolve().parents[1]
THEMES_ROOT = ROOT.parent / "themes"


class ColloidTemplateTests(unittest.TestCase):
    def test_hidden_override_files_are_not_visible_outputs(self):
        with tempfile.TemporaryDirectory(prefix="theme-source-") as temporary_directory:
            theme_source = Path(temporary_directory)
            hidden = theme_source / "overrides" / ".internal" / "colloid"
            hidden.mkdir(parents=True)
            (hidden / "_color-palette.scss").write_text("override")

            files = collect_templates(theme_source)

            self.assertNotIn(COLLOID_INTERNAL_TEMPLATE, files)

    def test_default_internal_colloid_template_is_used_without_override(self):
        with tempfile.TemporaryDirectory(prefix="theme-source-") as temporary_directory:
            overrides = Path(temporary_directory) / "overrides"
            overrides.mkdir()

            resolved = resolve_internal_template(
                overrides,
                TEMPLATES_DIR,
                COLLOID_INTERNAL_TEMPLATE,
            )

            self.assertEqual(resolved, TEMPLATES_DIR / COLLOID_INTERNAL_TEMPLATE)

    def test_theme_internal_colloid_override_wins(self):
        with tempfile.TemporaryDirectory(prefix="theme-source-") as temporary_directory:
            overrides = Path(temporary_directory) / "overrides"
            override = overrides / COLLOID_INTERNAL_TEMPLATE
            override.parent.mkdir(parents=True)
            override.write_text("override")

            resolved = resolve_internal_template(
                overrides,
                TEMPLATES_DIR,
                COLLOID_INTERNAL_TEMPLATE,
            )

            self.assertEqual(resolved, override)

    def test_personal_internal_colloid_override_wins_over_built_in(self):
        with tempfile.TemporaryDirectory(prefix="theme-sources-") as temporary_directory:
            root = Path(temporary_directory)
            built_in = root / "built-in" / COLLOID_INTERNAL_TEMPLATE
            personal = root / "personal" / COLLOID_INTERNAL_TEMPLATE
            built_in.parent.mkdir(parents=True)
            personal.parent.mkdir(parents=True)
            built_in.write_text("built-in")
            personal.write_text("personal")

            resolved = resolve_internal_template(
                [root / "built-in", root / "personal"],
                TEMPLATES_DIR,
                COLLOID_INTERNAL_TEMPLATE,
            )

            self.assertEqual(resolved, personal)

    def test_default_internal_template_renders_expected_variables(self):
        theme = load_theme(THEMES_ROOT / "hyprkarl" / "theme.yaml", DEFAULT_THEME_PATH)

        rendered = render_internal_colloid_palette(
            theme_name="hyprkarl",
            palette=theme,
            theme_overrides=THEMES_ROOT / "hyprkarl" / "overrides",
            base_templates=TEMPLATES_DIR,
        )

        self.assertIn("$red-light: #dd6666;", rendered)
        self.assertIn("$purple-dark: #63005A;", rendered)
        self.assertIn("$default-dark: #a46fd6;", rendered)
        self.assertIn("$grey-950: #1b1519;", rendered)


if __name__ == "__main__":
    unittest.main()
