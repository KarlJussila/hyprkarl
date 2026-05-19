HYPRKARL_PATH="${HYPRKARL_PATH:-$HOME/.local/share/hyprkarl}"
UPDATE_STATE_DIR="$HYPRKARL_PATH/config/hyprkarl/update"

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
