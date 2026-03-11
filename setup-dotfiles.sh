#!/bin/bash

# This script installs hyprkarl's configs via symlink in ~/.config and ~/.local/share/applications
# WARNING: This will replace any identically named files.
# Please back up anything that you might want to keep

# Unstow in case an older version with folding enabled was already installed
stow -D --dir=$HOME/.local/share/hyprkarl --target=$HOME/.config config

# Adopt the config files, then replace with hyprkarl configs
stow --dir=$HOME/.local/share/hyprkarl --target=$HOME/.config config --adopt --no-folding
stow --dir=$HOME/.local/share/hyprkarl --target=$HOME/.local/share/applications applications --adopt --no-folding
git -C ~/.local/share/hyprkarl checkout config/
git -C ~/.local/share/hyprkarl checkout applications/

hyprctl reload