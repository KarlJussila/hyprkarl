#!/bin/bash
# Re-stow the tracked config and desktop-entry trees into the user's home.

stow --dir="$HOME/.local/share/hyprkarl" --target="$HOME/.config" config --no-folding
stow --dir="$HOME/.local/share/hyprkarl" --target="$HOME/.local/share/applications" applications --no-folding
