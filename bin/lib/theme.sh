# bin/lib/theme.sh
# Shared ownership of generated theme sources and active runtime state.

HYPRKARL_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl"
HYPRKARL_THEME_STATE="$HYPRKARL_STATE_HOME/current"
HYPRKARL_THEME_ARTIFACTS="$HYPRKARL_STATE_HOME/themes"
HYPRKARL_CURRENT_THEME="$HYPRKARL_THEME_STATE/theme"
HYPRKARL_CURRENT_THEME_NAME="$HYPRKARL_THEME_STATE/theme.name"
HYPRKARL_CURRENT_THEME_SELECTOR="$HYPRKARL_THEME_STATE/theme.json"
HYPRKARL_CURRENT_WALLPAPER="$HYPRKARL_THEME_STATE/wallpaper"
HYPRKARL_THEME_LOCK="${XDG_RUNTIME_DIR:-/tmp}/hyprkarl-theme-set.lock"

theme_normalize_name() {
  printf '%s' "$*" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

theme_current_name() {
  if [[ -f "$HYPRKARL_CURRENT_THEME_NAME" ]]; then
    cat "$HYPRKARL_CURRENT_THEME_NAME"
  fi
}

theme_ensure_active() {
  local legacy_name_path="$HYPRKARL_PATH/config/hyprkarl/current/theme.name"
  local initial_name="hyprkarl"

  if [[ -d "$HYPRKARL_CURRENT_THEME" ]] && [[ -f "$HYPRKARL_CURRENT_THEME_SELECTOR" ]]; then
    return 0
  fi
  if [[ -f "$legacy_name_path" ]]; then
    initial_name=$(cat "$legacy_name_path")
  fi
  theme_activate_bundle "$initial_name"
}

theme_stow_source() {
  if [[ -d "$HYPRKARL_CURRENT_THEME" ]]; then
    printf '%s' "$HYPRKARL_CURRENT_THEME"
  else
    printf '%s' "$HYPRKARL_PATH/themes/hyprkarl"
  fi
}

theme_validate_bundle() {
  local root="$1" required
  local required_files=(
    quickshell.json
    rofi.rasi
    hyprland.lua
    hyprlock.conf
    hyprtoolkit.conf
    mako.ini
    btop.theme
    alacritty.toml
    foot.ini
    ghostty.conf
    kitty.conf
    wifitui.toml
    yazi.toml
    gtk-3.0/settings.ini
    gtk-3.0/gtk.css
    gtk-3.0/gtk-dark.css
    gtk-4.0/settings.ini
    gtk-4.0/gtk.css
    gtk-4.0/gtk-dark.css
    gtk-theme/index.theme
    gtk-theme/gtk-3.0/gtk.css
    gtk-theme/gtk-4.0/gtk.css
    nvim/colorscheme.lua
    nvim/custom-colors.lua
    qt5ct/qt5ct.conf
    qt5ct/style-colors.conf
    qt6ct/qt6ct.conf
    qt6ct/style-colors.conf
  )

  for required in "${required_files[@]}"; do
    if [[ ! -f "$root/$required" ]]; then
      printf 'Theme bundle is missing %s\n' "$required" >&2
      return 1
    fi
  done

  if [[ ! -d "$root/wallpapers" ]]; then
    printf 'Theme bundle is missing wallpapers/\n' >&2
    return 1
  fi

  if ! jq empty "$root/quickshell.json" 2>/dev/null; then
    printf 'Theme bundle has invalid quickshell.json\n' >&2
    return 1
  fi
}

theme_activate_bundle() {
  local name="$1"
  local built_in="$HYPRKARL_PATH/themes/$name"
  local user="$HYPRKARL_PATH/user/themes/$name"
  local staging artifact artifact_name previous_artifact temporary_link
  local disabled_wallpaper old_artifact

  if [[ ! "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    printf "Invalid theme name: %s\n" "$name" >&2
    return 1
  fi
  if [[ ! -d "$built_in" ]] && [[ ! -d "$user" ]]; then
    printf "Theme '%s' does not exist\n" "$name" >&2
    return 1
  fi

  mkdir -p "$HYPRKARL_THEME_STATE" "$HYPRKARL_THEME_ARTIFACTS"
  staging=$(mktemp -d "$HYPRKARL_THEME_ARTIFACTS/.next.XXXXXX") || return 1

  if [[ -d "$built_in" ]]; then
    cp -a "$built_in/." "$staging/" || { rm -rf "$staging"; return 1; }
  fi
  if [[ -d "$user" ]]; then
    cp -a "$user/." "$staging/" || { rm -rf "$staging"; return 1; }
  fi
  if [[ -f "$user/.wallpapers-disabled" ]]; then
    while IFS= read -r disabled_wallpaper; do
      if [[ -n "$disabled_wallpaper" ]] && [[ "$disabled_wallpaper" == "$(basename "$disabled_wallpaper")" ]]; then
        rm -f "$staging/wallpapers/$disabled_wallpaper"
      fi
    done < "$user/.wallpapers-disabled"
    rm -f "$staging/.wallpapers-disabled"
  fi
  if ! theme_validate_bundle "$staging"; then
    rm -rf "$staging"
    return 1
  fi

  artifact_name="$name.$(date +%s%N).$$"
  artifact="$HYPRKARL_THEME_ARTIFACTS/$artifact_name"
  mv "$staging" "$artifact" || { rm -rf "$staging"; return 1; }

  previous_artifact=$(readlink -f "$HYPRKARL_CURRENT_THEME" 2>/dev/null)
  temporary_link="$HYPRKARL_THEME_STATE/.theme.$$"
  ln -s "../themes/$artifact_name" "$temporary_link" || return 1
  mv -Tf "$temporary_link" "$HYPRKARL_CURRENT_THEME" || return 1

  printf '%s\n' "$name" > "$HYPRKARL_THEME_STATE/.theme.name.$$" || return 1
  mv -f "$HYPRKARL_THEME_STATE/.theme.name.$$" "$HYPRKARL_CURRENT_THEME_NAME" || return 1
  printf '{"name":"%s","artifact":"%s"}\n' "$name" "$artifact_name" \
    > "$HYPRKARL_THEME_STATE/.theme.json.$$" || return 1
  mv -f "$HYPRKARL_THEME_STATE/.theme.json.$$" "$HYPRKARL_CURRENT_THEME_SELECTOR" || return 1

  for old_artifact in "$HYPRKARL_THEME_ARTIFACTS"/*; do
    [[ -d "$old_artifact" ]] || continue
    if [[ "$old_artifact" == "$artifact" ]]; then
      continue
    fi
    if [[ -n "$previous_artifact" ]] && [[ "$old_artifact" == "$previous_artifact" ]]; then
      continue
    fi
    rm -rf "$old_artifact"
  done
}
