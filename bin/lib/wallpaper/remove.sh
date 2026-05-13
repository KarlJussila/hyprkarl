#!/bin/bash
# Remove a wallpaper from the current theme and delete its cached thumbnail.
#
# Usage:
#   hk-wallpaper remove <wallpaper_filename>

THEME_NAME=$(cat "$HYPRKARL_PATH/config/hyprkarl/current/theme.name")
WALLPAPER_DIR="$HYPRKARL_PATH/config/hyprkarl/current/theme/wallpapers"
CACHE_DIR="$HOME/.cache/hyprkarl/wallpapers/$THEME_NAME"

wallpaper_name="$1"

if [[ -z "$wallpaper_name" ]]; then
    echo "Usage: hk-wallpaper remove <wallpaper_filename>" >&2
    exit 1
fi

rm -f "$WALLPAPER_DIR/$wallpaper_name"
rm -f "$CACHE_DIR/$wallpaper_name"
