import tempfile
import unittest
from pathlib import Path

from PIL import Image

from theme_generator.preview import PREVIEW_SIZE, render_theme_preview
from theme_generator.render import DEFAULT_THEME_PATH, THEMES_DIR
from theme_generator.theme import hex_to_rgb, load_theme


class GraphicalPreviewTests(unittest.TestCase):
    def test_preview_renders_resolved_palette(self):
        theme = load_theme(THEMES_DIR / "loam" / "theme.yaml", DEFAULT_THEME_PATH)

        with tempfile.TemporaryDirectory(prefix="theme-preview-") as temporary_directory:
            output = Path(temporary_directory) / "loam.png"
            render_theme_preview(theme, "loam", output)

            with Image.open(output) as preview:
                self.assertEqual(preview.size, PREVIEW_SIZE)
                self.assertEqual(preview.getpixel((0, 0)), hex_to_rgb(theme["base"]["background"]))
                self.assertEqual(preview.getpixel((80, 200)), hex_to_rgb(theme["base"]["layer0"]))
                self.assertEqual(
                    preview.getpixel((200, 370)),
                    hex_to_rgb(theme["accent"]["primary"]["soft"]),
                )


if __name__ == "__main__":
    unittest.main()
