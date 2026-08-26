from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MASK_PATH = ROOT / "assets" / "default-wallpaper-mask.png"
DEFAULT_WALLPAPER_NAME = "01-hyprkarl-wallpaper.png"
CANVAS_SIZE = (3840, 2160)
ACCENT_POSITION = (1329, 665)
ACCENT_DIM_POSITION = (1353, 689)


def generate_default_wallpaper(settings: dict, destination: Path) -> None:
    with Image.open(MASK_PATH) as source:
        mask = source.convert("L")

    wallpaper = Image.new("RGB", CANVAS_SIZE, settings["background"])
    for color, position in (
        (settings["accent_dim"], ACCENT_DIM_POSITION),
        (settings["accent"], ACCENT_POSITION),
    ):
        layer = Image.new("RGB", mask.size, color)
        wallpaper.paste(layer, position, mask)

    destination.parent.mkdir(parents=True, exist_ok=True)
    wallpaper.save(destination, format="PNG", optimize=True)
