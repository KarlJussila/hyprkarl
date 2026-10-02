# Changelog

Notable changes to Hyprkarl. Releases are annotated git tags on `main`;
entries here are written by hand when a release is cut. Until v1.0.0, minor
versions may include breaking changes (renamed commands, changed config
surfaces) — they are called out explicitly.

## Unreleased

Installs from the `develop` branch at or before `3df882e` (the AGS era) have
no automatic upgrade path. Follow [Upgrading to 1.0](docs/upgrading-to-1.0.md).

- Breaking: replaced hyprlock with a Quickshell lock screen that runs as its own
  process. It locks before reading the theme, uses `/etc/pam.d/login` for
  passwords, and scans fingerprints when fingers are enrolled. `hk-suspend`
  now only suspends; Hypridle locks first. Lock appearance is theme data under
  `shell.lock`.
- Caffeine now holds a systemd idle inhibitor instead of stopping Hypridle, so
  manual suspend and lid close still lock while it is on.
- Breaking: `shell.json` and `menu.json` personal files merge over the shipped
  defaults with no `version` field and no schema validation. `bar.layoutEdits`
  is gone; to change a bar section, copy it from `defaults/shell.json` and
  edit it. A personal file that does not parse leaves the defaults running.
- Breaking: personal QML reads theme values by group, matching `theme.yaml`:
  `theme.palette.foreground`, `theme.panel.padding`, `theme.menu.accent`.
  `theme.document` is now `theme.values`.
- Added a built-in `tokyo-night` theme based on Tokyo Night's original dark
  Night palette.
- Added a built-in `loam` theme with warm brown surfaces, olive-moss
  highlights, and restrained ochre accents.
- Added opt-in generation of the shared Hyprkarl wallpaper from a theme's
  background, primary accent, and soft primary accent. Generated and authored
  wallpapers may ship together.
- Added graphical palette boards and repeatable live screenshot capture for
  theme authors, including the standard tiled busy desktop, OSD, notification,
  selected file, focused window, and deliberate pointer hover.
- Theme sources now select their desktop icon family through
  `desktop.icon_theme`; Loam uses Yaru Olive Dark and Tokyo Night uses Yaru
  Blue Dark.
- Breaking: replaced the baseline-commit updater and guided TUI with a staged
  source workflow. `hk-update sync` fetches, reviews, and pins one exact source
  revision without moving the live checkout; `hk-update apply` fast-forwards
  to it, seeds starting configs and restows, rebuilds the selected theme and
  GTK payload, reloads consumers, and records success. `hk-update all` now runs
  sync, apply, packages, system migrations, then `post-update`. The retired
  `tui` and `dotfiles` actions and their `--force` and `--adopt` paths are gone.
- Moved update records to `${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/update/`.
  Package requirements and one-time removal reviews use an atomically replaced
  `packages.json`; system changes are ordered files under `system/migrations/`
  with one success marker per migration.
- Breaking: integrated the theme compiler into Hyprkarl and converted
  `themes/<name>/` to authoring source only. `hk-theme set` now merges shared
  defaults, a built-in source, and an optional same-name personal source;
  renders and validates a complete build under XDG state; and points
  `current/theme` at it. The sibling generator dependency, `hk-theme build`,
  and generator `sync` command are gone.
- Personal themes now live as source under
  `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/themes/`. A new theme requires
  `theme.yaml`; a same-name overlay may contain only sparse values, overrides,
  or assets. Old hand-written theme directories must be recreated as
  `theme.yaml` sources.
- Fixed light theme generation so GTK 3 and GTK 4 compile the light Colloid
  variant and activation applies the matching desktop color-scheme preference.
- Breaking: personal configuration lives outside the checkout. Hyprland
  modules, hooks, and themes go in `~/.config/hyprkarl/`; shell and menu
  settings and personal QML go in `~/.config/quickshell/`. Ordinary
  personalization no longer requires a Git branch.
- Breaking: application preferences are user-owned files in their normal
  `~/.config/<application>/` directories. `hk-config-seed` copies Hyprkarl's
  starting config for Btop, Fastfetch, Fish, GTK, Hyprland helpers, Neovim,
  Qt, portals, terminal selection, and Yazi when you have none of an
  application's files, and never overwrites one. Alacritty, foot, Ghostty, and
  Kitty keep small tracked bootstraps and load personal `local.*` files last.
  Ghostty's entry point is now the native `config.ghostty` filename.
- Added a per-output display panel with internal-backlight brightness, cleaned
  scale presets, and output enable/disable controls. `hk-display` now owns
  Hyprland discovery, live changes, and an XDG-state layout that survives
  reloads without editing tracked or user-authored monitor files.
- Added a global display-arrangement modal that changes active-output positions
  and rotations while preserving mode, refresh rate, and scale. Right-click
  rotates a frame clockwise; its physical-bottom marker rotates with it, and
  overlapping drafts cannot be applied. The
  same reusable `ui.modal.Modal` component is available to the explicit
  personal QML root, with no discovery or registration layer.
- Replaced display-list enable switches with staged per-output settings for
  enablement, resolution, refresh rate, and scale. Resolution and refresh rate
  have separate nested pickers, and refresh options are filtered to modes
  supported at the selected resolution. Applying opens a
  ten-second confirmation modal on the output that owned the panel when it
  remains active; an independent backend watchdog restores the prior live
  layout unless the change is explicitly kept.
- Added shared spatial keyboard navigation to feature panels and public
  modals. Arrow keys and H/J/K/L move within a section, Tab moves between
  sections and restores the current choice, Enter/Space activate controls,
  and Escape or Q dismisses the surface. Nested display back actions now sit
  before the header title. Display details omit settings that cannot act on
  the current draft instead of presenting disabled rows. Pointer and keyboard
  navigation now share one current control, while the solid alternate panel
  background identifies its active section without changing section-heading
  typography. Audio uses one spatial section for output, input, and device
  choices.
- Fixed notification icon paths and sizing. Absolute sender paths now load as
  files, every icon source uses `notification.iconSize`, and the redundant
  `notification.imageSize` theme token has been removed.
- Breaking: replaced `bar.enabled` with the top-level `modules` object. Its
  nine switches independently select the bar, panels, notifications, OSD,
  polkit, menu, applications/open-with, calculator, and wallpaper. Module
  changes require `hk-shell restart`; disabled modules no longer construct
  their built-in windows, state, services, timers, watchers, processes, or IPC
  targets. `modules.panels` disables popup panels only, so status widgets stay
  in an enabled bar until you remove them from your layout.
- Expanded the explicitly referenced application-wide user QML root. Its
  context now exposes current outputs and direct overlay request and control
  fields, so personal QML can receive a custom menu overlay and close or
  replace it without a plugin registry.
- Added `tests/hk-shell-modules.sh`, an isolated Quickshell check for disabled
  module IPC, bar polling, the personal overlay context, and lazy public modal
  composition.
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
