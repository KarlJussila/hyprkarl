#!/bin/bash
# Apply any system migrations not yet recorded for this machine.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export HYPRKARL_PATH="${HYPRKARL_PATH:-$SCRIPT_DIR}"
PATH="$SCRIPT_DIR/bin:$PATH" exec hk-update-system
