#!/bin/bash

# This script installs hyprkarl's configs via symlink in ~/.config and ~/.local/share/applications
# WARNING: This will replace any identically named files.
# Please back up anything that you might want to keep

# Unstow in case an older version with folding enabled was already installed
stow -D --ignore='@girs' --ignore='node_modules' --dir=$HOME/.local/share/hyprkarl --target=$HOME/.config config

# Adopt the config files, then replace with hyprkarl configs
stow --ignore='@girs' --ignore='node_modules' --dir=$HOME/.local/share/hyprkarl --target=$HOME/.config config --adopt --no-folding
mkdir -p "$HOME/.local/share/applications"
stow --dir=$HOME/.local/share/hyprkarl --target=$HOME/.local/share/applications applications --adopt --no-folding
git -C ~/.local/share/hyprkarl checkout config/
git -C ~/.local/share/hyprkarl checkout applications/

# Set up AGS
ags types -u -d ~/.config/ags

# Stow the GTK theme
rm -f "$HOME/.local/share/themes/hyprkarl"
mkdir -p "$HOME/.local/share/themes/hyprkarl"
stow --no-folding \
  --dir="$HOME/.local/share/hyprkarl/config/hyprkarl/current/theme" \
  --target="$HOME/.local/share/themes/hyprkarl" \
  gtk-theme

hyprctl reload

# Record installed commit for update tracking
mkdir -p "$HOME/.local/share/hyprkarl/config/hyprkarl/update"
git -C "$HOME/.local/share/hyprkarl" rev-parse HEAD \
  > "$HOME/.local/share/hyprkarl/config/hyprkarl/update/dotfiles.commit"
