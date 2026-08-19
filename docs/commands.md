# Command Reference

This page lists the `hk-*` commands you would normally run directly. It
does not try to document every internal script.

## Update

- `hk-update check`
  Report what would change across configuration, packages, and system without
  making any changes. Configuration output separates upstream-owned defaults
  from user-owned files, which are review-only.
- `hk-update all [--force|--adopt]`
  Run dotfiles, packages, and system updates in sequence. `--force` and
  `--adopt` are passed through to the dotfiles step.
- `hk-update tui`
  Interactive guided update in a terminal: fetch and merge upstream (safe on a
  dirty working tree, with conflict resolution), review upstream and user
  configuration separately from package and system changes, then apply the categories you
  select. Excludes the system package upgrade (`paru -Syu`) — see
  `hk-pkg-upgrade` for that. Launch via the update menu or
  `hk-tui-launch hk-update-tui`.
- `hk-update dotfiles`
  Re-stow config files and remove stale symlinks. Checks for conflicts first
  and aborts if any are found.
- `hk-update dotfiles --force`
  Re-stow using the adopt-and-checkout flow, overwriting any conflicting files
  in `~/.config/`. Requires a clean git working tree.
- `hk-update dotfiles --adopt`
  Adopt conflicting `~/.config/` files into the repo without overwriting them,
  then report what differs so you can review and commit or discard.
- `hk-update remove-stale`
  Remove stale hyprkarl symlinks and empty directories from `~/.config/` and
  related directories without restowing. Useful when cleaning up after removing
  files from the repo.
- `hk-update packages`
  Install packages newly added to the required lists, prompt to remove packages
  that were dropped or added to the removal list.
- `hk-update system`
  Re-run `setup-system.sh`.

Full update workflows (`hk-update all` and `hk-update tui`) run the
`post-update` lifecycle hooks after completing successfully. Individual
category commands do not emit that event.

## Lifecycle Hooks

- `hk-hook-run <event>`
  Run personal executable hooks from `user/hooks/<event>.d/` in lexical order.
  Supported events are `post-boot`, `post-update`, `theme-set`, and
  `wallpaper-set`. This is normally called by the corresponding Hyprkarl
  action rather than manually.

## Menus and Launching

- `hk-shell menu [toggle|open] [menu-id]` / `hk-shell menu close`
  Control the Quickshell menu through its public IPC boundary. For example,
  `hk-shell menu toggle main`, `hk-shell menu open theme`, and
  `hk-shell menu open fingerprint`. Static forwarding aliases are not part of
  the command surface; bindings and scripts should use this command directly.
- `hk-menu-launcher`
  Open the rofi app launcher.
- `hk-keybindings-list`
  Print the live Hyprland keybindings shown by the searchable `keybindings`
  shell menu.
- `hk-menu-calculator`
  Open `rofi-calc`. `Ctrl+Return` copies the current result to the clipboard;
  history is trimmed to five entries on exit.
- `hk-icon-data-update`
  Download the latest Nerd Font glyph list from the upstream cheat-sheet and
  regenerate the provider-ready
  `~/.local/share/hyprkarl/data/nerdfont-menu.json`. Re-run after upgrading
  Nerd Fonts to pick up new icons shown by the searchable `icons` shell menu.

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
- `hk-terminal-open [args...]`
  Open a terminal window with the hyprkarl terminal app-id, waiting for it
  to close before returning. Arguments are forwarded to `xdg-terminal-exec`.
  Use `hk-tui-launch` instead when you don't need to wait for the result.
- `hk-open-with <file>`
  Show a rofi-based app picker for opening a file.
- `hk-lock`
  Launch `hyprlock` if it is not already running and wait until its Wayland
  surface is present before returning.

### Power

- `hk-suspend`
  Lock the session with `hk-lock`, then `systemctl suspend`.
- `hk-reboot`
  Reboot through `hyprshutdown` with the standard countdown overlay.
- `hk-shutdown`
  Shut down through `hyprshutdown` with the standard countdown overlay.

## Themes and Wallpapers

- `hk-theme set <theme>`
  Switch to a theme, update wallpaper state, update theme settings, and reload
  affected programs.
- `hk-theme list`
  List installed themes.
- `hk-theme current`
  Print the current theme name.
- `hk-menu-wallpaper`
  Open the shell-native wallpaper management menu. Select and Remove continue
  into the thumbnail picker; Add opens the file picker in a terminal.
- `hk-wallpaper set <filename>`
  Set the current wallpaper for the active theme.
- `hk-wallpaper cycle`
  Switch to the next wallpaper in the active theme.
- `hk-wallpaper select`
  Show the wallpaper picker and print the selected filename.
- `hk-wallpaper add <path>`
  Copy an image into the active theme's wallpaper directory and set it as the
  current wallpaper.
- `hk-wallpaper remove <filename>`
  Remove a wallpaper and its cached thumbnail.
- `hk-wallpaper cache [--regenerate|--single <filename>]`
  Sync or rebuild wallpaper thumbnails for the active theme.
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
  Install a terminal and make it the default terminal.
- `hk-default-editor <editor>`
  Install an editor and make it the default editor.
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

- `hk-shell start`
  Start the Hyprkarl Quickshell configuration in a UWSM scope if it is not
  already running. The command verifies that Quickshell registered a live
  instance and reports QML load failures.
- `hk-shell stop`
  Stop every running instance of the Hyprkarl Quickshell configuration. It is
  safe to run when the bar is already stopped and does not return until
  Quickshell has unregistered the stopped instances.
- `hk-shell restart`
  Stop and start the bar after shutdown completes.
- `hk-shell status`
  Print JSON containing `running` and the registered instances' IDs, process
  IDs, and launch times. Exits nonzero when stopped.
- `hk-shell logs [qs log options]`
  Read the newest running instance's log, or the newest stopped instance when
  the shell is not running. With no options it shows the last 200 lines;
  native options such as `--follow`, `--tail 100`, and `--no-color` pass
  through to `qs log`.
- `hk-shell menu [toggle|open] [menu-id]` / `hk-shell menu close`
  Open, toggle, or close the shell-native command menu. This is also described
  with the menu commands above.

## UI Helpers

- `hk-mako-reload`
  Reload mako.
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
- `hk-caffeine`
  Toggle idle behaviors (hypridle).
- `hk-playerctl`
  Control media playback and show track notifications.
- `hk-volume`
  Adjust audio volume and show the current level.
- `hk-mic`
  Toggle microphone mute and show the current state.
- `hk-webcam`
  Open a webcam preview window.
- `hk-dictionary`
  Dictionary TUI powered by `fzf` and dict.org.
- `hk-wifi-restart`
  Unblock Wi-Fi.
- `hk-audio-restart`
  Restart the PipeWire audio service.
- `hk-btop-reload`
  Reload the running `btop` so it picks up theme changes.

## Internal Helpers

These `hk-*` commands exist in `bin/` but are not meant to be typed directly.
They are invoked by other scripts, keybindings, and bar widgets. Listed for
completeness so they can be discovered with grep:

- Launching glue: `hk-tui-launch`, `hk-app-restart`
- Hardware actions bound to function keys: `hk-brightness-display`,
  `hk-brightness-keyboard`, `hk-audio-switch`, `hk-battery-monitor`
- Notification and OSD helpers: `hk-battery-notify`, `hk-notify-window-class`,
  `hk-show-done`, `hk-suggest-reboot`
- Lookup helpers: `hk-battery-find`, `hk-icon-find`, `hk-cmd-present`,
  `hk-terminal-cwd`

If you need behavior one of these provides from your own script, source or
shell it out the same way the existing callers do.

## Notes

For editing conventions, see [Repo Conventions](repo-conventions.md) and
[Command Script Style](shell-style.md).
