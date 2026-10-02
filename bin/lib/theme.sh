# bin/lib/theme.sh
# Build and activate themes. The active theme is one symlink,
# $XDG_STATE_HOME/hyprkarl/current/theme, pointing at a build named
# <theme>.<timestamp> under themes/.

HYPRKARL_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl"
HYPRKARL_USER_THEMES="${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/themes"
HYPRKARL_THEME_BUILDS="$HYPRKARL_STATE_HOME/themes"
HYPRKARL_CURRENT_THEME="$HYPRKARL_STATE_HOME/current/theme"
HYPRKARL_CURRENT_WALLPAPER="$HYPRKARL_STATE_HOME/current/wallpaper"
HYPRKARL_GTK_THEME_HOME="$HOME/.local/share/themes/hyprkarl"

theme_normalize_name() {
  printf '%s' "$*" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

# Prints nothing before the first activation.
theme_current_name() {
  local build

  build=$(readlink "$HYPRKARL_CURRENT_THEME") || return 0
  build=${build##*/}
  printf '%s\n' "${build%.*}"
}

theme_list_names() {
  local source

  for source in "$HYPRKARL_PATH/themes"/*/theme.yaml "$HYPRKARL_USER_THEMES"/*/theme.yaml; do
    if [[ -f "$source" ]]; then
      basename "$(dirname "$source")"
    fi
  done | sort -u
}

# Build into a fresh directory, swap the current link to it, and delete older
# builds. The swap is atomic, and deleting the old build makes file watchers
# (the shell's Theme.qml) reload through the new link.
theme_activate() {
  local name="$1" source="$1" build old scheme="prefer-dark" icons="Yaru-purple"
  local -a overlay=()

  if [[ -f "$HYPRKARL_PATH/themes/$name/theme.yaml" ]]; then
    if [[ -d "$HYPRKARL_USER_THEMES/$name" ]]; then
      overlay=(--overlay "$HYPRKARL_USER_THEMES/$name")
    fi
  elif [[ -f "$HYPRKARL_USER_THEMES/$name/theme.yaml" ]]; then
    source="$HYPRKARL_USER_THEMES/$name"
  else
    printf "Theme '%s' does not exist\n" "$name" >&2
    return 1
  fi

  build="$HYPRKARL_THEME_BUILDS/$name.$(date +%s%N)"
  if ! (cd "$HYPRKARL_PATH/theme-generator" \
      && python3 -m theme_generator build "$source" "${overlay[@]}" --output "$build" >/dev/null); then
    rm -rf "$build"
    return 1
  fi

  mkdir -p "${HYPRKARL_CURRENT_THEME%/*}"
  ln -sfn "../themes/${build##*/}" "$HYPRKARL_CURRENT_THEME.next"
  mv -T "$HYPRKARL_CURRENT_THEME.next" "$HYPRKARL_CURRENT_THEME" || return 1
  for old in "$HYPRKARL_THEME_BUILDS"/*; do
    if [[ "$old" != "$build" ]]; then
      rm -rf "$old"
    fi
  done

  # GTK does not reliably follow symlinked theme directories, so copy it.
  rm -rf "$HYPRKARL_GTK_THEME_HOME"
  mkdir -p "${HYPRKARL_GTK_THEME_HOME%/*}"
  cp -a "$build/gtk-theme" "$HYPRKARL_GTK_THEME_HOME" || return 1

  if [[ -f "$build/light.mode" ]]; then
    scheme="prefer-light"
  fi
  if [[ -f "$build/icons.theme" ]]; then
    icons=$(<"$build/icons.theme")
  fi
  gsettings set org.gnome.desktop.interface gtk-theme "hyprkarl"
  gsettings set org.gnome.desktop.interface color-scheme "$scheme"
  gsettings set org.gnome.desktop.interface icon-theme "$icons"
}

# Hyprland reads the cursor variables only when it starts, so set the theme's
# cursor on a running compositor after a reload.
theme_apply_cursor() {
  hyprctl setcursor "$(<"$HYPRKARL_CURRENT_THEME/cursor.theme")" "$XCURSOR_SIZE" >/dev/null
}

# Keep the current wallpaper if the new build still has it; otherwise pick the
# theme's first wallpaper.
theme_ensure_wallpaper_selection() {
  local wallpaper

  if [[ -e "$HYPRKARL_CURRENT_WALLPAPER" ]]; then
    return 0
  fi
  wallpaper=$(find -L "$HYPRKARL_CURRENT_THEME/wallpapers" -maxdepth 1 -type f -printf '%f\n' \
    | sort | head -n 1)
  if [[ -z "$wallpaper" ]]; then
    rm -f "$HYPRKARL_CURRENT_WALLPAPER"
    return 0
  fi
  ln -nsf "theme/wallpapers/$wallpaper" "$HYPRKARL_CURRENT_WALLPAPER"
}
