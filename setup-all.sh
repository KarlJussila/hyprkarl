#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/setup-packages.sh"
"$SCRIPT_DIR/setup-system.sh"
"$SCRIPT_DIR/setup-dotfiles.sh"

hyprkarl-suggest-reboot