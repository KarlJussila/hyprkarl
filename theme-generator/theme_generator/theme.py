import copy
import os
import tempfile
from pathlib import Path
from typing import Any

import colour
import jinja2
import yaml
from jinja2.nativetypes import NativeEnvironment


class ThemeError(ValueError):
    pass


def clamp(value: float) -> int:
    return max(0, min(255, round(value)))


def hex_to_rgb(color: str) -> tuple[int, int, int]:
    red, green, blue = colour.Color(color).rgb
    return clamp(red * 255), clamp(green * 255), clamp(blue * 255)


def luminance(color: str) -> float:
    return colour.Color(color).luminance


def rgba(color: str, alpha: float = 1.0) -> str:
    red, green, blue = hex_to_rgb(color)
    return f"rgba({red},{green},{blue},{alpha})"


def strip_hash(color: str) -> str:
    return color.lstrip("#")


def hyprrgb(color: str) -> str:
    return f"rgb({strip_hash(color)})"


def _adjust_hsl(color: str, lightness: float = 0, saturation: float = 0) -> str:
    value = colour.Color(color)
    hue, current_saturation, current_lightness = value.get_hsl()
    value.set_hsl(
        (
            hue,
            min(1.0, max(0.0, current_saturation + saturation / 100)),
            min(1.0, max(0.0, current_lightness + lightness / 100)),
        )
    )
    return value.hex_l


def lighten(color: str, percent: float) -> str:
    return _adjust_hsl(color, lightness=percent)


def darken(color: str, percent: float) -> str:
    return _adjust_hsl(color, lightness=-percent)


def saturate(color: str, percent: float) -> str:
    return _adjust_hsl(color, saturation=percent)


def rotate(color: str, degrees: float) -> str:
    value = colour.Color(color)
    hue, saturation_value, lightness_value = value.get_hsl()
    value.set_hsl(((hue + degrees / 360) % 1, saturation_value, lightness_value))
    return value.hex_l


def mix(first: str, second: str, percent: float) -> str:
    first_rgb = colour.Color(first).rgb
    second_rgb = colour.Color(second).rgb
    amount = percent / 100
    return colour.Color(
        rgb=tuple(a * (1 - amount) + b * amount for a, b in zip(first_rgb, second_rgb))
    ).hex_l


def contrast(first: str, second: str) -> float:
    first_luminance = luminance(first)
    second_luminance = luminance(second)
    return (max(first_luminance, second_luminance) + 0.05) / (
        min(first_luminance, second_luminance) + 0.05
    )


def ensure_contrast(foreground: str, background: str, target: float = 4.5) -> str:
    if contrast(foreground, background) >= target:
        return foreground

    foreground_oklab = colour.Color(foreground).oklab
    if luminance(background) < 0.5:
        low, high = foreground_oklab.L, 1.0
    else:
        low, high = 0.0, foreground_oklab.L

    best = foreground_oklab.L
    for _ in range(15):
        candidate_lightness = (low + high) / 2
        candidate_oklab = colour.Oklab(
            candidate_lightness,
            foreground_oklab.a,
            foreground_oklab.b,
        )
        candidate_rgb = colour.XYZ_to_RGB(colour.Oklab_to_XYZ(candidate_oklab)).get_srgb()[0]
        candidate = colour.Color(rgb=candidate_rgb).hex_l

        if contrast(candidate, background) >= target:
            best = candidate_lightness
            if luminance(background) < 0.5:
                high = candidate_lightness
            else:
                low = candidate_lightness
        elif luminance(background) < 0.5:
            low = candidate_lightness
        else:
            high = candidate_lightness

    final_oklab = colour.Oklab(best, foreground_oklab.a, foreground_oklab.b)
    final_rgb = colour.XYZ_to_RGB(colour.Oklab_to_XYZ(final_oklab)).get_srgb()[0]
    return colour.Color(rgb=final_rgb).hex_l


COLOR_FUNCTIONS = {
    "rgba": rgba,
    "strip_hash": strip_hash,
    "hyprrgb": hyprrgb,
    "lighten": lighten,
    "darken": darken,
    "mix": mix,
    "saturate": saturate,
    "rotate": rotate,
    "ensure_contrast": ensure_contrast,
    "contrast": contrast,
    "luminance": luminance,
}

TOKEN_ENVIRONMENT = NativeEnvironment(undefined=jinja2.StrictUndefined)
TEMPLATE_ENVIRONMENT = jinja2.Environment(
    undefined=jinja2.StrictUndefined,
)
TEMPLATE_ENVIRONMENT.policies["json.dumps_kwargs"] = {"sort_keys": False}
for environment in (TOKEN_ENVIRONMENT, TEMPLATE_ENVIRONMENT):
    environment.globals.update(COLOR_FUNCTIONS)
    environment.filters.update(COLOR_FUNCTIONS)

ANSI_NAMES = ("black", "red", "green", "yellow", "blue", "magenta", "cyan", "white")
REQUIRED_COLORS = (
    "base.background",
    "base.layer0",
    "base.layer1",
    "base.layer2",
    "base.layer3",
    "base.layer4",
    "base.surface_soft",
    "base.surface",
    "base.surface_alt",
    "base.foreground",
    "base.foreground_muted",
    "base.foreground_dim",
    *(f"ansi.{name}" for name in ANSI_NAMES),
    *(f"bright.{name}" for name in ANSI_NAMES),
    *(f"accent.{role}.{shade}" for role in ("primary", "secondary", "tertiary") for shade in ("base", "soft", "bright")),
    "status.success",
    "status.warning",
    "status.error",
    "status.urgent",
    "ui.cursor",
    "ui.text",
    "ui.text_secondary",
    "ui.selection_bg",
    "ui.selection_fg",
    "ui.panel",
    "ui.border",
    "ui.border_inner",
    "ui.border_soft",
    "ui.highlight",
)


def flatten(values: dict[str, Any], prefix: str = "") -> dict[str, Any]:
    flattened = {}
    for key, value in values.items():
        name = f"{prefix}.{key}" if prefix else key
        if isinstance(value, dict):
            flattened.update(flatten(value, name))
        else:
            flattened[name] = value
    return flattened


def deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    merged = copy.deepcopy(base)
    for key, value in override.items():
        if isinstance(value, dict) and isinstance(merged.get(key), dict):
            merged[key] = deep_merge(merged[key], value)
        else:
            merged[key] = copy.deepcopy(value)
    return merged


def _render_expressions(value: Any, root: dict[str, Any]) -> Any:
    if isinstance(value, dict):
        for key in value:
            value[key] = _render_expressions(value[key], root)
        return value
    if isinstance(value, list):
        for index in range(len(value)):
            value[index] = _render_expressions(value[index], root)
        return value
    if isinstance(value, str) and "{{" in value:
        try:
            return TOKEN_ENVIRONMENT.from_string(value).render(root)
        except (jinja2.UndefinedError, AttributeError, ValueError):
            return value
    return value


def resolve_theme(raw_theme: dict[str, Any]) -> dict[str, Any]:
    current = copy.deepcopy(raw_theme)
    for _ in range(len(flatten(current)) + 1):
        resolved = copy.deepcopy(current)
        _render_expressions(resolved, resolved)
        if resolved == current:
            break
        current = resolved

    unresolved = [
        key
        for key, value in flatten(current).items()
        if isinstance(value, str) and "{{" in value
    ]
    if unresolved:
        raise ThemeError(f"Unresolved theme expressions: {', '.join(unresolved)}")
    return current


def _add_bright_defaults(palette: dict[str, Any]) -> None:
    ansi = palette.get("ansi")
    if not isinstance(ansi, dict):
        raise ThemeError("Theme must define an ansi color group")
    bright = palette.setdefault("bright", {})
    if not isinstance(bright, dict):
        raise ThemeError("Theme bright group must be an object")
    for name in ANSI_NAMES:
        if name in ansi and name not in bright:
            bright[name] = f"{{{{ lighten(ansi.{name}, 20) }}}}"


def load_theme(
    path: str | Path,
    defaults_path: str | Path | None = None,
) -> dict[str, Any]:
    return load_theme_layers([path], defaults_path)


def _load_mapping(path: str | Path, label: str) -> dict[str, Any]:
    values = yaml.safe_load(Path(path).read_text())
    if not isinstance(values, dict):
        raise ThemeError(f"{label} root must be an object")
    return values


def load_theme_layers(
    paths: list[str | Path] | tuple[str | Path, ...],
    defaults_path: str | Path | None = None,
) -> dict[str, Any]:
    theme: dict[str, Any] = {}
    if defaults_path is not None:
        theme = _load_mapping(defaults_path, "Theme defaults")

    for path in paths:
        theme = deep_merge(theme, _load_mapping(path, "Theme"))

    _add_bright_defaults(theme)
    theme = resolve_theme(theme)
    mode = theme.setdefault("mode", "dark")
    if mode not in ("dark", "light"):
        raise ThemeError("Theme mode must be 'dark' or 'light'")

    flattened = flatten(theme)

    missing = [name for name in REQUIRED_COLORS if name not in flattened]
    if missing:
        raise ThemeError(f"Theme is missing required colors: {', '.join(missing)}")

    for name in REQUIRED_COLORS:
        try:
            colour.Color(flattened[name])
        except (AttributeError, ValueError) as error:
            raise ThemeError(f"Theme color {name} is invalid: {flattened[name]}") from error

    return theme


def render_template(text: str, context: dict[str, Any]) -> str:
    return TEMPLATE_ENVIRONMENT.from_string(text).render(context)


def write_atomic_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", delete=False, dir=path.parent) as handle:
        handle.write(text)
        temporary_path = handle.name
    os.replace(temporary_path, path)
