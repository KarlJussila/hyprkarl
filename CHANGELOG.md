# Changelog

Notable changes to Hyprkarl. Releases are annotated git tags on `main`;
entries here are written by hand when a release is cut. Until v1.0.0, minor
versions may include breaking changes (renamed commands, changed config
surfaces) — they are called out explicitly.

## Unreleased

- Added a per-output display panel with internal-backlight brightness, cleaned
  scale presets, and output enable/disable controls. `hk-display` now owns
  Hyprland discovery, live changes, and an XDG-state layout that survives
  reloads without editing tracked or user-authored monitor files.
- Added `bar.enabled` so the built-in bar and its bar-only polling can be
  removed without stopping menus, notifications, OSD, or polkit. Added one
  explicitly referenced application-wide user QML root with open theme data
  and reactive per-output notification positioning for custom bars.
- Breaking: renamed generator-owned `palette.yaml` sources to `theme.yaml` and
  expanded them into an open, typed token graph. Shared defaults now own fonts,
  spacing, radii, border widths, motion, and the complete Quickshell appearance
  contract; theme-defined structures can derive native string, numeric, and
  boolean consumer values.
- Replaced `hyprpolkitagent` with a focused, theme-aware Quickshell polkit
  prompt supporting PAM response visibility, fingerprint/no-response flows,
  multiple identities, cancellation, and service-owned retries.
- Replaced the static Rofi navigation tree with a theme-aware Quickshell menu
  surface, sparse user overrides, dynamic providers, and in-process search.
- Migrated theme selection, live keybindings, Nerd Font icons, Docker service
  selection, and the complete fingerprint workflow—including available and
  enrolled finger pickers—to Quickshell.
- Added menu-level row alignment so table-like providers such as live
  keybindings retain stable columns without a specialized renderer.
- Reworked dynamic menu providers around Python's standard JSON support and
  established Python as the default for structured data and substantial text
  processing, while retaining Bash for straightforward command orchestration.
- Simplified provider failure boundaries: trusted Hyprland data flows directly,
  external workflows use one catch-all, and a malformed Docker manifest is
  logged and skipped without suppressing the other services.
- Enabled Quickshell's required `QApplication` mode so system-tray items can
  display their native menus; documented the left, middle, and right-click
  interaction contract.
- Kept an open empty system tray fully collapsed while preserving its state so
  newly appearing items reveal automatically, and kept the chevron trigger's
  visible width stable between collapsed and expanded states.
- Added ordered user lifecycle hooks for session startup, completed updates,
  theme changes, and wallpaper changes under `user/hooks/<event>.d/`.
- Breaking: removed forwarding-only `hk-menu-*` commands. Custom bindings and
  scripts should call `hk-shell menu open <menu-id>` or
  `hk-shell menu toggle <menu-id>` directly. `hk-menu-keybindings --print` is
  replaced by `hk-keybindings-list`.

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
