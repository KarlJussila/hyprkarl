#!/bin/bash
# Install Hyprkarl on a CachyOS + Hyprland system.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HYPRKARL_PATH="$SCRIPT_DIR"
export PATH="$SCRIPT_DIR/bin:$PATH"

if [[ "$EUID" -eq 0 ]]; then
  echo "Run the installer as your normal user, not root; it uses sudo where needed." >&2
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

# The update workflow itself needs these before it can install the rest.
# Upgrade first: installing from a stale package database fails.
sudo pacman -Syu --needed --noconfirm gum jq python || exit 1
source "$SCRIPT_DIR/bin/lib/update.sh"
update_configure_source || exit 1

# The same apply an update uses: packages, migrations, starting configs,
# shipped links, and the theme.
hk-update-apply || exit 1

gum confirm "Restart required for changes to take effect. Restart now?" && hk-reboot
hk-suggest-reboot
