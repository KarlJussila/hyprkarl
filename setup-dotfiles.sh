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

# Create personal env var file from template if it doesn't exist
if [[ ! -f ~/.config/uwsm/env.local ]]; then
  cp "$HOME/.local/share/hyprkarl/templates/setup/env.local.example" ~/.config/uwsm/env.local
fi

# Set up AGS type definitions.
# ags types -u rewrites config/ags/tsconfig.json through the stow symlink.
# If the installed astal versions differ from what's committed, the file will
# be dirty — review with: git -C ~/.local/share/hyprkarl diff config/ags/tsconfig.json
ags types -u -d ~/.config/ags
if ! git -C "$HOME/.local/share/hyprkarl" diff --quiet -- config/ags/tsconfig.json 2>/dev/null; then
  printf 'Note: AGS type paths updated in config/ags/tsconfig.json\n'
  printf '  Review: git -C %s diff config/ags/tsconfig.json\n' "$HOME/.local/share/hyprkarl"
  printf '  Commit if the changes look correct.\n'
fi

# Stow the GTK theme
rm -rf "$HOME/.local/share/themes/hyprkarl"
mkdir -p "$HOME/.local/share/themes/hyprkarl"
stow --restow --no-folding \
  --dir="$HOME/.local/share/hyprkarl/config/hyprkarl/current/theme" \
  --target="$HOME/.local/share/themes/hyprkarl" \
  gtk-theme

hyprctl reload

# Record installed commit for update tracking
mkdir -p "$HOME/.local/share/hyprkarl/config/hyprkarl/update"
git -C "$HOME/.local/share/hyprkarl" rev-parse HEAD \
  >"$HOME/.local/share/hyprkarl/config/hyprkarl/update/dotfiles.commit"
