import argparse
import logging
import sys
from pathlib import Path

from .capture import DEFAULT_CAPTURE_WORKSPACE, capture_theme_previews
from .preview import render_theme_preview, show_theme
from .render import (
    OUTPUT_DIR,
    GenerationError,
    build_theme,
    load_source_theme,
    resolve_theme_sources,
)
from .validation import validate_repository

logger = logging.getLogger(__name__)


def _build(args: argparse.Namespace) -> None:
    destination = build_theme(args.theme, args.output, args.name, args.overlay)
    print(destination)


def _preview(args: argparse.Namespace) -> None:
    sources = resolve_theme_sources(args.theme, args.overlay)
    theme = load_source_theme(sources)
    show_theme(theme)
    output = args.output or OUTPUT_DIR / f"{sources.name}-palette.png"
    print(render_theme_preview(theme, sources.name, output))


def _capture(args: argparse.Namespace) -> None:
    if args.workspace < 1:
        raise GenerationError("Capture workspace must be a positive number")
    sources = resolve_theme_sources(args.theme, args.overlay)
    theme = load_source_theme(sources)
    output = Path(args.output).expanduser() if args.output else sources.layers[-1] / "previews"
    print(
        capture_theme_previews(
            sources.name,
            theme,
            output.resolve(),
            args.settle,
            args.workspace,
        )
    )


def _validate(_args: argparse.Namespace) -> None:
    issues = validate_repository()
    if issues:
        for issue in issues:
            print(f"{issue.theme}: {issue.message}", file=sys.stderr)
        raise GenerationError(f"Validation failed for {len(issues)} theme(s)")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Build token-driven Hyprkarl themes")
    parser.add_argument("--verbose", action="store_true", help="show every generated file")
    subcommands = parser.add_subparsers(dest="command", required=True)

    build = subcommands.add_parser("build", help="build one theme bundle")
    build.add_argument("theme", help="built-in theme name, source directory, or theme.yaml")
    build.add_argument("-o", "--output", help="output directory")
    build.add_argument("--name", help="theme name embedded in generated consumer files")
    build.add_argument("--overlay", help="personal source directory merged over the theme")
    build.set_defaults(action=_build)

    preview = subcommands.add_parser("preview", help="preview one theme palette")
    preview.add_argument("theme", help="built-in theme name, source directory, or theme.yaml")
    preview.add_argument("--overlay", help="personal source directory merged over the theme")
    preview.add_argument("-o", "--output", help="graphical preview path")
    preview.set_defaults(action=_preview)

    capture = subcommands.add_parser("capture", help="capture one theme's standard screenshots")
    capture.add_argument("theme", help="installed built-in or personal theme name")
    capture.add_argument("--overlay", help="personal source directory merged over the theme")
    capture.add_argument("-o", "--output", help="screenshot directory")
    capture.add_argument(
        "--settle",
        type=float,
        default=1.0,
        help="seconds to wait after each desktop change",
    )
    capture.add_argument(
        "--workspace",
        type=int,
        default=DEFAULT_CAPTURE_WORKSPACE,
        help="empty numbered workspace used for capture",
    )
    capture.set_defaults(action=_capture)

    validate = subcommands.add_parser("validate", help="build and validate every built-in theme")
    validate.set_defaults(action=_validate)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    logging.basicConfig(
        level=logging.INFO if args.verbose else logging.WARNING,
        format="%(levelname)s: %(message)s",
    )
    try:
        args.action(args)
    except Exception as error:
        logger.error("%s", error)
        return 1
    return 0
