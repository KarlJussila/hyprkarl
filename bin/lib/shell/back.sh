hyprkarl_parse_back_args() {
  HYPRKARL_BACK_ARGS=()

  if [[ "${1:-}" == "--back" ]]; then
    shift
    HYPRKARL_BACK_ARGS=("$@")
  fi
}

hyprkarl_build_self_command() {
  local command_name
  command_name=$(basename "$1")

  HYPRKARL_SELF_COMMAND=("$command_name")
  if ((${#HYPRKARL_BACK_ARGS[@]})); then
    HYPRKARL_SELF_COMMAND+=(--back "${HYPRKARL_BACK_ARGS[@]}")
  fi
}

hyprkarl_run_back() {
  (("$#" > 0)) || return 0
  "$@"
}
