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
sudo pacman -Syu --needed --noconfirm gum jq python stow || exit 1
source "$SCRIPT_DIR/bin/lib/update.sh"
update_configure_source || exit 1

# The system's own configs for applications Hyprkarl configures, such as
# CachyOS's hyprland.lua, would block Hyprkarl's links.
backup="$HOME/.local/state/hyprkarl/replaced-configs-$(date +%Y%m%d-%H%M%S)"
moved=$(move_config_conflicts "$backup") || exit 1
if [[ -n "$moved" ]]; then
  printf 'Moved these configs, which Hyprkarl replaces, to %s:\n%s\n' "$backup" "$moved"
fi

# The same apply an update uses: packages, migrations, starting configs,
# shipped links, and the theme.
hk-update-apply || exit 1

gum confirm "Restart required for changes to take effect. Restart now?" && hk-reboot
hk-suggest-reboot
