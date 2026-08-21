from .theme import flatten, hex_to_rgb


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
