# Changelog

Notable changes to Hyprkarl. Releases are annotated git tags on `main`;
entries here are written by hand when a release is cut. Until v1.0.0, minor
versions may include breaking changes (renamed commands, changed config
surfaces) — they are called out explicitly.

## Unreleased

- Breaking: replaced the baseline-commit updater and guided TUI with a staged
  source workflow. `hk-update sync` fetches, reviews, and pins one exact source
  revision without moving the live checkout; `hk-update apply` fast-forwards
  to it, migrates and restows configuration, rebuilds the selected theme and
  GTK payload, reloads consumers, and records success. `hk-update all` now runs
  sync, apply, packages, system migrations, then `post-update`. The retired
  `tui` and `dotfiles` actions and their `--force` and `--adopt` paths are gone.
- Moved update records to `${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/update/`.
  Package requirements and one-time removal reviews use an atomically replaced
  `packages.json`; system changes are ordered files under `system/migrations/`
  with one success marker per migration. Old checkout-local commit markers are
  imported on first use.
- Breaking: integrated the theme compiler into Hyprkarl and converted
  `themes/<name>/` to authoring source only. `hk-theme set` now merges shared
  defaults, a built-in source, and an optional same-name personal source;
  renders and validates a complete bundle; and activates an immutable XDG-state
  artifact. The sibling generator dependency, `hk-theme build`, and generator
  `sync` command are gone.
- Personal themes now live as source under
  `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/themes/`. A new theme requires
  `theme.yaml`; a same-name overlay may contain only sparse values, overrides,
  or assets. Migration moves legacy complete bundles to dated backups under
  `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/theme-backups/` instead of
  treating generated output as editable source.
- Fixed light theme generation so GTK 3 and GTK 4 compile the light Colloid
  variant and activation applies the matching desktop color-scheme preference.
- Breaking: moved personal shell JSON, menu JSON, Hyprland modules, hooks,
  Quickshell extensions, and themes from the checkout's `user/` tree to
  `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/`. `hk-user-migrate` performs the
  one-time move before a dotfiles update and materializes UWSM defaults,
  machine-local environment, and terminal preferences as real user files.
  Ordinary personalization no longer requires a Git branch.
- Breaking: application preferences are now user-owned files in their normal
  `~/.config/<application>/` directories. A one-time migration materializes
  old Stow links for Btop, Fastfetch, Fish, GTK, Hyprland helpers, Neovim, Qt,
  portals, terminal selection, and Yazi without overwriting existing files;
  an XDG-state marker prevents later updates from recreating deletions.
  Alacritty, foot, Ghostty, and Kitty retain small tracked bootstraps and load
  personal `local.*` overrides last. Ghostty's entry point is now the native
  `config.ghostty` filename.
- Added a per-output display panel with internal-backlight brightness, cleaned
  scale presets, and output enable/disable controls. `hk-display` now owns
  Hyprland discovery, live changes, and an XDG-state layout that survives
  reloads without editing tracked or user-authored monitor files.
- Fixed notification icon paths and sizing. Absolute sender paths now load as
  files, every icon source uses `notification.iconSize`, and the redundant
  `notification.imageSize` theme token has been removed.
- Breaking: replaced `bar.enabled` with the top-level `modules` object. Its
  nine switches independently select the bar, panels, notifications, OSD,
  polkit, menu, applications/open-with, calculator, and wallpaper. Module
  changes require `hk-shell restart`; disabled modules no longer construct
  their built-in windows, state, services, timers, watchers, processes, or IPC
  targets. `modules.panels` disables popup panels only, so status widgets stay
  in an enabled bar until a layout edit removes them.
- Expanded the explicitly referenced application-wide user QML root. Its
  context now exposes current outputs and direct overlay request and control
  fields, so personal QML can receive a custom menu overlay and close or
  replace it without a plugin registry.
- Added `tests/hk-shell-modules.sh`, an isolated Quickshell check for disabled
  module IPC, bar polling, and the personal overlay context.
- Fixed `hk-shell stop` returning during a reload-generation gap while the
  Quickshell daemon remained alive and able to restart the shell.
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
- Unified the command menu with the launcher, calculator, and wallpaper picker
  on the shared overlay frame and touchpad momentum implementation while
  preserving its compact layout and menu-specific navigation.
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
  theme changes, and wallpaper changes under the personal configuration root.
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
