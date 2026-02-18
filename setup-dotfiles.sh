#!/bin/bash

# This script installs hyprkarl's dotfiles via symlink in ~/.config
# WARNING: This will replace any identically named files.
# Please back up anything in ~/.config that you might want to keep

# Create directories in case they don't exist
mkdir -p $HOME/.config/hypr/bindings
mkdir -p $HOME/.config/hyprkarl/current/theme
mkdir -p $HOME/.config/kitty
mkdir -p $HOME/.config/uwsm
mkdir -p $HOME/.config/waybar

# Adopt the config files, then replace with hyprkarl configs
stow --dir=$HOME/.local/share/hyprkarl --target=$HOME/.config config --adopt
git -C ~/.local/share/hyprkarl checkout config/