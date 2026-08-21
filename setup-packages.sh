#!/bin/bash
# Bootstrap the update command, then use its one package workflow.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export HYPRKARL_PATH="${HYPRKARL_PATH:-$SCRIPT_DIR}"

sudo pacman -S --needed --noconfirm gum jq python || exit 1
PATH="$SCRIPT_DIR/bin:$PATH" exec hk-update-packages
