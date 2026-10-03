# Command Reference

This page lists the `hk-*` commands you would normally run directly. These
names and arguments stay stable across updates; commands not listed here are
internal and can change. See [What updates keep
stable](updating.md#what-updates-keep-stable).

## Update

- `hk-version`
  Print the installed version: the release tag, or `vX.Y.Z-N-g<commit>`
  between releases, with `-dirty` when tracked files have local changes. See
  [Versions](updating.md#versions).
- `hk-update-available`
  Fetch the update source and print bar-widget JSON that is visible when new
  commits are waiting. The shipped bar polls it hourly; offline it reuses the
  last fetched state.
- `hk-update check`
  Report the staged revision, the last applied revision, package changes, and
  pending migrations without changing anything.
- `hk-update all`
  Run `sync`, then `apply`, then personal `post-update` hooks. The update menu
  launches this command in a terminal.
- `hk-update sync`
  Fetch the configured remote and branch, show the new changelog entries and
  incoming commits, and pin one confirmed commit in XDG state. It does not move
  the live checkout.
- `hk-update apply`
  Fast-forward to the staged revision, then install and review packages, run
  pending migrations, copy new starting configs, restow, rebuild the theme,
  and reload. Quickshell is stopped meanwhile and started again however apply
  ends. With nothing staged, reapply the current checkout, which also repairs
  links and generated output.
- `hk-update remove-stale`
  Remove Hyprkarl links in `~/.config` whose target no longer exists.
- `hk-update packages`
  Install newly required packages and review retired ones; `apply` runs it.
- `hk-config-seed`
  Create missing personal files and starting configs, never overwriting one;
  `apply` runs it.

## Lifecycle Hooks

- `hk-autostart`
  Start Hyprkarl's session services at login: the shell, the idle daemon, the
  wallpaper, the cursor, and `login` hooks. Hyprland runs it once; a personal
  version in `~/.local/bin` replaces it.
- `hk-hook-run <event>`
  Run the hooks in `~/.config/hyprkarl/hooks/<event>.d/` in name order. Events
  are `login`, `post-update`, `theme-set`, and `wallpaper-set`; Hyprkarl runs
  each at that moment.

## Menus and Launching

- `hk-shell menu [toggle|open] [menu-id]` / `hk-shell menu close`
  Open, toggle, or close a menu, such as `hk-shell menu toggle main`. It opens
  on the focused monitor, or on the clicked bar's monitor from a bar widget.
- `hk-shell launcher [toggle|open|close]`
  Control the application launcher.
- `hk-shell calculator [toggle|open|close]`
  Control the Quickshell calculator. Results come from `qalc`; choosing one
  copies it to the clipboard and stores up to five recent calculations in XDG
  state.
- `hk-shell wallpaper <set|remove|close>`
  Open the Quickshell thumbnail picker to set or remove a wallpaper.
- `hk-keybindings-list`
  Print the live Hyprland keybindings shown by the searchable `keybindings`
  shell menu.
- `hk-icon-data-update`
  Refresh the `icons` menu's Nerd Font glyph list from upstream.

### Launching apps

- `hk-audio-launch`
  Launch the audio controls TUI (`wiremix`).
- `hk-bluetooth-launch`
  Launch the bluetooth controls TUI (`bluetui`). Unblocks bluetooth via
  `rfkill` first.
- `hk-wifi-launch`
  Launch the Wi-Fi controls TUI (`wifitui`). Unblocks Wi-Fi via `rfkill`
  first.
- `hk-browser-launch [--private] [args...]`
  Launch the default browser as defined by `xdg-settings`. `--private` is
  translated to the right private-browsing flag for the detected browser
  (Firefox, Edge, Chromium, etc.).
- `hk-editor-launch [args...]`
  Launch the editor set in `$EDITOR` (with `nvim` as a fallback). Known TUI
  editors run inside the hyprkarl terminal; everything else runs detached.
- `hk-tui-launch <command> [args...]`
  Run a terminal program in a floating Hyprkarl terminal window, as the menus
  do for updates and package pickers.
- `hk-terminal-open [args...]`
  Open a terminal window with the hyprkarl terminal app-id, waiting for it
  to close before returning. Arguments are forwarded to `xdg-terminal-exec`.
  Use `hk-tui-launch` instead when you don't need to wait for the result.
- `hk-open-with <file>`
  Show the shared Quickshell application picker for opening a file. Its custom
  switch optionally makes the selected application the default for the file's
  MIME type before launching it.
- `hk-lock`
  Lock the session.

### Power

- `hk-suspend`
  Suspend. Hypridle locks the session first.
- `hk-reboot`
  Reboot through `hyprshutdown` with the standard countdown overlay.
- `hk-shutdown`
  Shut down through `hyprshutdown` with the standard countdown overlay.

### Screenshots

- `hk-screenshot <window|output|region> [hyprshot options]`
  Capture with Hyprshot while preserving an open Quickshell feature panel.
  Additional options pass through to Hyprshot. The default `Print` bindings
  use this command for window, display, and region capture.

## Themes and Wallpapers

- `hk-theme set <theme>`
  Build a built-in source, personal source, or built-in plus same-name
  personal overlay; make it the active theme; copy its GTK theme; then update
  the wallpaper and application settings and reload affected programs.
- `hk-theme list`
  List installed themes.
- `hk-theme current`
  Print the current theme name.
- `hk-wallpaper set <filename>`
  Set the current wallpaper for the active theme.
- `hk-wallpaper cycle`
  Switch to the next wallpaper in the active theme.
- `hk-wallpaper add <path>`
  Copy an image into the active theme's wallpaper directory and set it as the
  current wallpaper.
- `hk-wallpaper remove <filename>`
  Remove a wallpaper and its cached preview.
- `hk-wallpaper cache [--regenerate|--single <filename>]`
  Sync or rebuild wallpaper previews for the active theme.
- `hk-wallpaper init`
  Reapply the current wallpaper through `hyprpaper`.

## Fingerprint

- `hk-shell menu open fingerprint`
  Open the setup-aware fingerprint workflow. Enrollment uses a dynamic picker
  containing only available fingers; removal uses a dynamic picker containing
  only enrolled fingers. Every fingerprint menu is rendered by Quickshell.
- `hk-fingerprint setup [--remove]`
  Configure fingerprint authentication for sudo and polkit, or remove it with
  `--remove`.
- `hk-fingerprint enroll <finger-name>`
  Enroll the specified fingerprint. The shell menu owns finger selection.
- `hk-fingerprint remove <finger-name>`
  Delete an enrolled fingerprint.
- `hk-fingerprint list`
  Print enrolled fingers, one per line.

## Defaults and Session Behavior

- `hk-default-terminal <terminal>`
  Install a terminal and make it the default by writing
  `~/.config/xdg-terminals.list`.
- `hk-default-editor <editor>`
  Install an editor and record it as `$EDITOR` in `~/.config/uwsm/default`.
- `hk-default-shell <shell>`
  Install a shell and make it the login shell.
- `hk-timezone-setup`
  Set the system timezone.

## Packages

- `hk-pkg-upgrade`
  Upgrade all installed packages (pacman + AUR) non-interactively, then prompt
  to reboot. Intended to be launched via `hk-tui-launch hk-pkg-upgrade` so it
  opens in a floating terminal.
- `hk-pkg-install-tui`
  Open an `fzf` package picker to install pacman packages.
- `hk-pkg-install-tui --aur`
  Open an `fzf` package picker to install AUR packages.
- `hk-pkg-install-tui --flatpak`
  Open an `fzf` package picker to install Flatpak apps.
- `hk-pkg-remove-tui`
  Open an `fzf` package picker to uninstall pacman packages.
- `hk-pkg-remove-tui --flatpak`
  Open an `fzf` package picker to uninstall Flatpak apps.
- `hk-pkg install <package>...`
  Install named pacman packages.
- `hk-pkg install --aur <package>...`
  Install named AUR packages.
- `hk-pkg install --flatpak <app-id>...`
  Install named Flatpak app ids.
- `hk-pkg remove <package>...`
  Remove named packages if they are installed.
- `hk-pkg remove --flatpak <app-id>...`
  Remove named Flatpak app ids if they are installed.
- `hk-pkg missing <package>...`
  Return success if any named package is missing.
- `hk-pkg missing --flatpak <app-id>...`
  Return success if any named Flatpak is missing.
- `hk-pkg present <package>...`
  Return success if all named packages are installed.
- `hk-pkg present --flatpak <app-id>...`
  Return success if all named Flatpaks are installed.

## Docker

- `hk-shell menu open docker-install`
  Open the shell-native Docker install menu, populated with services that are
  not installed.
- `hk-shell menu open docker-uninstall`
  Open the shell-native Docker uninstall menu, populated with installed
  services.
- `hk-docker install <service>`
  Install a local Docker service.
- `hk-docker uninstall <service>`
  Uninstall a local Docker service.
- `hk-docker list`
  Print the supported Docker service ids.

## Quickshell Shell

These commands manage and communicate with the session-started production
shell.

- `hk-shell start`, `stop`, `restart`
  Start, stop, or restart the shell. `start` reports QML load errors.
- `hk-shell status`
  Print JSON with `running` and the running instances; exits nonzero when
  stopped.
- `hk-shell logs [qs log options]`
  Show the shell's log, the last 200 lines by default; options such as
  `--follow` pass through to `qs log`.
- `hk-shell notifications <dismiss|dismiss-all|toggle-silenced|restore>`
  Dismiss notifications, silence them, or bring back the last one dismissed.
- `hk-shell osd <kind> ...`
  Show an OSD popup on the focused monitor, for your own keybindings. A media
  percentage of `-1` leaves out the progress bar:

  ```text
  hk-shell osd volume <percent> [muted]
  hk-shell osd audio-output <percent> <muted> <description>
  hk-shell osd microphone <muted>
  hk-shell osd display-brightness <percent>
  hk-shell osd keyboard-brightness <percent>
  hk-shell osd media <playing|paused|next|previous> <percent|-1> <title> [artist]
  ```

## UI Helpers

- `hk-terminal-reload`
  Reload terminal configs for supported terminals.
- `hk-workspace-swap <target_num>`
  Swap all windows between the active workspace and the target workspace, then
  focus the target. Tiled windows will be retiled on arrival.

## Media, Hardware, and Utilities

- `hk-screen-record`
  Start or stop screen recording. Supports desktop audio, microphone audio,
  webcam overlays, and explicit resolution arguments.
- `hk-video-compress [input] [target_size] [options]`
  Two-pass compression of a video file to a target file size. Prompts via
  `gum` for missing arguments unless `--non-interactive` is set.
- `hk-picture-select [directory]`
  Open `yazi` as an image picker and print the chosen path. Defaults to
  `~/Pictures`.
- `hk-video-select [directory]`
  Open `yazi` as a video picker and print the chosen path. Defaults to
  `~/Videos`.
- `hk-nightlight [on|off|toggle]`
  Enable, disable, or toggle hyprsunset nightlight (warm color temperature +
  gamma dimming).
- `hk-caffeine [on|off|toggle|status]`
  Pause idle locking and sleep with a systemd idle inhibitor. Hypridle keeps
  running, so manual suspend and lid close still lock first.
- `hk-display <state|scale|toggle|brightness> [arguments]`
  The display panel's backend. `state [output]` prints JSON,
  `scale <output> <factor>` and `toggle <output>` change a monitor and save
  the layout, and `brightness <output> <percent>` sets a built-in screen's
  backlight. The panel also uses internal `arrange`, `preview`, `confirm`,
  and `revert` actions.
- `hk-playerctl`
  Control media playback and show track state in the shell OSD.
- `hk-volume`
  Adjust audio volume and show the current level.
- `hk-mic`
  Toggle microphone mute and show the current state.
- `hk-webcam`
  Open a webcam preview window.
- `hk-dictionary`
  Dictionary TUI powered by `fzf` and the FreeDict DICT server.
- `hk-wifi-restart`
  Unblock Wi-Fi.
- `hk-audio-restart`
  Restart the PipeWire audio service.
- `hk-btop-reload`
  Reload the running `btop` so it picks up theme changes.

## Internal Helpers

Other scripts, keybindings, and bar widgets call these; they can change in
any release:

- Launching glue: `hk-app-restart`
- Hardware actions bound to function keys: `hk-brightness-display`,
  `hk-brightness-keyboard`, `hk-audio-switch`, `hk-battery-monitor`; display
  dispatcher actions: `hk-display-state`, `hk-display-arrange`,
  `hk-display-preview`, `hk-display-confirm`, `hk-display-revert`,
  `hk-display-scale`, `hk-display-toggle`, `hk-display-brightness`; internal
  timeout helper: `hk-display-watch`
- Notification helpers: `hk-battery-notify`, `hk-notify-window-class`,
  `hk-show-done`, `hk-suggest-reboot`
- Lookup helpers: `hk-battery-find`, `hk-icon-find`, `hk-cmd-present`,
  `hk-terminal-cwd`

## Notes

For editing conventions, see [Repo Conventions](repo-conventions.md) and
[Command Script Style](shell-style.md).
