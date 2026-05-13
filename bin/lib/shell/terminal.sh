hyprkarl_open_terminal() {
  xdg-terminal-exec --app-id=org.hyprkarl.terminal "$@"
}

hyprkarl_capture_terminal_output() {
  local output_file
  output_file=$(mktemp) || return 1

  if ! hyprkarl_open_terminal -e bash -lc 'output_file=$1; shift; "$@" >"$output_file"' bash "$output_file" "$@"; then
    rm -f "$output_file"
    return 1
  fi

  cat "$output_file"
  rm -f "$output_file"
}
