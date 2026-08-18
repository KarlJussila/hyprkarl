#!/bin/bash
# Shared Quickshell instance selection for hk-shell commands.

HK_SHELL_CONFIG="$HYPRKARL_PATH/config/quickshell"

hk_shell_instances() {
  local output
  output="$(qs list -j -p "$HK_SHELL_CONFIG" 2>/dev/null)"

  if ! jq -e 'type == "array" and length > 0' >/dev/null 2>&1 <<<"$output"; then
    return 1
  fi

  printf '%s\n' "$output"
}

hk_shell_is_running() {
  hk_shell_instances >/dev/null
}

hk_shell_latest_instance_id() {
  local instances
  instances="$(hk_shell_instances)"

  if [[ -z "$instances" ]]; then
    instances="$(qs list -j --show-dead -p "$HK_SHELL_CONFIG" 2>/dev/null)"
  fi

  jq -er 'max_by(.launch_time).id' <<<"$instances" 2>/dev/null
}
