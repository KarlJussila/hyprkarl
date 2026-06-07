#!/bin/bash

# This script installs packages for the hyprkarl setup.
# NOTE: It also removes some packages that are replaced with alternatives.
# Use paru consistently for AUR-backed installs and queries.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

read_pkgs() {
  grep -v '^[[:space:]]*#' "$1" | grep -v '^[[:space:]]*$' | sed 's/[[:space:]]*#.*//'
}

# Install packages
mapfile -t pacman_pkgs < <(read_pkgs "$SCRIPT_DIR/packages/pacman.txt")
sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}"

mapfile -t aur_pkgs < <(read_pkgs "$SCRIPT_DIR/packages/aur.txt")
paru -S --needed --noconfirm "${aur_pkgs[@]}"

# Remove packages
mapfile -t remove_pkgs < <(read_pkgs "$SCRIPT_DIR/packages/remove.txt")
if [[ ${#remove_pkgs[@]} -gt 0 ]]; then
  sudo pacman -Rns --noconfirm "${remove_pkgs[@]}"
fi

# Record installed commit for update tracking
mkdir -p "$SCRIPT_DIR/config/hyprkarl/update"
git -C "$SCRIPT_DIR" rev-parse HEAD > "$SCRIPT_DIR/config/hyprkarl/update/packages.commit"
