import json
import logging
import os
import shutil
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import yaml

from .gtk import COLLOID_INTERNAL_TEMPLATE, ColloidBuildError, build_colloid_theme
from .theme import load_theme_layers, render_template, write_atomic_text


logger = logging.getLogger(__name__)

ROOT = Path(__file__).resolve().parents[1]
HYPRKARL_ROOT = ROOT.parent
THEMES_DIR = HYPRKARL_ROOT / "themes"
TEMPLATES_DIR = ROOT / "templates"
DEFAULT_THEME_PATH = ROOT / "defaults" / "theme.yaml"
OUTPUT_DIR = ROOT / "output"

GTK_THEME_BUNDLE_DIR = "gtk-theme"
GTK_THEME_TEMPLATE_PATHS = (Path("index.theme"),)
SKIPPED_VISIBLE_TEMPLATE_PATHS = {Path("index.theme")}
TEMPLATE_EXTENSIONS = {
    ".conf",
    ".css",
    ".ini",
    ".json",
    ".lua",
    ".rasi",
    ".scss",
    ".svg",
    ".theme",
    ".toml",
}
ASSET_DIRECTORIES = {
    "wallpapers": "wallpapers",
    "previews": "screenshots",
    "icons": "icons",
}
REQUIRED_BUNDLE_FILES = (
    "theme.yaml",
    "quickshell.json",
    "hyprland.lua",
    "hyprlock.conf",
    "hyprtoolkit.conf",
    "btop.theme",
    "alacritty.toml",
    "foot.ini",
    "ghostty.conf",
    "kitty.conf",
    "wifitui.toml",
    "yazi.toml",
    "icons.theme",
    "gtk-3.0/settings.ini",
    "gtk-3.0/gtk.css",
    "gtk-3.0/gtk-dark.css",
    "gtk-4.0/settings.ini",
    "gtk-4.0/gtk.css",
    "gtk-4.0/gtk-dark.css",
    "gtk-theme/index.theme",
    "gtk-theme/gtk-3.0/gtk.css",
    "gtk-theme/gtk-4.0/gtk.css",
    "nvim/colorscheme.lua",
    "nvim/custom-colors.lua",
    "qt5ct/qt5ct.conf",
    "qt5ct/style-colors.conf",
    "qt6ct/qt6ct.conf",
    "qt6ct/style-colors.conf",
)
REQUIRED_BUNDLE_DIRECTORIES = ("icons", "wallpapers")


class GenerationError(RuntimeError):
    pass


@dataclass(frozen=True)
class ThemeSources:
    name: str
    layers: tuple[Path, ...]


def _source_directory(value: str | Path) -> Path | None:
    requested = Path(value).expanduser()
    if requested.is_file() and requested.name == "theme.yaml":
        return requested.parent.resolve()
    if requested.is_dir():
        return requested.resolve()
    return None


def resolve_theme_sources(
    value: str | Path,
    overlay_source: str | Path | None = None,
) -> ThemeSources:
    direct_source = _source_directory(value)
    if direct_source is not None:
        name = direct_source.name
        layers = [direct_source]
    else:
        name = str(value)
        built_in = THEMES_DIR / name
        layers = [built_in.resolve()] if built_in.is_dir() else []

    if overlay_source is not None:
        overlay = Path(overlay_source).expanduser()
        if overlay.is_dir():
            layers.append(overlay.resolve())

    if not layers:
        raise GenerationError(f"Theme source not found: {value}")
    if not any((source / "theme.yaml").is_file() for source in layers):
        raise GenerationError(f"Theme has no theme.yaml: {layers[-1]}")
    return ThemeSources(name=name, layers=tuple(layers))


def iter_theme_names() -> list[str]:
    return sorted(
        path.name
        for path in THEMES_DIR.iterdir()
        if path.is_dir() and (path / "theme.yaml").is_file()
    )


def _is_hidden(relative_path: Path) -> bool:
    return any(part.startswith(".") for part in relative_path.parts)


def _scan_files(root: Path) -> dict[Path, Path]:
    if not root.is_dir():
        return {}
    return {
        path.relative_to(root): path
        for path in sorted(root.rglob("*"))
        if path.is_file() and not _is_hidden(path.relative_to(root))
    }


def _as_sources(sources: Path | Iterable[Path]) -> tuple[Path, ...]:
    if isinstance(sources, Path):
        return (sources,)
    return tuple(sources)


def collect_templates(sources: Path | Iterable[Path]) -> dict[Path, Path]:
    templates = _scan_files(TEMPLATES_DIR)
    for source in _as_sources(sources):
        templates.update(_scan_files(source / "overrides"))
    return templates


def load_source_theme(sources: ThemeSources) -> dict:
    graph_paths = [
        source / "theme.yaml"
        for source in sources.layers
        if (source / "theme.yaml").is_file()
    ]
    return load_theme_layers(graph_paths, DEFAULT_THEME_PATH)


def _icon_theme_name(files: dict[Path, Path], context: dict) -> str:
    source = files.get(Path("icons.theme"))
    if source is None:
        return "Adwaita"
    text = source.read_text()
    if source.suffix in TEMPLATE_EXTENSIONS:
        text = render_template(text, context)
    return text.strip() or "Adwaita"


def _render_files(files: dict[Path, Path], context: dict, output_root: Path) -> None:
    for relative_path, source in files.items():
        if relative_path in SKIPPED_VISIBLE_TEMPLATE_PATHS:
            continue

        destination = output_root / relative_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        if source.suffix in TEMPLATE_EXTENSIONS:
            logger.info("Rendering %s", relative_path)
            write_atomic_text(destination, render_template(source.read_text(), context))
        else:
            logger.info("Copying %s", relative_path)
            shutil.copy2(source, destination)


def _disabled_wallpapers(source: Path) -> list[Path]:
    marker = source / ".wallpapers-disabled"
    if not marker.is_file():
        return []
    return [Path(line.strip()) for line in marker.read_text().splitlines() if line.strip()]


def _copy_assets(sources: tuple[Path, ...], output_root: Path) -> None:
    for source_name, output_name in ASSET_DIRECTORIES.items():
        files: dict[Path, Path] = {}
        for source in sources:
            files.update(_scan_files(source / source_name))
            if source_name == "wallpapers":
                for disabled in _disabled_wallpapers(source):
                    files.pop(disabled, None)

        destination_root = output_root / output_name
        destination_root.mkdir(parents=True, exist_ok=True)
        for relative_path, source in files.items():
            destination = destination_root / relative_path
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)


def _render_gtk_metadata(files: dict[Path, Path], context: dict, bundle_root: Path) -> None:
    bundle_root.mkdir(parents=True, exist_ok=True)
    for relative_path in GTK_THEME_TEMPLATE_PATHS:
        source = files.get(relative_path)
        if source is None:
            raise GenerationError(f"Missing GTK theme template: {relative_path}")
        write_atomic_text(bundle_root / relative_path, render_template(source.read_text(), context))


def _copy_gtk_payload(output_root: Path, bundle_root: Path) -> None:
    for directory_name in ("gtk-3.0", "gtk-4.0"):
        source = output_root / directory_name
        if not source.is_dir():
            raise GenerationError(f"Missing generated GTK payload: {directory_name}")
        destination = bundle_root / directory_name
        shutil.copytree(source, destination)
        settings = destination / "settings.ini"
        if settings.exists():
            settings.unlink()


def validate_bundle(bundle_root: Path) -> None:
    for relative_path in REQUIRED_BUNDLE_FILES:
        if not (bundle_root / relative_path).is_file():
            raise GenerationError(f"Theme bundle is missing {relative_path}")
    for relative_path in REQUIRED_BUNDLE_DIRECTORIES:
        if not (bundle_root / relative_path).is_dir():
            raise GenerationError(f"Theme bundle is missing {relative_path}/")

    try:
        json.loads((bundle_root / "quickshell.json").read_text())
    except (json.JSONDecodeError, OSError) as error:
        raise GenerationError("Theme bundle has invalid quickshell.json") from error


def _render_theme(sources: ThemeSources, output_root: Path, theme_name: str) -> None:
    theme = load_source_theme(sources)
    files = collect_templates(sources.layers)
    context = dict(theme)
    context["theme_name"] = theme_name
    context["icon_theme_name"] = _icon_theme_name(files, context)

    output_root.mkdir(parents=True, exist_ok=True)
    _render_files(files, context, output_root)
    _copy_assets(sources.layers, output_root)
    write_atomic_text(
        output_root / "theme.yaml",
        yaml.safe_dump(theme, sort_keys=False),
    )
    if theme["mode"] == "light":
        write_atomic_text(output_root / "light.mode", "")

    try:
        build_colloid_theme(
            theme_name=theme_name,
            palette=context,
            output_root=output_root,
            theme_overrides=tuple(source / "overrides" for source in sources.layers),
            base_templates=TEMPLATES_DIR,
            template_relative_path=COLLOID_INTERNAL_TEMPLATE,
        )
    except ColloidBuildError as error:
        raise GenerationError(str(error)) from error

    gtk_theme_root = output_root / GTK_THEME_BUNDLE_DIR
    _render_gtk_metadata(files, context, gtk_theme_root)
    _copy_gtk_payload(output_root, gtk_theme_root)
    validate_bundle(output_root)


def _replace_destination(staging: Path, destination: Path) -> None:
    if not destination.exists():
        os.replace(staging, destination)
        return

    backup = Path(tempfile.mkdtemp(prefix=f".{destination.name}-previous-", dir=destination.parent))
    backup.rmdir()
    os.replace(destination, backup)
    try:
        os.replace(staging, destination)
    except Exception:
        os.replace(backup, destination)
        raise
    if backup.is_dir():
        shutil.rmtree(backup)
    else:
        backup.unlink()


def build_theme(
    source: str | Path,
    output_path: str | Path | None = None,
    theme_name: str | None = None,
    overlay_source: str | Path | None = None,
) -> Path:
    sources = resolve_theme_sources(source, overlay_source)
    rendered_name = theme_name or sources.name
    destination = Path(output_path) if output_path else OUTPUT_DIR / rendered_name
    destination = destination.expanduser().resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)

    staging = Path(tempfile.mkdtemp(prefix=f".{destination.name}-", dir=destination.parent))
    try:
        _render_theme(sources, staging, rendered_name)
        _replace_destination(staging, destination)
    except Exception:
        shutil.rmtree(staging, ignore_errors=True)
        raise
    return destination
