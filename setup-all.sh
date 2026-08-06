#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/setup-purge-noctalia.sh" || exit 1
"$SCRIPT_DIR/setup-packages.sh" || exit 1
"$SCRIPT_DIR/setup-dotfiles.sh" || exit 1
"$SCRIPT_DIR/setup-system.sh" || exit 1

gum confirm "Restart required for changes to take effect. Restart now?" && "$SCRIPT_DIR/bin/hk-reboot"
"$SCRIPT_DIR/bin/hk-suggest-reboot"