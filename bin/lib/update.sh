# bin/lib/update.sh
# Shared state, package-list, source-sync, and Stow helpers for hk-update.

export HYPRKARL_PATH="${HYPRKARL_PATH:-$HOME/.local/share/hyprkarl}"

UPDATE_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/update"
UPDATE_CONFIGURATION_REVISION="$UPDATE_STATE_DIR/configuration.revision"
UPDATE_PENDING_SOURCE="$UPDATE_STATE_DIR/pending-source.revision"
UPDATE_SHELL_RESTART_MARKER="$UPDATE_STATE_DIR/restart-shell-after-apply"
UPDATE_PACKAGE_STATE="$UPDATE_STATE_DIR/packages.json"
UPDATE_SYSTEM_MIGRATION_DIR="$UPDATE_STATE_DIR/system-migrations"
LEGACY_UPDATE_STATE_DIR="$HYPRKARL_PATH/config/hyprkarl/update"
UPDATE_LEGACY_SYSTEM_MIGRATIONS=(
  010-sddm-autologin
  020-logind-lid-switch
  030-password-attempts
  040-localsend-firewall
  050-docker-service
)
UPDATE_LIB_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$UPDATE_LIB_DIR/theme.sh"

# --- machine update state ---

update_head_commit() {
  git -C "$HYPRKARL_PATH" rev-parse HEAD
}

update_commit_valid() {
  git -C "$HYPRKARL_PATH" cat-file -e "$1^{commit}" 2>/dev/null
}

update_read_configuration_revision() {
  [[ -f "$UPDATE_CONFIGURATION_REVISION" ]] \
    && cat "$UPDATE_CONFIGURATION_REVISION" \
    || printf ''
}

update_write_configuration_revision() {
  local temporary

  mkdir -p "$UPDATE_STATE_DIR" || return 1
  temporary=$(mktemp "$UPDATE_STATE_DIR/.configuration.XXXXXX") || return 1
  update_head_commit > "$temporary" || { rm -f "$temporary"; return 1; }
  mv -T "$temporary" "$UPDATE_CONFIGURATION_REVISION"
}

update_read_pending_source() {
  [[ -f "$UPDATE_PENDING_SOURCE" ]] && cat "$UPDATE_PENDING_SOURCE" || printf ''
}

update_write_pending_source() {
  local revision="$1" temporary

  mkdir -p "$UPDATE_STATE_DIR" || return 1
  temporary=$(mktemp "$UPDATE_STATE_DIR/.pending-source.XXXXXX") || return 1
  printf '%s\n' "$revision" > "$temporary" || { rm -f "$temporary"; return 1; }
  mv -T "$temporary" "$UPDATE_PENDING_SOURCE"
}

update_clear_pending_source() {
  rm -f "$UPDATE_PENDING_SOURCE"
}

update_import_legacy_configuration_state() {
  local legacy="$LEGACY_UPDATE_STATE_DIR/dotfiles.commit"

  [[ -f "$UPDATE_CONFIGURATION_REVISION" ]] && return 0
  [[ -f "$legacy" ]] || return 0
  mkdir -p "$UPDATE_STATE_DIR" || return 1
  cp "$legacy" "$UPDATE_CONFIGURATION_REVISION" || return 1
  rm -f "$legacy"
}

update_import_legacy_package_state() {
  local legacy="$LEGACY_UPDATE_STATE_DIR/packages.commit" baseline

  [[ -f "$UPDATE_PACKAGE_STATE" ]] && return 0
  [[ -f "$legacy" ]] || return 0
  baseline=$(cat "$legacy")
  if update_commit_valid "$baseline"; then
    python3 "$UPDATE_LIB_DIR/update_packages.py" import-legacy \
      "$HYPRKARL_PATH" "$baseline" "$UPDATE_PACKAGE_STATE" || return 1
  else
    printf 'Legacy package update revision is unavailable; package review will start from empty state.\n' >&2
  fi
  rm -f "$legacy"
}

update_import_legacy_system_state() {
  local legacy="$LEGACY_UPDATE_STATE_DIR/system.commit" id

  [[ -f "$legacy" ]] || return 0
  mkdir -p "$UPDATE_SYSTEM_MIGRATION_DIR" || return 1
  for id in "${UPDATE_LEGACY_SYSTEM_MIGRATIONS[@]}"; do
    : > "$UPDATE_SYSTEM_MIGRATION_DIR/$id" || return 1
  done
  rm -f "$legacy"
}

update_import_legacy_state() {
  update_import_legacy_configuration_state || return 1
  update_import_legacy_package_state || return 1
  update_import_legacy_system_state || return 1
  rmdir "$LEGACY_UPDATE_STATE_DIR" 2>/dev/null || true
}

# --- canonical source ---

update_source_remote() {
  git -C "$HYPRKARL_PATH" config --local --get hyprkarl.updateRemote 2>/dev/null \
    || printf 'origin'
}

update_source_branch() {
  git -C "$HYPRKARL_PATH" config --local --get hyprkarl.updateBranch 2>/dev/null \
    || printf 'main'
}

update_configure_source() {
  if [[ -z "$(git -C "$HYPRKARL_PATH" config --local --get hyprkarl.updateRemote 2>/dev/null)" ]]; then
    git -C "$HYPRKARL_PATH" config --local hyprkarl.updateRemote origin || return 1
  fi
  if [[ -z "$(git -C "$HYPRKARL_PATH" config --local --get hyprkarl.updateBranch 2>/dev/null)" ]]; then
    git -C "$HYPRKARL_PATH" config --local hyprkarl.updateBranch main || return 1
  fi
}

# --- Stow / symlink management ---

_stow_conflicts() {
  stow -n -v "$@" 2>&1 | grep -E '^(CONFLICT:|[[:space:]]+\* )'
}

check_config_conflicts() {
  _stow_conflicts --restow --no-folding \
    --dir="$HYPRKARL_PATH" \
    --target="$HOME/.config" \
    config
  _stow_conflicts --restow --no-folding \
    --dir="$HYPRKARL_PATH" \
    --target="$HOME/.local/share/applications" \
    applications
}

stow_restow_config() {
  stow --restow --no-folding \
    --dir="$HYPRKARL_PATH" \
    --target="$HOME/.config" \
    config || return 1
  stow --restow --no-folding \
    --dir="$HYPRKARL_PATH" \
    --target="$HOME/.local/share/applications" \
    applications
}

remove_stale_symlinks() {
  local root link target resolved directory

  for root in "$HOME/.config" "$HOME/.local/share/applications" "$HOME/.local/share/themes/hyprkarl"; do
    while IFS= read -r link; do
      if [[ ! -e "$link" ]]; then
        target=$(readlink "$link")
        if [[ "$target" == /* ]]; then
          resolved=$(realpath -ms -- "$target")
        else
          resolved=$(realpath -ms -- "$(dirname "$link")/$target")
        fi
        if [[ "$resolved" == "$HYPRKARL_PATH/"* ]]; then
          directory=$(dirname "$link")
          rm "$link"
          while [[ "$directory" != "$root" ]] && rmdir "$directory" 2>/dev/null; do
            directory=$(dirname "$directory")
          done
        fi
      fi
    done < <(find "$root" -type l 2>/dev/null)
  done
}
