# Command Reference

This page lists the `hk-*` commands you would normally run directly. It
does not try to document every internal script.

## Update

- `hk-update check`
  Report what would change across dotfiles, packages, and system without
  making any changes.
- `hk-update all [--force|--adopt]`
  Run dotfiles, packages, and system updates in sequence. `--force` and
  `--adopt` are passed through to the dotfiles step.
- `hk-update tui`
  Interactive guided update in a terminal: fetch and merge upstream (safe on a
  dirty working tree, with conflict resolution), review pending dotfile,
  package, and system changes as `delta` diffs, then apply the categories you
  select. Excludes the system package upgrade (`paru -Syu`) — see
  `hk-pkg-upgrade` for that. Launch via the update menu or
  `hk-launch-tui hk-update-tui`.
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

## Menus and Launching

- `hk-menu`
  Open the main Hyprkarl menu.
- `hk-menu-launcher`
  Open the rofi app launcher.
- `hk-menu-config`
  Open the configuration menu for themes, wallpapers, and defaults.
- `hk-menu-defaults`
  Open the defaults submenu (terminal, editor, shell).
- `hk-menu-editor` / `hk-menu-shell` / `hk-menu-terminal`
  Pick a default editor, shell, or terminal directly without going through the
  defaults menu.
- `hk-menu-install`
  Open the install menu for packages and Docker services.
- `hk-menu-uninstall`
  Open the uninstall menu for packages and Docker services.
- `hk-menu-update`
  Open the update menu: "Update Hyprkarl" launches the guided `hk-update tui`,
  "Upgrade Packages" runs the system package upgrade (`hk-pkg-upgrade`).
- `hk-menu-utils`
  Open the utilities submenu (toggles, screen recording, and other actions).
- `hk-menu-power`
  Open the power menu.
- `hk-menu-power-profile`
  Pick a `power-profiles-daemon` profile (performance / balanced / saver).
- `hk-menu-keybindings`
  Open a searchable rofi menu of all Hyprland keybindings. Pass `--print` /
  `-p` to print them to stdout instead.
- `hk-menu-calculator`
  Open `rofi-calc`. `Ctrl+Return` copies the current result to the clipboard;
  history is trimmed to five entries on exit.
- `hk-menu-icons`
  Open a fuzzy Nerd Font icon picker. Search by icon name, select an entry, and
  the glyph is copied to the clipboard. Requires the glyph data file — run
  `hk-icon-data-update` first if it is missing.
- `hk-icon-data-update`
  Download the latest Nerd Font glyph list from the upstream cheat-sheet and
  regenerate `~/.local/share/hyprkarl/data/nerdfont-glyphs.txt`. Re-run after upgrading
  Nerd Fonts to pick up new icons.

### Launching apps

- `hk-launch-audio`
  Launch the audio controls TUI (`wiremix`).
- `hk-launch-bluetooth`
  Launch the bluetooth controls TUI (`bluetui`). Unblocks bluetooth via
  `rfkill` first.
- `hk-launch-wifi`
  Launch the Wi-Fi controls TUI (`wifitui`). Unblocks Wi-Fi via `rfkill`
  first.
- `hk-launch-browser [--private] [args...]`
  Launch the default browser as defined by `xdg-settings`. `--private` is
  translated to the right private-browsing flag for the detected browser
  (Firefox, Edge, Chromium, etc.).
- `hk-launch-editor [args...]`
  Launch the editor set in `$EDITOR` (with `nvim` as a fallback). Known TUI
  editors run inside the hyprkarl terminal; everything else runs detached.
- `hk-open-terminal [args...]`
  Open a terminal window with the hyprkarl terminal app-id, waiting for it
  to close before returning. Arguments are forwarded to `xdg-terminal-exec`.
  Use `hk-launch-tui` instead when you don't need to wait for the result.
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

- `hk-menu-theme`
  Open the theme menu.
- `hk-theme set <theme>`
  Switch to a theme, update wallpaper state, update theme settings, and reload
  affected programs.
- `hk-theme list`
  List installed themes.
- `hk-theme current`
  Print the current theme name.
- `hk-menu-wallpaper`
  Open the wallpaper menu.
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

- `hk-menu-fingerprint`
  Open the fingerprint menu.
- `hk-fingerprint setup [--remove]`
  Configure fingerprint authentication for sudo and polkit, or remove it with
  `--remove`.
- `hk-fingerprint enroll [finger-name]`
  Enroll a fingerprint, prompting for a finger if omitted.
- `hk-fingerprint remove <finger-name>`
  Delete an enrolled fingerprint.
- `hk-fingerprint list`
  Print enrolled fingers, one per line.
- `hk-fingerprint select [message]`
  Show the fingerprint picker and print the selected finger name.

## Defaults and Session Behavior

- `hk-default-terminal <terminal>`
  Install a terminal and make it the default terminal.
- `hk-default-editor <editor>`
  Install an editor and make it the default editor.
- `hk-default-shell <shell>`
  Install a shell and make it the login shell.
- `hk-setup-timezone`
  Set the system timezone.

## Packages

- `hk-pkg-upgrade`
  Upgrade all installed packages (pacman + AUR) non-interactively, then prompt
  to reboot. Intended to be launched via `hk-launch-tui hk-pkg-upgrade` so it
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

- `hk-menu-docker-install`
  Open the Docker install menu.
- `hk-menu-docker-uninstall`
  Open the Docker uninstall menu.
- `hk-docker setup`
  Install Docker and Docker Compose, enable Docker, and add the user to the
  `docker` group.
- `hk-docker install <service>`
  Install a local Docker service.
- `hk-docker uninstall <service>`
  Uninstall a local Docker service.
- `hk-docker list`
  Print the supported Docker service ids.

## AGS Bar

- `hk-menu-ags`
  Open the AGS bar control menu. Shows current state for visibility, autohide,
  and exclusive zone; selecting an item toggles it.

- `hk-ags restart`
  Gracefully quit AGS, wait for the process to exit, then restart it under
  uwsm-app.
- `hk-ags start`
  Start AGS if it is not running.
- `hk-ags stop`
  Quit AGS if it is running.
- `hk-ags autohide [on|off|toggle]`
  Control bar autohide behavior. Defaults to `toggle`.
- `hk-ags exclusive [on|off|toggle]`
  Control whether the bar reserves an exclusive zone. Defaults to `toggle`.
- `hk-ags show`
  Force the bar visible.
- `hk-ags hide`
  Force the bar hidden.
- `hk-ags toggle`
  Toggle bar visibility.
- `hk-ags status`
  Print bar status as JSON (`autohide`, `exclusive`, `hidden`).
- `hk-ags request [args...]`
  Send an arbitrary request to the running AGS instance.

## UI Helpers

- `hk-mako-reload`
  Reload mako.
- `hk-terminal-reload`
  Reload terminal configs for supported terminals.
- `hk-workspace-swap <target_num>`
  Swap all windows between the active workspace and the target workspace, then
  focus the target. Tiled windows will be retiled on arrival.

## Media, Hardware, and Utilities

- `hk-record-screen`
  Start or stop screen recording. Supports desktop audio, microphone audio,
  webcam overlays, and explicit resolution arguments.
- `hk-compress-video [input] [target_size] [options]`
  Two-pass compression of a video file to a target file size. Prompts via
  `gum` for missing arguments unless `--non-interactive` is set.
- `hk-select-picture [directory]`
  Open `yazi` as an image picker and print the chosen path. Defaults to
  `~/Pictures`.
- `hk-select-video [directory]`
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

- Launching glue: `hk-launch-tui`, `hk-restart-app`
- Hardware actions bound to function keys: `hk-brightness-display`,
  `hk-brightness-keyboard`, `hk-audio-switch`, `hk-battery-monitor`
- Notification and OSD helpers: `hk-notify-battery`, `hk-notify-window-class`,
  `hk-show-done`, `hk-suggest-reboot`
- Lookup helpers: `hk-find-battery`, `hk-find-icon`, `hk-cmd-present`,
  `hk-terminal-cwd`

If you need behavior one of these provides from your own script, source or
shell it out the same way the existing callers do.

## Notes

For editing conventions, see [Repo Conventions](repo-conventions.md) and
[Shell Style](shell-style.md).
