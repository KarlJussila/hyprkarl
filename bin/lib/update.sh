# bin/lib/update.sh
# Shared state, package-list, source-sync, and Stow helpers for hk-update.

export HYPRKARL_PATH="${HYPRKARL_PATH:-$HOME/.local/share/hyprkarl}"

UPDATE_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/update"
UPDATE_CONFIGURATION_REVISION="$UPDATE_STATE_DIR/configuration.revision"
UPDATE_PENDING_SOURCE="$UPDATE_STATE_DIR/pending-source.revision"
UPDATE_PACKAGE_STATE="$UPDATE_STATE_DIR/packages.json"
UPDATE_MIGRATION_DIR="$UPDATE_STATE_DIR/migrations"
# Coding agents (the shared ~/.agents, Claude Code, Codex) load skills from
# <home>/skills.
AGENT_HOMES=("$HOME/.agents" "$HOME/.claude" "$HOME/.codex")
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
  mkdir -p "$UPDATE_STATE_DIR" || return 1
  update_head_commit > "$UPDATE_CONFIGURATION_REVISION"
}

update_read_pending_source() {
  [[ -f "$UPDATE_PENDING_SOURCE" ]] && cat "$UPDATE_PENDING_SOURCE" || printf ''
}

update_write_pending_source() {
  mkdir -p "$UPDATE_STATE_DIR" || return 1
  printf '%s\n' "$1" > "$UPDATE_PENDING_SOURCE"
}

update_clear_pending_source() {
  rm -f "$UPDATE_PENDING_SOURCE"
}

# --- migrations ---

# Migrations are numbered executables in migrations/, run once per machine.
update_pending_migrations() {
  local migration

  for migration in "$HYPRKARL_PATH/migrations"/*; do
    if [[ -f "$migration" ]] && [[ ! -e "$UPDATE_MIGRATION_DIR/${migration##*/}" ]]; then
      printf '%s\n' "$migration"
    fi
  done
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
}

stow_restow_config() {
  stow --restow --no-folding \
    --dir="$HYPRKARL_PATH" \
    --target="$HOME/.config" \
    config
}

remove_stale_symlinks() {
  local root link target resolved directory

  for root in "$HOME/.config" "$HOME/.local/share/applications" "$HOME/.local/share/themes/hyprkarl" \
      "${AGENT_HOMES[@]/%//skills}"; do
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

# Link Hyprkarl's skills into installed agents' skill folders, so an agent
# asked to change the desktop learns where changes belong. A skill of the
# user's own with the same name stays.
link_agent_skills() {
  local agent_home skill link

  for agent_home in "${AGENT_HOMES[@]}"; do
    [[ -d "$agent_home" ]] || continue
    for skill in "$HYPRKARL_PATH"/defaults/skills/*/; do
      skill=${skill%/}
      link="$agent_home/skills/${skill##*/}"
      if [[ -e "$link" ]] && [[ ! -L "$link" ]]; then
        continue
      fi
      mkdir -p "$agent_home/skills" && ln -sfn "$skill" "$link" || return 1
    done
  done
}
