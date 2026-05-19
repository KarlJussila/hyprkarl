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
