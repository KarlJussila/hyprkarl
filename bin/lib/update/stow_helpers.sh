_stow_conflicts() {
  stow -n -v "$@" 2>&1 | grep '^CONFLICT:'
}

_stow_gtk_theme() {
  local force_clear="${1:-0}"
  if [[ "$force_clear" -eq 1 ]]; then
    rm -rf "$HOME/.local/share/themes/hyprkarl"
  fi
  mkdir -p "$HOME/.local/share/themes/hyprkarl"
  stow --restow --no-folding \
    --dir="$HYPRKARL_PATH/config/hyprkarl/current/theme" \
    --target="$HOME/.local/share/themes/hyprkarl" \
    gtk-theme
}

check_config_conflicts() {
  _stow_conflicts --restow --no-folding --ignore='@girs' --ignore='node_modules' \
    --dir="$HYPRKARL_PATH" \
    --target="$HOME/.config" \
    config
  _stow_conflicts --restow --no-folding \
    --dir="$HYPRKARL_PATH" \
    --target="$HOME/.local/share/applications" \
    applications
  mkdir -p "$HOME/.local/share/themes/hyprkarl"
  _stow_conflicts --restow --no-folding \
    --dir="$HYPRKARL_PATH/config/hyprkarl/current/theme" \
    --target="$HOME/.local/share/themes/hyprkarl" \
    gtk-theme
}

stow_adopt_config() {
  stow -D --ignore='@girs' --ignore='node_modules' --no-folding \
    --dir="$HYPRKARL_PATH" --target="$HOME/.config" config
  stow --ignore='@girs' --ignore='node_modules' --adopt --no-folding \
    --dir="$HYPRKARL_PATH" --target="$HOME/.config" config
  stow --adopt --no-folding \
    --dir="$HYPRKARL_PATH" --target="$HOME/.local/share/applications" applications
  _stow_gtk_theme 1
}

stow_restow_config() {
  stow --restow --no-folding --ignore='@girs' --ignore='node_modules' \
    --dir="$HYPRKARL_PATH" \
    --target="$HOME/.config" \
    config
  stow --restow --no-folding \
    --dir="$HYPRKARL_PATH" \
    --target="$HOME/.local/share/applications" \
    applications
  _stow_gtk_theme 0
}

remove_stale_symlinks() {
  while IFS= read -r link; do
    if [[ ! -e "$link" ]]; then
      target=$(readlink "$link")
      if [[ "$target" == *"hyprkarl"* ]]; then
        rm "$link"
      fi
    fi
  done < <(find "$HOME/.config" "$HOME/.local/share/applications" "$HOME/.local/share/themes/hyprkarl" -type l 2>/dev/null)
}

remove_empty_dirs() {
  find "$HOME/.config" "$HOME/.local/share/applications" "$HOME/.local/share/themes/hyprkarl" \
    -mindepth 1 -depth -type d -empty -delete 2>/dev/null
}
