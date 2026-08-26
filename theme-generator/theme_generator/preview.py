from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from .theme import contrast, flatten, hex_to_rgb

PREVIEW_SIZE = (1600, 1000)


def foreground(color: str, text: str) -> str:
    red, green, blue = hex_to_rgb(color)
    return f"\033[38;2;{red};{green};{blue}m{text}\033[0m"


def background(color: str, text: str) -> str:
    red, green, blue = hex_to_rgb(color)
    return f"\033[48;2;{red};{green};{blue}m{text}\033[0m"


def foreground_background(foreground_color: str, background_color: str, text: str) -> str:
    red, green, blue = hex_to_rgb(foreground_color)
    bg_red, bg_green, bg_blue = hex_to_rgb(background_color)
    return (
        f"\033[38;2;{red};{green};{blue}m"
        f"\033[48;2;{bg_red};{bg_green};{bg_blue}m{text}\033[0m"
    )


def divider(palette: dict, title: str) -> None:
    print()
    print(foreground(palette["accent.primary.bright"], title))
    print(foreground(palette["base.foreground_dim"], "─" * 60))


def show_theme(theme: dict) -> None:
    palette = flatten(theme)
    print("\nUI COLORS\n")
    for name, value in palette.items():
        if isinstance(value, str) and value.startswith("#") and name.startswith(
            ("base", "accent", "status", "ui")
        ):
            print(background(value, "   "), name, value)

    divider(palette, "Log Output")
    print(foreground(palette["status.success"], "✔ Build succeeded"))
    print(foreground(palette["status.warning"], "⚠ Warning: palette contrast low"))
    print(foreground(palette["status.error"], "✖ Error: template variable missing"))
    print(foreground(palette["status.urgent"], "‼ Critical: config not found"))

    divider(palette, "Selection")
    print(
        foreground_background(
            palette["ui.selection_fg"],
            palette["ui.selection_bg"],
            " This text is selected in the terminal ",
        )
    )

    divider(palette, "ANSI Colors")
    names = ("black", "red", "green", "yellow", "blue", "magenta", "cyan", "white")
    print(" ".join(background(palette[f"ansi.{name}"], "   ") for name in names))
    print(" ".join(background(palette[f"bright.{name}"], "   ") for name in names))

    divider(palette, "Background Layers")
    for index in range(5):
        name = f"base.layer{index}"
        print(
            background(
                palette[name],
                foreground(palette["base.foreground"], f"  {name}  {palette[name]}  "),
            )
        )

    divider(palette, "Shell Prompt")
    user = foreground(palette["accent.primary.soft"], "karl")
    host = foreground(palette["ansi.blue"], "hyprbox")
    path = foreground(palette["ansi.cyan"], "~/projects/theme-generator")
    print(f"{user}@{host} {path}")
    print(
        foreground(palette["ui.cursor"], "❯ ")
        + foreground(palette["base.foreground"], "hyprkarl-theme build")
    )

    divider(palette, "Code Sample")
    print(foreground(palette["base.foreground_dim"], "# palette generation example"))
    print(
        foreground(palette["ansi.magenta"], "def ")
        + foreground(palette["ansi.blue"], "build_theme")
        + foreground(palette["base.foreground"], "():")
    )
    print(
        "    "
        + foreground(palette["ansi.magenta"], "return ")
        + foreground(palette["ansi.green"], '\"theme generated successfully\"')
    )


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    return ImageFont.load_default(size=size)


def _label_color(color: str) -> str:
    dark = "#111111"
    light = "#f5f2eb"
    return light if contrast(light, color) >= contrast(dark, color) else dark


def _swatch(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    color: str,
    label: str,
    value: str,
    *,
    radius: int = 12,
) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=color)
    text_color = _label_color(color)
    draw.text((box[0] + 14, box[1] + 12), label, fill=text_color, font=_font(17))
    draw.text((box[0] + 14, box[3] - 30), value, fill=text_color, font=_font(14))


def _section_title(draw: ImageDraw.ImageDraw, x: int, y: int, title: str, color: str) -> None:
    draw.text((x, y), title, fill=color, font=_font(21))


def render_theme_preview(theme: dict, theme_name: str, output_path: str | Path) -> Path:
    palette = flatten(theme)
    output = Path(output_path).expanduser().resolve()
    background = palette["base.background"]
    foreground_color = palette["base.foreground"]
    muted = palette["base.foreground_muted"]
    surface = palette["base.surface"]
    surface_alt = palette["base.surface_alt"]
    accent = palette["accent.primary.base"]
    accent_bright = palette["accent.primary.bright"]

    image = Image.new("RGB", PREVIEW_SIZE, hex_to_rgb(background))
    draw = ImageDraw.Draw(image)

    draw.rounded_rectangle((32, 32, 1568, 968), radius=24, fill=surface, outline=accent, width=3)
    draw.rectangle((32, 32, 46, 968), fill=accent)
    draw.text((72, 56), theme_name.replace("-", " ").upper(), fill=foreground_color, font=_font(38))
    icon_theme = theme.get("desktop", {}).get("icon_theme", "Adwaita")
    draw.text(
        (72, 106),
        f"{theme['mode']} theme   /   {icon_theme}",
        fill=muted,
        font=_font(17),
    )

    left_x = 72
    left_width = 920
    right_x = 1030
    right_width = 490

    _section_title(draw, left_x, 154, "Surfaces", accent_bright)
    surface_names = ("layer0", "layer1", "layer2", "layer3", "layer4")
    swatch_gap = 10
    swatch_width = (left_width - swatch_gap * 4) // 5
    for index, name in enumerate(surface_names):
        color = palette[f"base.{name}"]
        x = left_x + index * (swatch_width + swatch_gap)
        _swatch(draw, (x, 190, x + swatch_width, 286), color, name, color)

    _section_title(draw, left_x, 320, "Accents", accent_bright)
    accent_names = ("primary", "secondary", "tertiary")
    shade_names = ("soft", "base", "bright")
    for row, accent_name in enumerate(accent_names):
        y = 358 + row * 84
        draw.text((left_x, y + 24), accent_name, fill=muted, font=_font(17))
        for column, shade_name in enumerate(shade_names):
            color = palette[f"accent.{accent_name}.{shade_name}"]
            x = left_x + 118 + column * 268
            _swatch(draw, (x, y, x + 252, y + 68), color, shade_name, color, radius=10)

    _section_title(draw, left_x, 622, "ANSI", accent_bright)
    ansi_names = ("black", "red", "green", "yellow", "blue", "magenta", "cyan", "white")
    ansi_width = (left_width - 7 * 8) // 8
    for column, name in enumerate(ansi_names):
        x = left_x + column * (ansi_width + 8)
        for row, group in enumerate(("ansi", "bright")):
            color = palette[f"{group}.{name}"]
            y = 660 + row * 76
            label = name if row == 0 else "bright"
            _swatch(draw, (x, y, x + ansi_width, y + 62), color, label, color, radius=8)

    _section_title(draw, left_x, 824, "Status", accent_bright)
    status_names = ("success", "warning", "error", "urgent")
    status_width = (left_width - 3 * 12) // 4
    for index, name in enumerate(status_names):
        color = palette[f"status.{name}"]
        x = left_x + index * (status_width + 12)
        _swatch(draw, (x, 862, x + status_width, 932), color, name, color, radius=10)

    _section_title(draw, right_x, 154, "Interface sample", accent_bright)
    draw.rounded_rectangle(
        (right_x, 190, right_x + right_width, 556),
        radius=18,
        fill=background,
        outline=palette["ui.border"],
        width=2,
    )

    draw.rounded_rectangle((right_x + 18, 208, right_x + right_width - 18, 244), radius=9, fill=surface_alt)
    draw.text((right_x + 32, 217), "1   2   3   4", fill=muted, font=_font(14))
    draw.text((right_x + right_width - 126, 217), "10:42", fill=foreground_color, font=_font(14))

    draw.rounded_rectangle(
        (right_x + 48, 274, right_x + right_width - 48, 530),
        radius=14,
        fill=surface,
        outline=palette["ui.border_soft"],
        width=2,
    )
    draw.rounded_rectangle(
        (right_x + 66, 294, right_x + right_width - 66, 338),
        radius=8,
        fill=surface_alt,
        outline=palette["ui.border_inner"],
        width=1,
    )
    draw.text((right_x + 82, 306), "Search applications", fill=muted, font=_font(15))
    sample_rows = ("Terminal", "Files", "Settings", "Theme preview")
    for index, label in enumerate(sample_rows):
        y = 354 + index * 40
        if index == 1:
            draw.rounded_rectangle(
                (right_x + 66, y, right_x + right_width - 66, y + 34),
                radius=7,
                fill=palette["ui.selection_bg"],
                outline=accent,
                width=1,
            )
            row_color = palette["ui.selection_fg"]
        else:
            row_color = foreground_color
        draw.ellipse((right_x + 80, y + 9, right_x + 96, y + 25), fill=palette[f"ansi.{ansi_names[index + 2]}"])
        draw.text((right_x + 108, y + 8), label, fill=row_color, font=_font(15))

    _section_title(draw, right_x, 592, "Notification", accent_bright)
    draw.rounded_rectangle(
        (right_x, 630, right_x + right_width, 744),
        radius=16,
        fill=background,
        outline=palette["ui.border"],
        width=2,
    )
    draw.ellipse((right_x + 20, 650, right_x + 68, 698), fill=accent)
    draw.text((right_x + 84, 648), "Theme applied", fill=foreground_color, font=_font(18))
    draw.text((right_x + 84, 681), "All generated consumers reloaded", fill=muted, font=_font(14))
    draw.rectangle((right_x + 20, 726, right_x + right_width - 20, 730), fill=accent_bright)

    _section_title(draw, right_x, 780, "Contrast", accent_bright)
    contrast_pairs = (
        ("text / background", palette["ui.text"], background),
        ("muted / surface", muted, surface),
        ("selection", palette["ui.selection_fg"], palette["ui.selection_bg"]),
    )
    for index, (label, first, second) in enumerate(contrast_pairs):
        y = 820 + index * 38
        ratio = contrast(first, second)
        ratio_color = palette["status.success"] if ratio >= 4.5 else palette["status.warning"]
        draw.text((right_x, y), label, fill=foreground_color, font=_font(15))
        draw.rounded_rectangle((right_x + 350, y - 2, right_x + 488, y + 28), radius=8, fill=ratio_color)
        draw.text(
            (right_x + 419, y + 4),
            f"{ratio:.2f}:1",
            fill=_label_color(ratio_color),
            font=_font(14),
            anchor="ma",
        )

    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output)
    return output
