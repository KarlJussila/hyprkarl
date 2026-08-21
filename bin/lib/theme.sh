# bin/lib/theme.sh
# Shared ownership of generated theme sources and active runtime state.

HYPRKARL_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl"
HYPRKARL_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl"
HYPRKARL_USER_THEMES="$HYPRKARL_CONFIG_HOME/themes"
HYPRKARL_THEME_STATE="$HYPRKARL_STATE_HOME/current"
HYPRKARL_THEME_ARTIFACTS="$HYPRKARL_STATE_HOME/themes"
HYPRKARL_CURRENT_THEME="$HYPRKARL_THEME_STATE/theme"
HYPRKARL_CURRENT_THEME_NAME="$HYPRKARL_THEME_STATE/theme.name"
HYPRKARL_CURRENT_THEME_SELECTOR="$HYPRKARL_THEME_STATE/theme.json"
HYPRKARL_CURRENT_WALLPAPER="$HYPRKARL_THEME_STATE/wallpaper"
HYPRKARL_THEME_LOCK="${XDG_RUNTIME_DIR:-/tmp}/hyprkarl-theme-set.lock"
HYPRKARL_GTK_THEME_HOME="$HOME/.local/share/themes/hyprkarl"
HYPRKARL_THEME_BACKUPS="$HYPRKARL_CONFIG_HOME/theme-backups"

theme_normalize_name() {
  printf '%s' "$*" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

theme_current_name() {
  if [[ -f "$HYPRKARL_CURRENT_THEME_NAME" ]]; then
    cat "$HYPRKARL_CURRENT_THEME_NAME"
  fi
}

theme_is_legacy_bundle() {
  local source="$1"

  [[ -f "$source/quickshell.json" ]] \
    && [[ -f "$source/hyprland.lua" ]] \
    && [[ -d "$source/gtk-theme" ]]
}

theme_is_source() {
  local source="$1"

  [[ -f "$source/theme.yaml" ]] && ! theme_is_legacy_bundle "$source"
}

theme_has_overlay_content() {
  local source="$1"

  [[ -d "$source" ]] && [[ -n "$(find "$source" -mindepth 1 -print -quit)" ]]
}

theme_list_names() {
  local source

  for source in "$HYPRKARL_PATH/themes"/* "$HYPRKARL_USER_THEMES"/*; do
    if ! theme_is_source "$source"; then
      continue
    fi
    basename "$source"
  done | sort -u
}

theme_migrate_legacy_bundles() {
  local source name backup

  for source in "$HYPRKARL_USER_THEMES"/*; do
    if [[ ! -d "$source" ]] || ! theme_is_legacy_bundle "$source"; then
      continue
    fi

    name=$(basename "$source")
    mkdir -p "$HYPRKARL_THEME_BACKUPS" || return 1
    backup="$HYPRKARL_THEME_BACKUPS/${name}.$(date +%Y%m%d%H%M%S).legacy"
    if ! mv "$source" "$backup"; then
      return 1
    fi
    printf 'Moved legacy generated theme bundle from %s to %s\n' "$source" "$backup"
    printf 'It was not treated as a source. Recreate it at %s/theme.yaml before selecting it.\n' \
      "$HYPRKARL_USER_THEMES/$name"
  done
}

_theme_link_destination() {
  local link="$1" target
  target=$(readlink "$link")
  if [[ "$target" == /* ]]; then
    realpath -m -- "$target"
  else
    realpath -m -- "$(dirname "$link")/$target"
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

theme_gtk_install_is_replaceable() {
  local target="$HYPRKARL_GTK_THEME_HOME"
  local link resolved unexpected

  if [[ ! -e "$target" ]] && [[ ! -L "$target" ]]; then
    return 0
  fi
  if [[ -L "$target" ]]; then
    return 1
  fi
  if [[ -d "$target" ]] && [[ -f "$target/.hyprkarl-managed" ]]; then
    return 0
  fi
  if [[ -d "$target" ]] && [[ -z "$(find "$target" -mindepth 1 -print -quit)" ]]; then
    return 0
  fi

  if [[ ! -d "$target" ]]; then
    return 1
  fi

  unexpected=$(find "$target" -mindepth 1 ! -type d ! -type l -print -quit)
  if [[ -n "$unexpected" ]]; then
    return 1
  fi
  while IFS= read -r link; do
    resolved=$(_theme_link_destination "$link")
    if [[ "$resolved" != "$HYPRKARL_PATH/"* && "$resolved" != "$HYPRKARL_STATE_HOME/"* ]]; then
      return 1
    fi
  done < <(find "$target" -type l)
  return 0
}

THEME_GTK_TRANSACTION=0
THEME_GTK_PREVIOUS=""

theme_install_gtk_payload_from() {
  local artifact="$1" force_replace="${2:-0}" keep_previous="${3:-0}"
  local source="$artifact/gtk-theme"
  local parent staging backup=""

  if [[ ! -d "$source" ]]; then
    printf 'Theme has no GTK payload: %s\n' "$source" >&2
    return 1
  fi
  if [[ "$force_replace" -ne 1 ]] && ! theme_gtk_install_is_replaceable; then
    printf 'GTK theme destination is not managed by Hyprkarl: %s\n' "$HYPRKARL_GTK_THEME_HOME" >&2
    return 1
  fi

  parent=$(dirname "$HYPRKARL_GTK_THEME_HOME")
  mkdir -p "$parent"
  staging=$(mktemp -d "$parent/.hyprkarl.next.XXXXXX") || return 1
  if ! cp -a "$source/." "$staging/"; then
    rm -rf "$staging"
    return 1
  fi
  printf 'Managed by Hyprkarl. Changes are replaced on theme switch.\n' \
    > "$staging/.hyprkarl-managed"

  if [[ -e "$HYPRKARL_GTK_THEME_HOME" ]] || [[ -L "$HYPRKARL_GTK_THEME_HOME" ]]; then
    backup=$(mktemp -d "$parent/.hyprkarl.previous.XXXXXX") || {
      rm -rf "$staging"
      return 1
    }
    rmdir "$backup"
    if ! mv "$HYPRKARL_GTK_THEME_HOME" "$backup"; then
      rm -rf "$staging"
      return 1
    fi
  fi
  if ! mv "$staging" "$HYPRKARL_GTK_THEME_HOME"; then
    if [[ -n "$backup" ]]; then
      mv "$backup" "$HYPRKARL_GTK_THEME_HOME"
    fi
    rm -rf "$staging"
    return 1
  fi
  if [[ "$keep_previous" -eq 1 ]]; then
    THEME_GTK_TRANSACTION=1
    THEME_GTK_PREVIOUS="$backup"
  elif [[ -n "$backup" ]]; then
    rm -rf "$backup"
  fi
}

theme_install_gtk_payload() {
  local force_replace="${1:-0}"

  theme_ensure_active || return 1
  theme_install_gtk_payload_from "$HYPRKARL_CURRENT_THEME" "$force_replace"
}

theme_commit_gtk_payload() {
  if [[ "$THEME_GTK_TRANSACTION" -eq 1 ]] && [[ -n "$THEME_GTK_PREVIOUS" ]]; then
    rm -rf "$THEME_GTK_PREVIOUS"
  fi
  THEME_GTK_TRANSACTION=0
  THEME_GTK_PREVIOUS=""
}

theme_rollback_gtk_payload() {
  if [[ "$THEME_GTK_TRANSACTION" -ne 1 ]]; then
    return 0
  fi

  rm -rf "$HYPRKARL_GTK_THEME_HOME"
  if [[ -n "$THEME_GTK_PREVIOUS" ]]; then
    mv "$THEME_GTK_PREVIOUS" "$HYPRKARL_GTK_THEME_HOME"
  fi
  THEME_GTK_TRANSACTION=0
  THEME_GTK_PREVIOUS=""
}

theme_read_desktop_settings() {
  THEME_PREVIOUS_GTK_SETTING=$(gsettings get org.gnome.desktop.interface gtk-theme) \
    || return 1
  THEME_PREVIOUS_COLOR_SETTING=$(gsettings get org.gnome.desktop.interface color-scheme) \
    || return 1
  THEME_PREVIOUS_ICON_SETTING=$(gsettings get org.gnome.desktop.interface icon-theme) \
    || return 1
}

theme_restore_desktop_settings() {
  gsettings set org.gnome.desktop.interface gtk-theme "$THEME_PREVIOUS_GTK_SETTING"
  gsettings set org.gnome.desktop.interface color-scheme "$THEME_PREVIOUS_COLOR_SETTING"
  gsettings set org.gnome.desktop.interface icon-theme "$THEME_PREVIOUS_ICON_SETTING"
}

theme_apply_desktop_settings() {
  local artifact="$1" icon_theme="Yaru-purple"

  if [[ -f "$artifact/icons.theme" ]]; then
    icon_theme=$(<"$artifact/icons.theme")
  fi

  gsettings set org.gnome.desktop.interface gtk-theme "hyprkarl" || return 1
  if [[ -f "$artifact/light.mode" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme "prefer-light" || return 1
  else
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" || return 1
  fi
  gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
}

theme_apply_bundle() {
  local name="$1" force_replace="${2:-0}" lock_fd
  local status=0
  local artifact previous_artifact

  exec {lock_fd}> "$HYPRKARL_THEME_LOCK" || return 1
  if ! flock "$lock_fd"; then
    exec {lock_fd}>&-
    return 1
  fi

  if [[ "$force_replace" -ne 1 ]] && ! theme_gtk_install_is_replaceable; then
    printf 'GTK theme destination is not managed by Hyprkarl: %s\n' "$HYPRKARL_GTK_THEME_HOME" >&2
    status=1
  elif ! theme_build_bundle "$name"; then
    status=1
  else
    artifact="$THEME_BUILT_ARTIFACT"
    previous_artifact=$(readlink -f "$HYPRKARL_CURRENT_THEME" 2>/dev/null)
  fi

  if [[ "$status" -eq 0 ]] && ! theme_read_desktop_settings; then
    status=1
  elif [[ "$status" -eq 0 ]] && ! theme_apply_desktop_settings "$artifact"; then
    theme_restore_desktop_settings >/dev/null 2>&1
    status=1
  elif [[ "$status" -eq 0 ]] \
      && ! theme_install_gtk_payload_from "$artifact" "$force_replace" 1; then
    theme_restore_desktop_settings >/dev/null 2>&1
    status=1
  elif [[ "$status" -eq 0 ]] \
      && ! theme_select_bundle "$name" "$THEME_BUILT_ARTIFACT_NAME"; then
    theme_rollback_gtk_payload
    theme_restore_desktop_settings >/dev/null 2>&1
    status=1
  fi

  if [[ "$status" -eq 0 ]]; then
    theme_commit_gtk_payload
    theme_prune_artifacts "$artifact" "$previous_artifact"
  elif [[ -n "$artifact" ]]; then
    rm -rf "$artifact"
  fi

  flock -u "$lock_fd"
  exec {lock_fd}>&-
  return "$status"
}

theme_apply_current() {
  local name

  name=$(theme_current_name)
  theme_apply_bundle "${name:-hyprkarl}" "$@"
}

theme_ensure_wallpaper_selection() {
  local wallpaper

  if [[ -L "$HYPRKARL_CURRENT_WALLPAPER" ]] && [[ -e "$HYPRKARL_CURRENT_WALLPAPER" ]]; then
    return 0
  fi
  wallpaper=$(find -L "$HYPRKARL_CURRENT_THEME/wallpapers" -maxdepth 1 -type f -print0 \
    | sort -z | head -z -n 1 | tr -d '\0')
  if [[ -z "$wallpaper" ]]; then
    rm -f "$HYPRKARL_CURRENT_WALLPAPER"
    return 0
  fi
  ln -nsf "theme/wallpapers/$(basename "$wallpaper")" "$HYPRKARL_CURRENT_WALLPAPER"
}

THEME_BUILT_ARTIFACT=""
THEME_BUILT_ARTIFACT_NAME=""

theme_build_bundle() {
  local name="$1"
  local built_in="$HYPRKARL_PATH/themes/$name"
  local user="$HYPRKARL_USER_THEMES/$name"
  local build_source staging artifact artifact_name
  local -a build_command

  THEME_BUILT_ARTIFACT=""
  THEME_BUILT_ARTIFACT_NAME=""

  if [[ ! "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    printf "Invalid theme name: %s\n" "$name" >&2
    return 1
  fi
  if theme_is_legacy_bundle "$user"; then
    printf 'Personal theme %s is a legacy generated bundle. Run hk-user-migrate to back it up before selecting this theme.\n' \
      "$user" >&2
    return 1
  fi
  if ! theme_is_source "$built_in" && ! theme_is_source "$user"; then
    printf "Theme '%s' does not exist\n" "$name" >&2
    return 1
  fi
  if [[ ! -d "$HYPRKARL_PATH/theme-generator/theme_generator" ]]; then
    printf 'Theme compiler not found: %s/theme-generator\n' "$HYPRKARL_PATH" >&2
    return 1
  fi

  mkdir -p "$HYPRKARL_THEME_STATE" "$HYPRKARL_THEME_ARTIFACTS"
  staging=$(mktemp -d "$HYPRKARL_THEME_ARTIFACTS/.next.XXXXXX") || return 1

  if theme_is_source "$built_in"; then
    build_source="$name"
  else
    build_source="$user"
  fi
  build_command=(python3 -m theme_generator build "$build_source" --output "$staging")
  if theme_is_source "$built_in" && theme_has_overlay_content "$user"; then
    build_command+=(--overlay "$user")
  fi
  if ! (
    cd "$HYPRKARL_PATH/theme-generator" || exit 1
    "${build_command[@]}" >/dev/null
  ); then
    rm -rf "$staging"
    return 1
  fi

  artifact_name="$name.$(date +%s%N).$$"
  artifact="$HYPRKARL_THEME_ARTIFACTS/$artifact_name"
  mv "$staging" "$artifact" || { rm -rf "$staging"; return 1; }

  THEME_BUILT_ARTIFACT="$artifact"
  THEME_BUILT_ARTIFACT_NAME="$artifact_name"
}

theme_restore_selection() {
  local old_link="$1" old_name="$2" old_selector="$3"
  local had_name="$4" had_selector="$5"

  if [[ -n "$old_link" ]]; then
    ln -nsf "$old_link" "$HYPRKARL_THEME_STATE/.theme.restore.$$"
    mv -Tf "$HYPRKARL_THEME_STATE/.theme.restore.$$" "$HYPRKARL_CURRENT_THEME"
  else
    rm -f "$HYPRKARL_CURRENT_THEME"
  fi
  if [[ "$had_name" -eq 1 ]]; then
    printf '%s\n' "$old_name" > "$HYPRKARL_THEME_STATE/.theme.name.restore.$$"
    mv -f "$HYPRKARL_THEME_STATE/.theme.name.restore.$$" "$HYPRKARL_CURRENT_THEME_NAME"
  else
    rm -f "$HYPRKARL_CURRENT_THEME_NAME"
  fi
  if [[ "$had_selector" -eq 1 ]]; then
    printf '%s\n' "$old_selector" > "$HYPRKARL_THEME_STATE/.theme.json.restore.$$"
    mv -f "$HYPRKARL_THEME_STATE/.theme.json.restore.$$" "$HYPRKARL_CURRENT_THEME_SELECTOR"
  else
    rm -f "$HYPRKARL_CURRENT_THEME_SELECTOR"
  fi
}

theme_select_bundle() {
  local name="$1" artifact_name="$2"
  local temporary_link old_link old_name old_selector
  local had_name=0 had_selector=0

  old_link=$(readlink "$HYPRKARL_CURRENT_THEME" 2>/dev/null)
  if [[ -f "$HYPRKARL_CURRENT_THEME_NAME" ]]; then
    old_name=$(<"$HYPRKARL_CURRENT_THEME_NAME")
    had_name=1
  fi
  if [[ -f "$HYPRKARL_CURRENT_THEME_SELECTOR" ]]; then
    old_selector=$(<"$HYPRKARL_CURRENT_THEME_SELECTOR")
    had_selector=1
  fi

  temporary_link="$HYPRKARL_THEME_STATE/.theme.$$"
  ln -s "../themes/$artifact_name" "$temporary_link" || return 1
  printf '%s\n' "$name" > "$HYPRKARL_THEME_STATE/.theme.name.$$" || return 1
  printf '{"name":"%s","artifact":"%s"}\n' "$name" "$artifact_name" \
    > "$HYPRKARL_THEME_STATE/.theme.json.$$" || return 1

  if ! mv -Tf "$temporary_link" "$HYPRKARL_CURRENT_THEME" \
      || ! mv -f "$HYPRKARL_THEME_STATE/.theme.name.$$" "$HYPRKARL_CURRENT_THEME_NAME" \
      || ! mv -f "$HYPRKARL_THEME_STATE/.theme.json.$$" "$HYPRKARL_CURRENT_THEME_SELECTOR"; then
    theme_restore_selection "$old_link" "$old_name" "$old_selector" \
      "$had_name" "$had_selector"
    return 1
  fi
}

theme_prune_artifacts() {
  local artifact="$1" previous_artifact="$2" old_artifact

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

theme_activate_bundle() {
  local name="$1" artifact previous_artifact

  theme_build_bundle "$name" || return 1
  artifact="$THEME_BUILT_ARTIFACT"
  previous_artifact=$(readlink -f "$HYPRKARL_CURRENT_THEME" 2>/dev/null)
  if ! theme_select_bundle "$name" "$THEME_BUILT_ARTIFACT_NAME"; then
    rm -rf "$artifact"
    return 1
  fi
  theme_prune_artifacts "$artifact" "$previous_artifact"
}
