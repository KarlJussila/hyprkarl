#!/bin/bash
# Shared Quickshell instance selection for hk-shell commands.

HK_SHELL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"

hk_shell_instances() {
  local instances
  instances=$(qs list -j -p "$HK_SHELL_CONFIG")

  # Quickshell 0.3.1 writes a status message to stdout instead of JSON when
  # no instances are running.
  jq -e 'arrays | select(length > 0)' <<<"$instances" 2>/dev/null
}

hk_shell_is_running() {
  hk_shell_instances >/dev/null
}
