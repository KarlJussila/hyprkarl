#!/bin/bash
# Display a fingerprint picker and print the selected finger name to stdout.
#
# Usage:
#   hk-fingerprint select [message]

# Get enrolled fingers
fingers=$(hk-fingerprint list)

if [[ -z "$fingers" ]]; then
  exit 1
fi

# Format for display: hyphens to spaces, capitalize.
format_display() {
  echo "$1" | sed -E 's/(^|-)([a-z])/\1\u\2/g; s/-/ /g'
}

# Convert back: spaces to hyphens, lowercase
format_store() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

# Build display list
display_list=()
while IFS= read -r finger; do
  [[ -n "$finger" ]] && display_list+=("$(format_display "$finger")")
done <<< "$fingers"

# Message for rofi
message="${1:-Select Fingerprint}"

# Show rofi menu
selected=$(printf '%s\n' "${display_list[@]}" | rofi -dmenu -p "" -no-custom -mesg "$message" -theme ~/.config/rofi/custom-menu.rasi) || exit 1

# Convert back to storage format
format_store "$selected"
