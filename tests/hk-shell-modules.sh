#!/bin/bash
# Exercise disabled built-in modules and the personal overlay context.

REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
FIXTURES="$REPO/tests/fixtures/quickshell-modules"
TEST_ROOT=$(mktemp -d /tmp/hk-shell-modules.XXXXXX)
SHELL_ROOT="$TEST_ROOT/repo/config/quickshell"
CONFIG_HOME="$TEST_ROOT/home/.config"
STATE_HOME="$TEST_ROOT/home/.local/state"

cleanup() {
  trap - EXIT
  stop_shell >/dev/null 2>&1 || true
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

start_shell() {
  XDG_CONFIG_HOME="$CONFIG_HOME" XDG_STATE_HOME="$STATE_HOME" \
    QML_IMPORT_PATH="$SHELL_ROOT" \
    qs -d -p "$SHELL_ROOT" --no-color \
    || fail "Quickshell did not start"

  for _ in {1..50}; do
    if XDG_CONFIG_HOME="$CONFIG_HOME" XDG_STATE_HOME="$STATE_HOME" \
        qs list -p "$SHELL_ROOT" -j 2>/dev/null | jq -e 'length == 1' >/dev/null; then
      return
    fi
    sleep 0.1
  done
  fail "Quickshell instance was not discoverable"
}

stop_shell() {
  local instances pids daemon_running
  instances=$(XDG_CONFIG_HOME="$CONFIG_HOME" XDG_STATE_HOME="$STATE_HOME" \
    qs list -p "$SHELL_ROOT" -j 2>/dev/null)
  if ! jq -e 'length > 0' <<< "$instances" >/dev/null 2>&1; then
    return
  fi

  pids=$(jq -r '.[].pid' <<< "$instances")
  while read -r instance_id; do
    XDG_CONFIG_HOME="$CONFIG_HOME" XDG_STATE_HOME="$STATE_HOME" \
      qs kill -i "$instance_id" >/dev/null \
      || fail "could not stop isolated Quickshell instance"
  done < <(jq -r '.[].id' <<< "$instances")
  while read -r pid; do
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" || fail "could not stop isolated Quickshell daemon"
    fi
  done <<< "$pids"

  for _ in {1..100}; do
    daemon_running=false
    while read -r pid; do
      if kill -0 "$pid" 2>/dev/null; then
        daemon_running=true
        break
      fi
    done <<< "$pids"
    if [[ "$daemon_running" == false ]]; then
      return
    fi
    sleep 0.05
  done
  fail "isolated Quickshell daemon did not stop"
}

mkdir -p \
  "$TEST_ROOT/repo/config" \
  "$TEST_ROOT/repo/defaults" \
  "$CONFIG_HOME/hyprkarl/quickshell" \
  "$STATE_HOME/hyprkarl/current" \
  "$STATE_HOME/hyprkarl/themes/test"
cp -a "$REPO/config/quickshell" "$TEST_ROOT/repo/config/"
cp "$REPO/defaults/shell.json" "$REPO/defaults/menu.json" \
  "$TEST_ROOT/repo/defaults/"
cp "$FIXTURES/shell.json" "$CONFIG_HOME/hyprkarl/shell.json"
cp "$FIXTURES/Extensions.qml" \
  "$CONFIG_HOME/hyprkarl/quickshell/Extensions.qml"
cp "$FIXTURES/theme.json" "$STATE_HOME/hyprkarl/current/theme.json"
cp "$FIXTURES/quickshell.json" \
  "$STATE_HOME/hyprkarl/themes/test/quickshell.json"

start_shell

instance=$(XDG_CONFIG_HOME="$CONFIG_HOME" XDG_STATE_HOME="$STATE_HOME" \
  qs list -p "$SHELL_ROOT" -j 2>/dev/null) \
  || fail "Quickshell instance was not discoverable"
[[ $(jq 'length' <<< "$instance") -eq 1 ]] \
  || fail "expected one isolated Quickshell instance"

ipc=$(XDG_CONFIG_HOME="$CONFIG_HOME" XDG_STATE_HOME="$STATE_HOME" \
  qs ipc -p "$SHELL_ROOT" show 2>/dev/null) \
  || fail "could not inspect IPC targets"
grep -q 'userTest' <<< "$ipc" \
  || fail "personal QML IPC target is missing"
for target in menu launcher openWith calculator wallpaper notifications osd; do
  if grep -q "^$target" <<< "$ipc"; then
    fail "disabled IPC target '$target' is still present"
  fi
done
grep -q '^target screenshot' <<< "$ipc" \
  || fail "screenshot coordination IPC target is missing"
[[ $(XDG_CONFIG_HOME="$CONFIG_HOME" XDG_STATE_HOME="$STATE_HOME" \
  qs ipc -p "$SHELL_ROOT" call screenshot begin) == true ]] \
  || fail "screenshot focus hold did not start"
[[ $(XDG_CONFIG_HOME="$CONFIG_HOME" XDG_STATE_HOME="$STATE_HOME" \
  qs ipc -p "$SHELL_ROOT" call screenshot finish) == true ]] \
  || fail "screenshot focus hold did not finish"

call_user_test() {
  XDG_CONFIG_HOME="$CONFIG_HOME" XDG_STATE_HOME="$STATE_HOME" \
    qs ipc -p "$SHELL_ROOT" call userTest "$@"
}

initial=$(call_user_test snapshot) || fail "could not read personal QML context"
jq -e '.configuration == 1 and .fixture == true and .name == ""' \
  <<< "$initial" >/dev/null \
  || fail "personal QML context did not expose configuration, settings, and overlay state"

output=$(jq -r '.[0].name' <<< "$(hyprctl -j monitors)")
[[ -n "$output" && "$output" != null ]] || fail "no output available for overlay test"

call_user_test open dashboard "$output" weather >/dev/null \
  || fail "openOverlay failed"
opened=$(call_user_test snapshot)
jq -e --arg output "$output" \
  '.name == "dashboard" and .output == $output and .values.section == "weather"' \
  <<< "$opened" >/dev/null \
  || fail "personal overlay did not receive its request"

call_user_test open blocked "$output" ignored >/dev/null
jq -e '.name == "dashboard" and .values.section == "weather"' \
  <<< "$(call_user_test snapshot)" >/dev/null \
  || fail "openOverlay replaced an existing overlay"
call_user_test push launcher "$output" applications >/dev/null \
  || fail "pushOverlay failed"
jq -e '.name == "launcher" and .values.section == "applications"' \
  <<< "$(call_user_test snapshot)" >/dev/null \
  || fail "pushed overlay did not receive its request"
[[ $(call_user_test back) == true ]] \
  || fail "backOverlay did not restore the prior request"
jq -e '.name == "dashboard" and .values.section == "weather"' \
  <<< "$(call_user_test snapshot)" >/dev/null \
  || fail "backOverlay restored the wrong request"
call_user_test replace replacement "$output" controls >/dev/null \
  || fail "replaceOverlay failed"
replaced=$(call_user_test snapshot)
jq -e '.name == "replacement" and .values.section == "controls"' \
  <<< "$replaced" >/dev/null \
  || fail "replaceOverlay did not replace the request"
[[ $(call_user_test back) == false ]] \
  || fail "replaceOverlay retained a stale return request"

call_user_test toggle replacement "$output" controls >/dev/null \
  || fail "toggleOverlay did not close the matching request"
jq -e '.name == ""' <<< "$(call_user_test snapshot)" >/dev/null \
  || fail "toggleOverlay left the matching request open"

call_user_test toggle dashboard "$output" system >/dev/null \
  || fail "toggleOverlay did not open a different request"
call_user_test close >/dev/null || fail "closeOverlay failed"
jq -e '.name == ""' <<< "$(call_user_test snapshot)" >/dev/null \
  || fail "closeOverlay left a request open"

call_user_test open user.fixture "$output" modal >/dev/null \
  || fail "public personal modal did not open"
for _ in {1..20}; do
  [[ $(call_user_test snapshot | jq -r '.modalLoads') -eq 1 ]] && break
  sleep 0.05
done
jq -e '.name == "user.fixture" and .modalLoads == 1' \
  <<< "$(call_user_test snapshot)" >/dev/null \
  || fail "public personal modal body did not load on demand"
call_user_test close >/dev/null || fail "public personal modal did not close"
call_user_test open user.fixture "$output" modal >/dev/null \
  || fail "public personal modal did not reopen"
for _ in {1..20}; do
  [[ $(call_user_test snapshot | jq -r '.modalLoads') -eq 2 ]] && break
  sleep 0.05
done
jq -e '.modalLoads == 2' <<< "$(call_user_test snapshot)" >/dev/null \
  || fail "public personal modal content was not recreated"
call_user_test close >/dev/null || fail "public personal modal did not close"

if pgrep -af "$SHELL_ROOT/scripts/read-system-state.sh" >/dev/null; then
  fail "bar system monitor started while the bar was disabled"
fi

stop_shell
cp "$FIXTURES/bar-no-panels.json" "$CONFIG_HOME/hyprkarl/shell.json"
rm -f "$CONFIG_HOME/hyprkarl/quickshell/Extensions.qml"
start_shell
sleep 0.5

panel_log=$(XDG_CONFIG_HOME="$CONFIG_HOME" XDG_STATE_HOME="$STATE_HOME" \
  qs log -p "$SHELL_ROOT" --tail 200 --no-color 2>/dev/null) \
  || fail "could not read bar-without-panels log"
if grep -Eq 'TypeError|ReferenceError|failed to load' <<< "$panel_log"; then
  printf '%s\n' "$panel_log" >&2
  fail "bar without panels produced a runtime error"
fi
pgrep -af "$SHELL_ROOT/scripts/read-system-state.sh" >/dev/null \
  || fail "bar system monitor did not start with the bar enabled"

printf 'Shell module and personal modal checks passed.\n'
