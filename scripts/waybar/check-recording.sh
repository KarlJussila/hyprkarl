#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/hyprkarl-shell.sh
source "$SCRIPT_DIR/../lib/hyprkarl-shell.sh"

pid_file="$HYPRKARL_RUNTIME_DIR/screenrecording.pid"
recording_pid=""

if [[ -f "$pid_file" ]]; then
  recording_pid=$(< "$pid_file")
fi

if [[ "$recording_pid" =~ ^[0-9]+$ ]] && kill -0 "$recording_pid" 2>/dev/null; then
  echo '{"text": " 󰻂 ", "tooltip": "Stop recording", "class": "active"}'
else
  echo '{"text": ""}'
fi
