#!/bin/bash
# Install listed pacman packages. Returns false if it couldn't be done.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if "$SCRIPT_DIR/missing.sh" "$@"; then
  sudo pacman -S --noconfirm --needed "$@" || exit 1
fi

for pkg in "$@"; do
  if ! pacman -Q "$pkg" &>/dev/null; then
    printf '\033[31mError: Package %q did not install\033[0m\n' "$pkg" >&2
    exit 1
  fi
done

exit 0
