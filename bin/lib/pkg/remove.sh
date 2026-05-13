#!/bin/bash
# Remove all the named pacman packages if they're installed (otherwise ignore).

for pkg in "$@"; do
  if pacman -Q "$pkg" &>/dev/null; then
    sudo pacman -Rns --noconfirm "$pkg" || exit 1
  else
    printf 'Skipping not-installed package: %s\n' "$pkg" >&2
  fi
done
