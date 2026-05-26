#!/bin/bash
# Switch the active Hyprkarl theme and reload affected components.
#
# Usage:
#   hk-theme set <theme-name>
#
# The theme name is case-insensitive and spaces are treated as hyphens,
# so "Forest Dark" and "forest-dark" are equivalent.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [[ -z $1 ]]; then
  echo "Usage: hk-theme set <theme-name>"
  exit 1
fi

THEMES_PATH="$HYPRKARL_PATH/themes"
THEME_LINK="$HYPRKARL_PATH/config/hyprkarl/current/theme"
THEME_NAME=$(echo "$*" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

if [[ ! -d "$THEMES_PATH/$THEME_NAME" ]]; then
  echo "Theme '$THEME_NAME' does not exist"
  exit 1
fi

# Swap the theme symlink
ln -sfn "../../../themes/$THEME_NAME" "$THEME_LINK"

# Store theme name for reference
echo "$THEME_NAME" > "$HYPRKARL_PATH/config/hyprkarl/current/theme.name"

# Refresh wallpaper
hk-wallpaper init || hk-wallpaper cycle

# Set gtk/qt themes
"$SCRIPT_DIR/set-gtk.sh"

# Restart components to apply new theme
if pgrep -x ags >/dev/null; then
  hk-ags restart
fi
hyprctl reload >/dev/null
hk-mako-reload
hk-terminal-reload
hk-btop-reload
