#!/bin/bash
# Replaces a color value in all SVGs in the current directory.

# Usage:
#   hyprkarl-icons-recolor <find> <replace>

# Example:
#   hyprkarl-icons-recolor currentColor "#d2ccd2"

find="${1:-}"
replace="${2:-}"
[[ -n "$find" && -n "$replace" ]] || {
  echo "Usage: hyprkarl-icons-recolor <find> <replace>" >&2
  exit 1
}

for svg in ./*.svg; do
  [ -f "$svg" ] || continue
  sed -i "s/${find}/${replace}/g" "$svg"
done
