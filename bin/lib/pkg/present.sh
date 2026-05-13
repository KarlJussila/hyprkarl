#!/bin/bash
# Returns true if all listed packages are installed,
# or false if any are missing.

for pkg in "$@"; do
  pacman -Q "$pkg" &>/dev/null || exit 1
done

exit 0
