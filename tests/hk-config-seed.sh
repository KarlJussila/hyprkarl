#!/bin/bash
# Exercise starting-config seeding in a disposable home.

ORIG=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d /tmp/hk-config-seed.XXXXXX)
CONFIG_HOME="$TEST_ROOT/config"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

seed() {
  XDG_CONFIG_HOME="$CONFIG_HOME" HYPRKARL_PATH="$ORIG" "$ORIG/bin/hk-config-seed" >/dev/null
}

# An existing nvim setup and an unrelated btop file are already present.
mkdir -p "$CONFIG_HOME/nvim" "$CONFIG_HOME/btop"
printf 'my own init\n' > "$CONFIG_HOME/nvim/init.lua"
printf 'log\n' > "$CONFIG_HOME/btop/btop.log"

seed || fail "seeding returned nonzero"

[[ -f "$CONFIG_HOME/yazi/yazi.toml" ]] || fail "missing application was not seeded"
[[ "$(cat "$CONFIG_HOME/nvim/init.lua")" == "my own init" ]] \
  || fail "existing nvim config was overwritten"
[[ ! -e "$CONFIG_HOME/nvim/lua/config/lazy.lua" ]] \
  || fail "seed files were mixed into an existing nvim config"
[[ -f "$CONFIG_HOME/btop/btop.conf" ]] \
  || fail "an unrelated btop file blocked the btop seed"
[[ -L "$CONFIG_HOME/btop/themes/current.theme" ]] \
  || fail "seed symlink was not preserved"
grep -q "$CONFIG_HOME" "$CONFIG_HOME/fastfetch/config.jsonc" \
  || fail "@CONFIG_HOME@ was not substituted"
[[ -f "$CONFIG_HOME/uwsm/env.local" ]] && [[ -f "$CONFIG_HOME/kitty/local.conf" ]] \
  && [[ -f "$CONFIG_HOME/hypr/hypridle.local.conf" ]] \
  || fail "included personal files were not created"

printf 'edited\n' > "$CONFIG_HOME/yazi/yazi.toml"
printf 'edited\n' > "$CONFIG_HOME/kitty/local.conf"
seed || fail "second run returned nonzero"
[[ "$(cat "$CONFIG_HOME/yazi/yazi.toml")" == "edited" ]] \
  || fail "a second run overwrote a seeded file"
[[ "$(cat "$CONFIG_HOME/kitty/local.conf")" == "edited" ]] \
  || fail "a second run overwrote an included personal file"

printf 'Starting-config seeding passed.\n'
