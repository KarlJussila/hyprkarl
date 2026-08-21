from dataclasses import dataclass
from pathlib import Path
from tempfile import TemporaryDirectory

from .render import build_theme, iter_theme_names


@dataclass(frozen=True)
class ValidationIssue:
    theme: str
    message: str


def validate_theme(source: str | Path) -> list[ValidationIssue]:
    with TemporaryDirectory(prefix="validate-theme-") as temporary_directory:
        try:
            build_theme(source, Path(temporary_directory) / "output")
        except Exception as error:
            return [ValidationIssue(theme=str(source), message=str(error))]
    return []


def validate_repository() -> list[ValidationIssue]:
    return [
        issue
        for theme_name in iter_theme_names()
        for issue in validate_theme(theme_name)
    ]
