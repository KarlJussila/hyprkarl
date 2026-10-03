# Changelog

Notable changes to Hyprkarl. Releases are annotated git tags on `main`;
entries here are written by hand when a release is cut. From v1.0.0, a
breaking change bumps the major version and is called out explicitly.

## Unreleased

- The update icon now sits left of the clock in the default bar.
- `hk-update all`, which the update icon runs, now asks "Apply this update
  now?" after its review, since saying yes starts the apply. `hk-update sync`
  on its own still asks whether to stage the revision.

## v1.0.0 (2026-10-03)

The desktop shell, configuration model, theme system, and updater were all
rebuilt, so installs from the AGS-era `develop` branch (at or before
`3df882e`) have no automatic upgrade. Follow
[Upgrading to 1.0](docs/upgrading-to-1.0.md).

### Desktop shell

- Breaking: Quickshell replaces the AGS bar, rofi menus, the launcher and
  calculator, mako, the OSD, hyprpolkitagent, and hyprlock. One shell draws the
  bar and its feature panels (display, audio, network, Bluetooth, power,
  calendar), the command menu, launcher and open-with picker, calculator,
  wallpaper carousel, notifications, OSD, and polkit prompt. `hk-shell` starts,
  restarts, and controls it.
- The lock screen runs as its own process, so restarting the shell never
  unlocks the session. It locks before reading the theme, authenticates
  passwords through `/etc/pam.d/login`, and scans fingerprints when fingers
  are enrolled. Hypridle locks before every suspend.
- Panels and modals share keyboard navigation: arrows or H/J/K/L within a
  section, Tab between sections, Escape or Q to close.
- The display panel changes resolution, refresh rate, scale, and enabled
  outputs with a ten-second keep-or-revert trial, and an arranger positions
  and rotates monitors. The layout persists in XDG state, outside your config.
- Menus are data: `defaults/menu.json` plus your
  `~/.config/quickshell/settings/menu.json`, with fuzzy search across submenus
  and dynamic entries for themes, keybindings, icons, Docker services, and
  fingerprints.
- Caffeine pauses idle locking and sleep with an idle inhibitor; manual
  suspend and lid close still lock.
- The shell runs from `~/.config/quickshell/`, so personal QML can import any
  part of it. Each built-in (launcher, menu, notifications, OSD, calculator,
  wallpaper picker, polkit prompt, bar) can be switched off and replaced by
  your own QML answering the same IPC target, without editing Hyprkarl's
  files. Any `hk-*` command, including `hk-lock`, can be replaced by a script
  of the same name in `~/.local/bin/`.

### Configuration

- Breaking: personal configuration lives outside the checkout, so updates
  never touch it and no Git branch is needed. Hyprland modules, hooks, and
  themes go in `~/.config/hyprkarl/`; shell and menu settings and personal QML
  go in `~/.config/quickshell/`.
- Breaking: shipped Hyprland modules moved to `defaults/hypr/`. Personal
  Hyprland settings go in `~/.config/hypr/hyprland.local.lua`, which loads last.
- Breaking: application configs keep receiving Hyprkarl's defaults. Terminals
  and Hypridle, Hyprpaper, and Hyprsunset load Hyprkarl's settings, then your
  `local.*` file; Hypridle's timeouts and actions are variables you redefine
  there. Portal and terminal choices are defaults your own file replaces. GTK
  and Qt follow the theme. Only btop, fastfetch, Neovim, and Yazi are copied
  once, when you have none of their files. Ghostty's config is now
  `config.ghostty`.
- Hyprkarl no longer installs desktop-file overrides to hide applications; the
  launcher hides them through `applications.hidden` in `shell.json`.
- Shell behavior comes from `defaults/shell.json` with your
  `~/.config/quickshell/settings/shell.json` merged over it: objects merge,
  arrays replace. The `modules` object turns built-in parts of the shell on or
  off. Bar widgets include configurable command widgets and your own QML
  widgets, and one personal QML root can add independent surfaces or replace
  the bar.
- Lifecycle hooks run your executables after login, updates, theme changes,
  and wallpaper changes.
- A `hyprkarl` skill for coding agents (Claude Code, Codex, and others that
  read `~/.agents/skills`) explains where each kind of change belongs, so an
  agent customizing the system works with Hyprkarl instead of around it.
  Installing or updating links it where those agents look, including for
  agents installed later.

### Themes

- Breaking: the theme compiler is part of Hyprkarl. A theme is one typed
  `theme.yaml` source instead of a directory of per-app files; old custom
  themes must be recreated. A personal theme, or a same-name overlay with only
  the values you change, lives in `~/.config/hyprkarl/themes/<name>/`.
- `hk-theme set` builds the theme under `~/.local/state/hyprkarl/` and switches
  to it without editing the checkout. A failed build leaves the current theme
  in place.
- Added the `loam` and `tokyo-night` themes, per-theme icon families, light
  theme support for GTK, and an optional generated wallpaper.
- Themes set the mouse cursor theme (`desktop.cursor_theme`, Adwaita by
  default) for Hyprland and for apps that draw their own cursor. Cursor size
  stays in Hyprland's `envs.lua`.

### Updates

- Breaking: `hk-update sync` fetches and shows incoming commits, then records
  the revision you reviewed; `hk-update apply` moves to it, seeds new starting
  configs, restows, rebuilds the theme, and restarts the shell. Within
  `apply`, packages are installed and retired ones reviewed once, then
  numbered one-time migrations run. The `tui` and `dotfiles` actions and their
  `--force` and `--adopt` flags are gone. Update state lives under
  `~/.local/state/hyprkarl/update/`.
- Breaking: `install.sh` replaces `setup-all.sh` and the `setup-*.sh` scripts.
  It bootstraps the updater and runs the same `hk-update apply` an update
  does. It moves the system's own configs that block Hyprkarl's links to
  `~/.local/state/hyprkarl/replaced-configs-<date>/`.
- Breaking: Hyprkarl logs in through greetd instead of SDDM, starting the
  session automatically at boot, as CachyOS's current Hyprland edition does.
  Upgrades switch the display manager at the next boot and offer SDDM for
  removal.

### Commands

- Breaking: the `hk-menu-*` commands are gone; call
  `hk-shell menu toggle <menu-id>`. `hk-ags` became `hk-shell`, and
  `hk-menu-keybindings --print` became `hk-keybindings-list`.
- Yazi gained image actions to set a wallpaper, clear metadata, and convert to
  JPG. Screenshots no longer close an open panel. `hk-dictionary` uses the
  FreeDict server.
- Retired packages, reviewed once by `hk-update packages`: AGS and its astal
  libraries, dart-sass, rofi, rofi-calc, wofi, waybar, mako, hyprlock,
  hyprpolkitagent, kvantum, dolphin (replaced by Nautilus), and wifitui-bin
  (replaced by wifitui).

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
