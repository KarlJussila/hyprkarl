#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/setup-packages.sh"
"$SCRIPT_DIR/setup-dotfiles.sh"
"$SCRIPT_DIR/setup-system.sh"

gum confirm "Restart required for changes to take effect. Restart now?" && hk-reboot
hk-suggest-reboot