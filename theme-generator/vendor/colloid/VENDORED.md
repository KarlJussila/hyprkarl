Upstream: `https://github.com/vinceliuice/Colloid-gtk-theme`
Pinned commit: `fd805dbeeacb12f7971b98408c415c3f472e5aef`

This vendor snapshot is source-only and intentionally limited to the files needed for local GTK generation.
It keeps only the Colloid sources required for this repo's GTK3 dark CSS build,
libadwaita dark CSS build, and GTK asset recoloring pipeline.

The vendored Colloid source remains GPL-3.0. The repository root `LICENSE`
documents the top-level licensing state for the combined project.

Repository-specific integration lives primarily in:
- `colloid.py`
- `generate.py`
- `templates/.internal/colloid/_color-palette.scss`
