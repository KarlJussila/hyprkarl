#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/state.sh"

baseline=$(update_read_commit system)
head=$(update_head_commit)

if [[ -n "$baseline" ]] && [[ "$baseline" == "$head" ]]; then
  printf 'System already up to date.\n'
  update_write_commit system
  exit 0
fi

printf 'Running system setup...\n'
"$HYPRKARL_PATH/setup-system.sh" || exit 1

update_write_commit system
printf 'System updated.\n'
