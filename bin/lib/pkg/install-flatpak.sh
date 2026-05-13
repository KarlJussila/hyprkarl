#!/bin/bash
# Install listed Flatpaks from Flathub. Returns false if it couldn't be done.

flatpak install flathub --system -y "$@" || exit 1

for app in "$@"; do
  if ! flatpak info --system "$app" &>/dev/null; then
    printf '\033[31mError: Flatpak %q did not install\033[0m\n' "$app" >&2
    exit 1
  fi
done

exit 0
