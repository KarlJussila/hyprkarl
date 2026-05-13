#!/bin/bash

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/hyprkarl"
pid_file="$runtime_dir/screenrecording.pid"
recording_pid=""

if [[ -f "$pid_file" ]]; then
  recording_pid=$(<"$pid_file")
fi

if [[ "$recording_pid" =~ ^[0-9]+$ ]] && kill -0 "$recording_pid" 2>/dev/null; then
  echo '{"text": " 󰻂 ", "tooltip": "Stop recording", "class": "active"}'
else
  echo '{"text": ""}'
fi
