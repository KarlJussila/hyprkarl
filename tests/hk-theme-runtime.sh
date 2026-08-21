#!/bin/bash
# Exercise source compilation and atomic runtime activation in disposable XDG paths.

ORIG=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d /tmp/hk-theme-runtime.XXXXXX)
export HOME="$TEST_ROOT/home"
export XDG_CONFIG_HOME="$TEST_ROOT/config"
export XDG_STATE_HOME="$TEST_ROOT/state"
export XDG_RUNTIME_DIR="$TEST_ROOT/runtime"
export HYPRKARL_PATH="$ORIG"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_RUNTIME_DIR"
source "$ORIG/bin/lib/theme.sh"

theme_activate_bundle hyprkarl >/dev/null \
  || fail "built-in theme did not activate"
[[ "$(theme_current_name)" == "hyprkarl" ]] \
  || fail "active theme name was not written"
[[ -f "$HYPRKARL_CURRENT_THEME/quickshell.json" ]] \
  || fail "generated Quickshell theme is missing"
[[ -f "$HYPRKARL_CURRENT_THEME/gtk-theme/gtk-3.0/gtk.css" ]] \
  || fail "generated GTK payload is missing"

mkdir -p "$HYPRKARL_USER_THEMES/hyprkarl/wallpapers"
printf 'shell:\n  metrics:\n    borderWidth: 5\n' \
  > "$HYPRKARL_USER_THEMES/hyprkarl/theme.yaml"
printf 'personal wallpaper\n' \
  > "$HYPRKARL_USER_THEMES/hyprkarl/wallpapers/personal.txt"
printf '01-hyprkarl.jpg\n' \
  > "$HYPRKARL_USER_THEMES/hyprkarl/.wallpapers-disabled"

theme_activate_bundle hyprkarl >/dev/null \
  || fail "same-name personal overlay did not activate"
jq -e '.metrics.borderWidth == 5' "$HYPRKARL_CURRENT_THEME/quickshell.json" \
  >/dev/null || fail "personal graph did not merge before rendering"
[[ -f "$HYPRKARL_CURRENT_THEME/wallpapers/personal.txt" ]] \
  || fail "personal wallpaper was not included"
[[ ! -e "$HYPRKARL_CURRENT_THEME/wallpapers/01-hyprkarl.jpg" ]] \
  || fail "disabled built-in wallpaper remained in the bundle"

selector_before=$(readlink "$HYPRKARL_CURRENT_THEME")
mkdir -p "$HYPRKARL_USER_THEMES/hyprkarl/overrides"
printf '{invalid\n' \
  > "$HYPRKARL_USER_THEMES/hyprkarl/overrides/quickshell.json"
if theme_activate_bundle hyprkarl >/dev/null 2>&1; then
  fail "invalid generated bundle was activated"
fi
[[ "$(readlink "$HYPRKARL_CURRENT_THEME")" == "$selector_before" ]] \
  || fail "failed build changed the active selector"

rm -f "$HYPRKARL_USER_THEMES/hyprkarl/overrides/quickshell.json"
theme_install_gtk_payload || fail "GTK payload was not materialized"
[[ -f "$HYPRKARL_GTK_THEME_HOME/.hyprkarl-managed" ]] \
  || fail "GTK install is not marked as managed"
[[ ! -L "$HYPRKARL_GTK_THEME_HOME" ]] \
  || fail "GTK payload was installed as a symlink"

printf 'Theme runtime integration passed.\n'
