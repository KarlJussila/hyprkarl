#!/bin/bash
# Exercise the personal-config migration in a disposable home and checkout.

ORIG=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d /tmp/hk-user-migrate.XXXXXX)
FAKE_REPO="$TEST_ROOT/repo"
FAKE_HOME="$TEST_ROOT/home"
CONFIG_HOME="$FAKE_HOME/.config"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

mkdir -p \
  "$FAKE_REPO/user/hypr" \
  "$FAKE_REPO/user/hooks/theme-set.d" \
  "$FAKE_REPO/user/quickshell/modules" \
  "$FAKE_REPO/user/themes/test/wallpapers" \
  "$FAKE_REPO/user/themes/legacy/gtk-theme" \
  "$FAKE_REPO/bin/lib" \
  "$FAKE_REPO/config/uwsm" \
  "$FAKE_REPO/templates/setup" \
  "$CONFIG_HOME/uwsm" \
  "$CONFIG_HOME/hyprkarl/current"

printf 'return true\n' > "$FAKE_REPO/user/hypr/input.lua"
printf '{"version":1}\n' > "$FAKE_REPO/user/shell.json"
printf '#!/bin/bash\nexit 0\n' \
  > "$FAKE_REPO/user/hooks/theme-set.d/10-test"
chmod +x "$FAKE_REPO/user/hooks/theme-set.d/10-test"
printf 'import QtQuick\nItem {}\n' \
  > "$FAKE_REPO/user/quickshell/modules/Test.qml"
printf 'theme source\n' > "$FAKE_REPO/user/themes/test/theme.yaml"
printf 'generated bundle\n' > "$FAKE_REPO/user/themes/legacy/quickshell.json"
printf 'generated config\n' > "$FAKE_REPO/user/themes/legacy/hyprland.lua"
printf 'resolved graph\n' > "$FAKE_REPO/user/themes/legacy/theme.yaml"
printf 'terminal and editor\n' > "$FAKE_REPO/config/uwsm/default"
printf 'secret value\n' > "$FAKE_REPO/config/uwsm/env.local"
printf 'kitty.desktop\n' > "$FAKE_REPO/config/xdg-terminals.list"
printf 'env template\n' > "$FAKE_REPO/templates/setup/env.local.example"
printf 'keep me\n' > "$CONFIG_HOME/hyprkarl/current/marker"
cp "$ORIG/bin/lib/theme.sh" "$FAKE_REPO/bin/lib/theme.sh"

ln -s "$FAKE_REPO/config/uwsm/default" "$CONFIG_HOME/uwsm/default"
ln -s "$FAKE_REPO/config/uwsm/env.local" "$CONFIG_HOME/uwsm/env.local"
ln -s "$FAKE_REPO/config/xdg-terminals.list" "$CONFIG_HOME/xdg-terminals.list"

HOME="$FAKE_HOME" XDG_CONFIG_HOME="$CONFIG_HOME" HYPRKARL_PATH="$FAKE_REPO" \
  "$ORIG/bin/hk-user-migrate" >/dev/null || fail "migration returned nonzero"

[[ -f "$CONFIG_HOME/hyprkarl/hypr/input.lua" ]] \
  || fail "Hyprland config was not moved"
[[ -f "$CONFIG_HOME/hyprkarl/hooks/theme-set.d/10-test" ]] \
  || fail "hook was not moved"
[[ -f "$CONFIG_HOME/hyprkarl/quickshell/modules/Test.qml" ]] \
  || fail "QML module was not moved"
[[ -f "$CONFIG_HOME/hyprkarl/themes/test/theme.yaml" ]] \
  || fail "theme was not moved"
[[ ! -e "$CONFIG_HOME/hyprkarl/themes/legacy" ]] \
  || fail "legacy generated bundle was treated as a source"
find "$CONFIG_HOME/hyprkarl/theme-backups" -maxdepth 1 -type d \
  -name 'legacy.*.legacy' -print -quit | grep -q . \
  || fail "legacy generated bundle was not backed up"
[[ -f "$CONFIG_HOME/hyprkarl/current/marker" ]] \
  || fail "existing config-root state was changed"

for path in \
  "$CONFIG_HOME/uwsm/default" \
  "$CONFIG_HOME/uwsm/env.local" \
  "$CONFIG_HOME/xdg-terminals.list"; do
  [[ -f "$path" ]] || fail "$path is missing"
  [[ ! -L "$path" ]] || fail "$path is still a symlink"
done

[[ ! -e "$FAKE_REPO/config/uwsm/env.local" ]] \
  || fail "old env.local was not removed"

HOME="$FAKE_HOME" XDG_CONFIG_HOME="$CONFIG_HOME" HYPRKARL_PATH="$FAKE_REPO" \
  "$ORIG/bin/hk-user-migrate" >/dev/null || fail "second migration was not idempotent"

mkdir -p "$FAKE_REPO/user"
printf 'old menu\n' > "$FAKE_REPO/user/menu.json"
printf 'new menu\n' > "$CONFIG_HOME/hyprkarl/menu.json"
if HOME="$FAKE_HOME" XDG_CONFIG_HOME="$CONFIG_HOME" HYPRKARL_PATH="$FAKE_REPO" \
    "$ORIG/bin/hk-user-migrate" >/dev/null 2>&1; then
  fail "conflicting personal files were accepted"
fi
[[ "$(cat "$FAKE_REPO/user/menu.json")" == "old menu" ]] \
  || fail "old conflicting file changed"
[[ "$(cat "$CONFIG_HOME/hyprkarl/menu.json")" == "new menu" ]] \
  || fail "new conflicting file changed"

printf 'Personal configuration migration passed.\n'
