#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/stow_helpers.sh"

remove_stale_symlinks
remove_empty_dirs
printf 'Stale symlinks and empty directories removed.\n'
