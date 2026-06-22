# bin/lib/update.sh
# Shared helpers for the hk-update-* action commands. Source from each script:
#   SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
#   source "$SCRIPT_DIR/lib/update.sh"
#
# Commit/baseline state:
#   update_read_commit TYPE              Read recorded baseline commit (dotfiles|packages|system)
#   update_write_commit TYPE             Write current HEAD as baseline for TYPE
#   update_head_commit                   Print current HEAD commit hash
#   update_commit_valid COMMIT           Return 0 if COMMIT exists in repo history
#
# Package list diffing:
#   pkg_diff FILE BASELINE_COMMIT        Compare package file against baseline; sets $added/$removed
#   pkg_comment PKG FILE                 Print the inline comment for PKG in FILE, if any
#
# Stow / symlink management:
#   check_config_conflicts               Detect stow conflicts before an update
#   stow_adopt_config                    Adopt conflicting files into the repo (--adopt)
#   stow_restow_config                   Re-stow config without conflicts
#   remove_stale_symlinks                Remove broken symlinks pointing into hyprkarl
#   remove_empty_dirs                    Remove empty directories left behind after stow

HYPRKARL_PATH="${HYPRKARL_PATH:-$HOME/.local/share/hyprkarl}"
UPDATE_STATE_DIR="$HYPRKARL_PATH/config/hyprkarl/update"

# --- baseline commit state ---

update_read_commit() {
  local file="$UPDATE_STATE_DIR/$1.commit"
  [[ -f "$file" ]] && cat "$file" || printf ''
}

update_write_commit() {
  mkdir -p "$UPDATE_STATE_DIR"
  git -C "$HYPRKARL_PATH" rev-parse HEAD > "$UPDATE_STATE_DIR/$1.commit"
}

update_head_commit() {
  git -C "$HYPRKARL_PATH" rev-parse HEAD
}

update_commit_valid() {
  git -C "$HYPRKARL_PATH" cat-file -e "$1^{commit}" 2>/dev/null
}

# --- package list diff helpers ---

pkg_diff() {
  local file="$1" baseline_commit="$2" old new
  if [[ -n "$baseline_commit" ]]; then
    old=$(git -C "$HYPRKARL_PATH" show "$baseline_commit:$file" 2>/dev/null \
      | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' \
      | sed 's/[[:space:]]*#.*//' | sort)
  fi
  new=$(grep -v '^[[:space:]]*#' "$HYPRKARL_PATH/$file" 2>/dev/null \
    | grep -v '^[[:space:]]*$' | sed 's/[[:space:]]*#.*//' | sort)
  added=$(comm -13 <(printf '%s' "$old") <(printf '%s' "$new") | grep .)
  removed=$(comm -23 <(printf '%s' "$old") <(printf '%s' "$new") | grep .)
}

pkg_comment() {
  local pkg="$1" file="$2" line
  line=$(grep -m1 "^[[:space:]]*${pkg}[[:space:]]*#" "$file" 2>/dev/null)
  if [[ -n "$line" ]]; then
    IFS='#' read -r _ comment <<< "$line"
    printf '%s' "${comment## }"
  fi
}

# --- stow / symlink helpers ---

_stow_conflicts() {
  # stow <2.4 prefixes conflicts with "CONFLICT:"; 2.4+ lists them as
  # "  * cannot stow ... over existing target ..." bullets under a WARNING.
  stow -n -v "$@" 2>&1 | grep -E '^(CONFLICT:|[[:space:]]+\* )'
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
  _stow_conflicts --restow --no-folding \
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
  stow -D --no-folding \
    --dir="$HYPRKARL_PATH" --target="$HOME/.config" config
  stow --adopt --no-folding \
    --dir="$HYPRKARL_PATH" --target="$HOME/.config" config
  stow --adopt --no-folding \
    --dir="$HYPRKARL_PATH" --target="$HOME/.local/share/applications" applications
  _stow_gtk_theme 1
}

stow_restow_config() {
  stow --restow --no-folding \
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
