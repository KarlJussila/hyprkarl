#!/bin/bash

# Install hyprkarl's configs via symlink in ~/.config and ~/.local/share/applications.
# WARNING: This will replace any identically named files.
# Please back up anything that you might want to keep.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HYPRKARL_PATH="${HYPRKARL_PATH:-$SCRIPT_DIR}"

# Mirror the hk-update-dotfiles --force guard before starting the install, so a
# doomed run fails before any live configuration is changed.
dirty=$(git -C "$SCRIPT_DIR" diff --name-only HEAD -- config/ applications/ themes/)
if [[ -n "$dirty" ]]; then
  printf 'Cannot install dotfiles — uncommitted changes would be overwritten:\n%s\n' "$dirty" >&2
  printf 'Commit your changes first.\n' >&2
  exit 1
fi

# Stow config/ and applications/, then install the active GTK payload as a
# managed real-file copy. This refuses to run if the repo has uncommitted
# config changes (the reset to HEAD would silently discard them) and records
# the installed commit for update tracking.
"$SCRIPT_DIR/bin/hk-update-dotfiles" --force || exit 1

# Seed the current-wallpaper symlink so it's already set on first login,
# rather than relying on autostart's `hk-wallpaper init || cycle` fallback
# to win a race against hyprpaper starting up on the very first boot.
PATH="$SCRIPT_DIR/bin:$PATH" "$SCRIPT_DIR/bin/hk-wallpaper-cycle"
