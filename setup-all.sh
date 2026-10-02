#!/bin/bash
# Install Hyprkarl on a CachyOS + Hyprland system.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$EUID" -eq 0 ]]; then
  echo "Run setup as your normal user, not root; it uses sudo where needed." >&2
  exit 1
fi
if ! command -v pacman >/dev/null; then
  echo "Hyprkarl needs an Arch-based system with pacman (CachyOS)." >&2
  exit 1
fi
# config/uwsm/env puts this path on PATH for every session.
if [[ "$SCRIPT_DIR" != "$HOME/.local/share/hyprkarl" ]]; then
  echo "Clone Hyprkarl to ~/.local/share/hyprkarl; it is at $SCRIPT_DIR." >&2
  exit 1
fi

"$SCRIPT_DIR/setup-purge-noctalia.sh" || exit 1
"$SCRIPT_DIR/setup-packages.sh" || exit 1
"$SCRIPT_DIR/setup-dotfiles.sh" || exit 1
"$SCRIPT_DIR/setup-system.sh" || exit 1

gum confirm "Restart required for changes to take effect. Restart now?" && "$SCRIPT_DIR/bin/hk-reboot"
"$SCRIPT_DIR/bin/hk-suggest-reboot"
