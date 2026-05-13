#!/bin/bash
# Returns true if all listed Flatpaks are installed,
# or false if any are missing.

for app in "$@"; do
  flatpak info --system "$app" &>/dev/null || exit 1
done

exit 0
