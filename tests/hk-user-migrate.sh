#!/bin/bash
# Exercise the personal-config migration in a disposable home and checkout.

ORIG=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d /tmp/hk-user-migrate.XXXXXX)
FAKE_REPO="$TEST_ROOT/repo"
FAKE_HOME="$TEST_ROOT/home"
CONFIG_HOME="$FAKE_HOME/.config"
STATE_HOME="$FAKE_HOME/.local/state"

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
  "$FAKE_REPO/templates/setup/terminals" \
  "$CONFIG_HOME/uwsm" \
  "$CONFIG_HOME/hyprkarl/current"

cp -a "$ORIG/config/." "$FAKE_REPO/config/"

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
cp -a "$ORIG/templates/setup/terminals/." \
  "$FAKE_REPO/templates/setup/terminals/"
printf 'keep me\n' > "$CONFIG_HOME/hyprkarl/current/marker"
printf '{"entries":{}}\n' > "$CONFIG_HOME/hyprkarl/menu.json"
cp "$ORIG/bin/lib/theme.sh" "$FAKE_REPO/bin/lib/theme.sh"

ln -s "$FAKE_REPO/config/uwsm/default" "$CONFIG_HOME/uwsm/default"
ln -s "$FAKE_REPO/config/uwsm/env.local" "$CONFIG_HOME/uwsm/env.local"
ln -s "$FAKE_REPO/config/xdg-terminals.list" "$CONFIG_HOME/xdg-terminals.list"
mkdir -p "$CONFIG_HOME/btop" "$CONFIG_HOME/nvim"
ln -s "$FAKE_REPO/config/btop/btop.conf" "$CONFIG_HOME/btop/btop.conf"
ln -s "$FAKE_REPO/config/nvim/init.lua" "$CONFIG_HOME/nvim/init.lua"
printf 'runtime state\n' > "$CONFIG_HOME/nvim/lazy-lock.json"
ln -s "$FAKE_REPO/config/gtk-3.0" "$CONFIG_HOME/gtk-3.0"
mkdir -p \
  "$CONFIG_HOME/fastfetch" \
  "$CONFIG_HOME/foot" \
  "$CONFIG_HOME/yazi" \
  "$TEST_ROOT/external-fish"
printf 'personal fastfetch\n' > "$CONFIG_HOME/fastfetch/config.jsonc"
printf 'personal foot\n' > "$CONFIG_HOME/foot/foot.ini"
printf 'personal yazi keys\n' > "$CONFIG_HOME/yazi/keymap.toml"
printf 'personal fish\n' > "$TEST_ROOT/external-fish/config.fish"
ln -s "$TEST_ROOT/external-fish" "$CONFIG_HOME/fish"

HOME="$FAKE_HOME" XDG_CONFIG_HOME="$CONFIG_HOME" XDG_STATE_HOME="$STATE_HOME" \
  HYPRKARL_PATH="$FAKE_REPO" \
  "$ORIG/bin/hk-user-migrate" >/dev/null || fail "migration returned nonzero"

[[ -f "$CONFIG_HOME/hyprkarl/hypr/input.lua" ]] \
  || fail "Hyprland config was not moved"
[[ -f "$CONFIG_HOME/hyprkarl/hooks/theme-set.d/10-test" ]] \
  || fail "hook was not moved"
[[ -f "$CONFIG_HOME/quickshell/custom/modules/Test.qml" ]] \
  || fail "QML module was not moved"
[[ "$(cat "$CONFIG_HOME/quickshell/settings/shell.json")" == '{"version":1}' ]] \
  || fail "legacy shell configuration did not reach the native settings directory"
[[ "$(cat "$CONFIG_HOME/quickshell/settings/menu.json")" == '{"entries":{}}' ]] \
  || fail "personal menu configuration was not moved"
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

for path in \
  "$CONFIG_HOME/btop/btop.conf" \
  "$CONFIG_HOME/nvim/init.lua" \
  "$CONFIG_HOME/gtk-3.0/settings.ini" \
  "$CONFIG_HOME/qt5ct/qt5ct.conf"; do
  [[ -f "$path" ]] || fail "$path was not seeded"
  [[ ! -L "$path" ]] || fail "$path is still a shipped config symlink"
done
[[ ! -L "$CONFIG_HOME/gtk-3.0" ]] \
  || fail "folded GTK config directory was not materialized"
[[ "$(cat "$CONFIG_HOME/nvim/lazy-lock.json")" == "runtime state" ]] \
  || fail "existing Neovim state was changed"
[[ "$(cat "$CONFIG_HOME/fastfetch/config.jsonc")" == "personal fastfetch" ]] \
  || fail "existing Fastfetch config was overwritten"
[[ ! -e "$CONFIG_HOME/fastfetch/hyprkarl.txt" ]] \
  || fail "defaults were added beside a personal Fastfetch config"
[[ "$(cat "$CONFIG_HOME/yazi/keymap.toml")" == "personal yazi keys" ]] \
  || fail "existing Yazi config was overwritten"
[[ ! -e "$CONFIG_HOME/yazi/yazi.toml" ]] \
  || fail "defaults were added beside a personal Yazi config"
[[ -L "$CONFIG_HOME/fish" ]] \
  || fail "external Fish config symlink was replaced"
[[ "$(cat "$CONFIG_HOME/fish/config.fish")" == "personal fish" ]] \
  || fail "external Fish config was changed"
grep -Fq "color_scheme_path=$CONFIG_HOME/qt5ct/style-colors.conf" \
  "$CONFIG_HOME/qt5ct/qt5ct.conf" \
  || fail "Qt config path placeholder was not rendered"
[[ -L "$CONFIG_HOME/qt5ct/style-colors.conf" ]] \
  || fail "Qt theme link was not seeded"
[[ -f "$STATE_HOME/hyprkarl/migrations/seeded-application-config-v1" ]] \
  || fail "seed migration marker was not written"
for path in \
  "$CONFIG_HOME/alacritty/local.toml" \
  "$CONFIG_HOME/foot/local.ini" \
  "$CONFIG_HOME/ghostty/local.conf" \
  "$CONFIG_HOME/kitty/local.conf"; do
  [[ -f "$path" ]] || fail "$path was not seeded"
  [[ ! -L "$path" ]] || fail "$path is not user-owned"
done
[[ "$(cat "$CONFIG_HOME/foot/local.ini")" == "personal foot" ]] \
  || fail "existing foot config was not preserved as its sidecar"

stow --restow --no-folding \
  --dir="$FAKE_REPO" \
  --target="$CONFIG_HOME" \
  config >/dev/null || fail "Stow rejected the migrated configuration"
for path in \
  "$CONFIG_HOME/alacritty/alacritty.toml" \
  "$CONFIG_HOME/foot/foot.ini" \
  "$CONFIG_HOME/ghostty/config.ghostty" \
  "$CONFIG_HOME/hypr/hyprland.lua" \
  "$CONFIG_HOME/hypr/hyprtoolkit.conf"; do
  [[ -L "$path" ]] || fail "$path is not a managed entry point"
done
[[ ! -L "$CONFIG_HOME/btop/btop.conf" ]] \
  || fail "Stow reclaimed the personal Btop config"

rm \
  "$CONFIG_HOME/alacritty/local.toml" \
  "$CONFIG_HOME/btop/btop.conf" \
  "$CONFIG_HOME/xdg-terminals.list"

HOME="$FAKE_HOME" XDG_CONFIG_HOME="$CONFIG_HOME" XDG_STATE_HOME="$STATE_HOME" \
  HYPRKARL_PATH="$FAKE_REPO" \
  "$ORIG/bin/hk-user-migrate" >/dev/null || fail "second migration was not idempotent"
[[ ! -e "$CONFIG_HOME/btop/btop.conf" ]] \
  || fail "deleted Btop config was recreated after migration"
[[ ! -e "$CONFIG_HOME/xdg-terminals.list" ]] \
  || fail "deleted terminal preference was recreated after migration"
[[ ! -e "$CONFIG_HOME/alacritty/local.toml" ]] \
  || fail "deleted terminal sidecar was recreated after migration"

mkdir -p "$FAKE_REPO/user"
printf 'old menu\n' > "$FAKE_REPO/user/menu.json"
printf 'new menu\n' > "$CONFIG_HOME/hyprkarl/menu.json"
if HOME="$FAKE_HOME" XDG_CONFIG_HOME="$CONFIG_HOME" XDG_STATE_HOME="$STATE_HOME" \
    HYPRKARL_PATH="$FAKE_REPO" \
    "$ORIG/bin/hk-user-migrate" >/dev/null 2>&1; then
  fail "conflicting personal files were accepted"
fi
[[ "$(cat "$FAKE_REPO/user/menu.json")" == "old menu" ]] \
  || fail "old conflicting file changed"
[[ "$(cat "$CONFIG_HOME/hyprkarl/menu.json")" == "new menu" ]] \
  || fail "new conflicting file changed"

rm "$FAKE_REPO/user/menu.json" "$CONFIG_HOME/hyprkarl/menu.json"
printf 'old shell\n' > "$CONFIG_HOME/hyprkarl/shell.json"
if HOME="$FAKE_HOME" XDG_CONFIG_HOME="$CONFIG_HOME" XDG_STATE_HOME="$STATE_HOME" \
    HYPRKARL_PATH="$FAKE_REPO" \
    "$ORIG/bin/hk-user-migrate" >/dev/null 2>&1; then
  fail "conflicting native Quickshell settings were accepted"
fi
[[ "$(cat "$CONFIG_HOME/hyprkarl/shell.json")" == 'old shell' ]] \
  || fail "legacy conflicting shell config changed"
[[ "$(cat "$CONFIG_HOME/quickshell/settings/shell.json")" == '{"version":1}' ]] \
  || fail "native conflicting shell config changed"

rm "$CONFIG_HOME/hyprkarl/shell.json"
HOME="$FAKE_HOME" XDG_CONFIG_HOME="$CONFIG_HOME" XDG_STATE_HOME="$STATE_HOME" \
  HYPRKARL_PATH="$FAKE_REPO" "$ORIG/bin/hk-user-migrate" >/dev/null \
  || fail "repeat migration failed"

printf 'Personal configuration migration passed.\n'
