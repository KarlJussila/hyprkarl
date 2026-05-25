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
- `hk-update dotfiles`
  Re-stow config files and remove stale symlinks. Checks for conflicts first
  and aborts if any are found.
- `hk-update dotfiles --force`
  Re-stow using the adopt-and-checkout flow, overwriting any conflicting files
  in `~/.config/`. Requires a clean git working tree.
- `hk-update dotfiles --adopt`
  Adopt conflicting `~/.config/` files into the repo without overwriting them,
  then report what differs so you can review and commit or discard.
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
- `hk-menu-install`
  Open the install menu for packages and Docker services.
- `hk-menu-uninstall`
  Open the uninstall menu for packages and Docker services.
- `hk-menu-power`
  Open the power menu.

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

- `hk-pkg-install-tui`
  Open an `fzf` package picker for pacman packages.
- `hk-pkg-install-tui --aur`
  Open an `fzf` package picker for AUR packages.
- `hk-pkg-install-tui --flatpak`
  Open an `fzf` package picker for Flatpak apps.
- `hk-pkg-remove-tui`
  Open an `fzf` picker for installed packages.
- `hk-pkg-remove-tui --flatpak`
  Open an `fzf` picker for installed Flatpak apps.
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

- `hk-ags-restart`
  Gracefully quit AGS, wait for the process to exit, then restart it under
  uwsm-app.
- `hk-ags-toggle`
  Start AGS if it is not running; quit it if it is.

## UI Helpers

- `hk-mako-reload`
  Reload mako.
- `hk-terminal-reload`
  Reload terminal configs for supported terminals.

## Media, Hardware, and Utilities

- `hk-record-screen`
  Start or stop screen recording. Supports desktop audio, microphone audio,
  webcam overlays, and explicit resolution arguments.
- `hk-nightlight`
  Toggle Hyprsunset.
- `hk-caffeine`
  Toggle the idle inhibitor.
- `hk-playerctl`
  Control media playback and show track notifications.
- `hk-volume`
  Adjust audio volume and show the current level.
- `hk-mic`
  Toggle microphone mute and show the current state.
- `hk-webcam`
  Open a webcam preview window.
- `hk-wifi-restart`
  Unblock Wi-Fi.
- `hk-audio-restart`
  Restart the PipeWire audio service.

## Notes

For editing conventions, see [Repo Conventions](repo-conventions.md) and
[Shell Style](../shell-style.md).
