#!/bin/bash
# Install shipped entry points and build the selected theme.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export HYPRKARL_PATH="${HYPRKARL_PATH:-$SCRIPT_DIR}"
source "$SCRIPT_DIR/bin/lib/update.sh"

update_configure_source || exit 1
PATH="$SCRIPT_DIR/bin:$PATH" exec hk-update-apply
