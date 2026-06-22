#!/bin/bash

# This script installs hyprkarl's configs via symlink in ~/.config and ~/.local/share/applications
# WARNING: This will replace any identically named files.
# Please back up anything that you might want to keep

# Build the AGS bar's generated, gitignored artifacts BEFORE stowing, so stow
# symlinks them into ~/.config/ags like everything else (config/ags/node_modules
# and config/ags/@girs are never committed):
#   - npm install builds node_modules with RELATIVE ags/gnim symlinks (recorded
#     as links in package-lock.json, so no registry fetch). Relative is the
#     point: GNU Stow aborts the whole operation on an ABSOLUTE symlink, so the
#     links must be relative to be stowable.
#   - `ags types` (no -u) generates the @girs type defs without touching the
#     tracked tsconfig.json — that is refreshed after the git checkout below.
AGS_REPO_DIR="$HOME/.local/share/hyprkarl/config/ags"
npm --prefix "$AGS_REPO_DIR" install
ags types -d "$AGS_REPO_DIR"

# Older installs generated real @girs/node_modules directly under ~/.config/ags
# (they were stow-ignored then); remove them so stow replaces them with symlinks
# into the repo. No-op on a fresh install.
rm -rf "$HOME/.config/ags/@girs" "$HOME/.config/ags/node_modules"

# Unstow in case an older version with folding enabled was already installed
stow -D --dir=$HOME/.local/share/hyprkarl --target=$HOME/.config config

# Adopt the config files, then replace with hyprkarl configs
stow --dir=$HOME/.local/share/hyprkarl --target=$HOME/.config config --adopt --no-folding
mkdir -p "$HOME/.local/share/applications"
stow --dir=$HOME/.local/share/hyprkarl --target=$HOME/.local/share/applications applications --adopt --no-folding
git -C ~/.local/share/hyprkarl checkout config/
git -C ~/.local/share/hyprkarl checkout applications/

# Create personal env var file from template if it doesn't exist
if [[ ! -f ~/.config/uwsm/env.local ]]; then
  cp "$HOME/.local/share/hyprkarl/templates/setup/env.local.example" ~/.config/uwsm/env.local
fi

# The git checkout above reverted tsconfig.json; (re)apply the AGS type paths.
# `ags types -u` rewrites tsconfig for the installed astal versions and refreshes
# the node_modules/ags link. If it differs from what's committed the file goes
# dirty — review the diff before committing.
ags types -u -d "$AGS_REPO_DIR"
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
