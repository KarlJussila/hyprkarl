#!/bin/bash
# Display a wallpaper picker and print the selected filename to stdout.
#
# Usage:
#   hk-wallpaper select [highlight-color]
#
#   highlight-color   Optional hex color for the selection border (e.g. #cc5555).
#                     Defaults to the theme's highlight color if omitted.

THEME_NAME=$(cat "$HYPRKARL_PATH/config/hyprkarl/current/theme.name")
WALLPAPER_DIR="$HYPRKARL_PATH/config/hyprkarl/current/theme/wallpapers"
CACHE_DIR="$HOME/.cache/hyprkarl/wallpapers/$THEME_NAME"

# Apply optional highlight color
if [[ -n "$1" ]]; then
    color_override="* { select-border: $1; }"
fi

hk-wallpaper cache

mapfile -t wallpapers < <(
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        -printf '%f\n' \
        | sort
)

if ((${#wallpapers[@]} == 0)); then
    echo "No wallpapers found in $WALLPAPER_DIR" >&2
    exit 1
fi

# Calculate icon and window sizing based on focused monitor
logical_height=$(hyprctl monitors -j | jq '[.[] | select(.focused)][0] | .height / .scale | floor')
icon_size=$(( logical_height / 4 )) # 25% of logical height (width of an icon)
window_width=$(( icon_size * 3 + 70 )) # 3 icons, plus padding

# Rofi command
rofi_override="window{width:${window_width}px;} element-icon{size:${icon_size}px;} ${color_override:-}"

# Display menu
selected=$(
    for name in "${wallpapers[@]}"; do
        echo -en "$name\x00icon\x1f$CACHE_DIR/$name\n"
    done \
        | \
    rofi -dmenu -theme "$HOME/.config/rofi/wallpapers.rasi" -theme-str "$rofi_override"
)

[[ -n "$selected" ]] || exit 1

echo "$selected"
