import logging
import re
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Iterable

from .theme import render_template, write_atomic_text

logger = logging.getLogger(__name__)

ROOT = Path(__file__).resolve().parents[1]
VENDOR_COLLOID_DIR = ROOT / "vendor" / "colloid"
COLLOID_INTERNAL_TEMPLATE = Path(".internal/colloid/_color-palette.scss")

HEX_COLOR_RE = re.compile(r"^#[0-9a-fA-F]{6}$")
SCSS_VAR_RE = re.compile(r"^\s*\$([A-Za-z0-9_-]+):\s*([^;]+);")


class ColloidBuildError(RuntimeError):
    pass


def resolve_internal_template(
    theme_overrides: Path | Iterable[Path],
    base_templates: Path,
    relative_path: Path,
) -> Path:
    override_directories = (
        (theme_overrides,) if isinstance(theme_overrides, Path) else tuple(theme_overrides)
    )
    for override_directory in reversed(override_directories):
        override_source = override_directory / relative_path
        if override_source.is_file():
            return override_source

    base_source = base_templates / relative_path
    if base_source.is_file():
        return base_source

    raise ColloidBuildError(f"Missing internal Colloid template: {relative_path}")


def render_internal_colloid_palette(
    theme_name: str,
    palette: dict,
    theme_overrides: Path | Iterable[Path],
    base_templates: Path,
    template_relative_path: Path = COLLOID_INTERNAL_TEMPLATE,
) -> str:
    source_path = resolve_internal_template(theme_overrides, base_templates, template_relative_path)
    context = {**palette, "theme_name": theme_name}
    try:
        return render_template(source_path.read_text(), context)
    except Exception as exc:
        raise ColloidBuildError(
            f"Failed to render Colloid palette template {template_relative_path}: {exc}"
        ) from exc


def _copy_vendor_workspace(workspace_root: Path) -> None:
    if not VENDOR_COLLOID_DIR.exists():
        raise ColloidBuildError(f"Vendored Colloid source not found: {VENDOR_COLLOID_DIR}")
    shutil.copytree(VENDOR_COLLOID_DIR, workspace_root, dirs_exist_ok=True)


def _write_tweaks_file(workspace_root: Path, palette_stub: str) -> None:
    tweaks_path = workspace_root / "src" / "sass" / "_tweaks-temp.scss"
    tweaks_path.write_text(
        "\n".join(
            [
                f"@import 'color-palette-{palette_stub}';",
                "",
                "$colorscheme: 'default';",
                "$colortype: 'fixed';",
                "$opacity: 'default';",
                "$theme: 'default';",
                "$compact: 'false';",
                "$translucent: 'false';",
                "$panel_opacity: 1.0;",
                "$blackness: 'false';",
                "$rimless: 'false';",
                "$window_button: 'mac';",
                "$float: 'false';",
                "$gnome_version: 'default';",
                "",
            ]
        )
    )


def _run_sassc(input_path: Path, output_path: Path) -> None:
    try:
        subprocess.run(
            ["sassc", "-M", "-t", "expanded", str(input_path), str(output_path)],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as exc:
        raise ColloidBuildError("sassc is required to generate Colloid GTK output") from exc
    except subprocess.CalledProcessError as exc:
        stderr = exc.stderr.strip() or exc.stdout.strip() or str(exc)
        raise ColloidBuildError(f"Colloid sassc build failed for {input_path.name}: {stderr}") from exc


def _parse_palette_variables(rendered_palette: str) -> dict:
    raw = {}
    for line in rendered_palette.splitlines():
        match = SCSS_VAR_RE.match(line)
        if match:
            raw[match.group(1)] = match.group(2).strip()

    resolved = {}
    pending = dict(raw)
    while pending:
        progress = False
        for name, value in list(pending.items()):
            if HEX_COLOR_RE.fullmatch(value):
                resolved[name] = value
            elif value.startswith("$") and value[1:] in resolved:
                resolved[name] = resolved[value[1:]]
            else:
                continue
            del pending[name]
            progress = True
        if not progress:
            break
    return {k: v.lower() for k, v in resolved.items()}


def _require_palette_color(palette_vars: dict, name: str) -> str:
    value = palette_vars.get(name)
    if value and HEX_COLOR_RE.fullmatch(value):
        return value
    raise ColloidBuildError(f"Rendered Colloid palette is missing a concrete hex value for ${name}")


def _replace_svg_colors(path: Path, replacements: dict) -> None:
    text = path.read_text()
    for source, target in replacements.items():
        text = text.replace(source, target)
    write_atomic_text(path, text)


def _copy_and_recolor_assets(
    workspace_root: Path,
    output_root: Path,
    palette_vars: dict,
    mode: str,
) -> None:
    assets_source = workspace_root / "src" / "assets" / "gtk" / "assets"
    symbolics_source = workspace_root / "src" / "assets" / "gtk" / "symbolics"
    thumbnail = workspace_root / "src" / "assets" / "gtk" / (
        "thumbnail-Dark.svg" if mode == "dark" else "thumbnail.svg"
    )

    replacements = {
        "#5b9bf8": _require_palette_color(palette_vars, "default-light"),
        "#3c84f7": _require_palette_color(palette_vars, "default-dark"),
        "#ffffff": _require_palette_color(palette_vars, "white"),
        "#000000": _require_palette_color(palette_vars, "black"),
        "#f2f2f2": _require_palette_color(palette_vars, "grey-050"),
        "#2c2c2c": _require_palette_color(palette_vars, "grey-700"),
        "#3c3c3c": _require_palette_color(palette_vars, "grey-650"),
    }

    for gtk_dir_name in ("gtk-3.0", "gtk-4.0"):
        gtk_dir = output_root / gtk_dir_name
        assets_dest = gtk_dir / "assets"
        thumbnail_dest = gtk_dir / "thumbnail.png"

        shutil.rmtree(assets_dest, ignore_errors=True)
        shutil.copytree(assets_source, assets_dest)
        for svg_path in symbolics_source.glob("*.svg"):
            shutil.copy2(svg_path, assets_dest / svg_path.name)

        # GTK4's libadwaita CSS references this symbolic asset, but Colloid does
        # not ship it in the same source directory as the rest of the GTK assets.
        devel_symbolic = assets_dest / "devel-symbolic.svg"
        if not devel_symbolic.exists():
            devel_symbolic.write_text(
                """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
  <path fill="#ffffff" d="M3 3h10v2H3zm0 4h10v2H3zm0 4h7v2H3z"/>
</svg>
"""
            )

        shutil.copy2(thumbnail, thumbnail_dest)

        for svg_path in assets_dest.glob("*.svg"):
            _replace_svg_colors(svg_path, replacements)
        _replace_svg_colors(thumbnail_dest, replacements)


def build_colloid_theme(
    theme_name: str,
    palette: dict,
    output_root: Path,
    theme_overrides: Path | Iterable[Path],
    base_templates: Path,
    template_relative_path: Path = COLLOID_INTERNAL_TEMPLATE,
) -> None:
    rendered_palette = render_internal_colloid_palette(
        theme_name=theme_name,
        palette=palette,
        theme_overrides=theme_overrides,
        base_templates=base_templates,
        template_relative_path=template_relative_path,
    )
    palette_vars = _parse_palette_variables(rendered_palette)

    palette_stub = re.sub(r"[^A-Za-z0-9_-]+", "-", theme_name)

    with tempfile.TemporaryDirectory(prefix=f"colloid-{palette_stub}-") as temp_dir:
        workspace_root = Path(temp_dir)
        _copy_vendor_workspace(workspace_root)

        palette_path = workspace_root / "src" / "sass" / f"_color-palette-{palette_stub}.scss"
        palette_path.write_text(rendered_palette)
        _write_tweaks_file(workspace_root, palette_stub)

        variant = "Dark" if palette["mode"] == "dark" else "Light"
        gtk3_input = workspace_root / "src" / "main" / "gtk-3.0" / f"gtk-{variant}.scss"
        gtk4_input = workspace_root / "src" / "main" / "libadwaita" / f"libadwaita-{variant}.scss"
        gtk3_css = gtk3_input.with_suffix(".css")
        gtk4_css = gtk4_input.with_suffix(".css")

        logger.info("Building Colloid GTK output")
        _run_sassc(gtk3_input, gtk3_css)
        _run_sassc(gtk4_input, gtk4_css)

        gtk3_output = output_root / "gtk-3.0"
        gtk4_output = output_root / "gtk-4.0"
        gtk3_output.mkdir(parents=True, exist_ok=True)
        gtk4_output.mkdir(parents=True, exist_ok=True)

        gtk3_text = gtk3_css.read_text()
        gtk4_text = gtk4_css.read_text()

        write_atomic_text(gtk3_output / "gtk.css", gtk3_text)
        write_atomic_text(gtk3_output / "gtk-dark.css", gtk3_text)
        write_atomic_text(gtk4_output / "gtk.css", gtk4_text)
        write_atomic_text(gtk4_output / "gtk-dark.css", gtk4_text)

        _copy_and_recolor_assets(workspace_root, output_root, palette_vars, palette["mode"])
