# Changelog

Notable changes to Hyprkarl. Releases are annotated git tags on `main`;
entries here are written by hand when a release is cut. Until v1.0.0, minor
versions may include breaking changes (renamed commands, changed config
surfaces) — they are called out explicitly.

## Unreleased

## v0.1.0

First tagged release, marking the settled runtime shape:

- Lua-based Hyprland configuration (`config/hypr/`), with keybindings and
  window rules split into per-topic modules
- AGS/Astal TypeScript bar with data-only widget and layout configuration,
  flyouts, autohide, and a typecheck harness
- Theme system covering Hyprland, the bar, rofi, terminals, mako, hyprlock,
  GTK, and Qt, with three shipped themes (hyprkarl, everforest, gruvbox) and a
  companion [theme generator](https://github.com/KarlJussila/hyprkarl-theme-generator)
- The `hk-*` command suite and rofi menu system
- Baseline-commit update model (`hk-update`) with a guided TUI, plus manual
  sandbox test harnesses under `tests/`
- Stow-based install (`setup-all.sh`) with re-run safety guards

Breaking change for pre-release installs: verb-first commands were renamed to
noun-first (`hk-launch-browser` → `hk-browser-launch`, `hk-record-screen` →
`hk-screen-record`, `hk-find-icon` → `hk-icon-find`, and 13 more — see
`docs/commands.md`). Custom bindings or scripts referencing old names need
updating.
