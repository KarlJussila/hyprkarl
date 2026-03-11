#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/setup-packages.sh"
"$SCRIPT_DIR/setup-system.sh"
"$SCRIPT_DIR/setup-dotfiles.sh"

gum confirm "Restart required for changes to take effect. Restart now?" && hyprkarl-reboot
hyprkarl-suggest-reboot