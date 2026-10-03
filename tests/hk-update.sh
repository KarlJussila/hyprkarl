#!/bin/bash
# Isolated acceptance checks for the Hyprkarl update workflow.

ORIG=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d /tmp/hk-update-test.XXXXXX)
UPSTREAM="$WORK/upstream.git"
CLONE="$WORK/hyprkarl"
FAKEHOME="$WORK/home"
MOCKBIN="$WORK/mockbin"

cleanup() {
  rm -rf "$WORK"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_equal() {
  local actual="$1" expected="$2" message="$3"
  [[ "$actual" == "$expected" ]] || fail "$message (got '$actual', expected '$expected')"
}

assert_file_contains() {
  local path="$1" pattern="$2" message="$3"
  grep -Fqi "$pattern" "$path" || fail "$message"
}

make_mock_commands() {
  mkdir -p "$MOCKBIN"

  cat > "$MOCKBIN/gum" <<'EOF'
#!/bin/bash
case "$1" in
  confirm) exit 0 ;;
  choose)
    printf 'choose\n' >> "$HK_TEST_GUM_LOG"
    case "${HK_TEST_GUM_MODE:-all}" in
      escape) cat >/dev/null; exit 130 ;;
      none) cat >/dev/null; exit 0 ;;
      *)
        while IFS=$'\t' read -r _ value; do
          for selected in ${HK_TEST_GUM_SELECTED:-$value}; do
            [[ "$value" == "$selected" ]] && printf '%s\n' "$value"
          done
        done
        exit 0
        ;;
    esac
    ;;
  *) exit 0 ;;
esac
EOF

  cat > "$MOCKBIN/pacman" <<'EOF'
#!/bin/bash
case "$1" in
  -Qq) cat "$HK_TEST_INSTALLED" ;;
  -Qqt) grep -Fxv -f "${HK_TEST_REQUIRED:-/dev/null}" "$HK_TEST_INSTALLED" ;;
  -D) printf '%s\n' "$*" >> "$HK_TEST_ASDEPS_LOG" ;;
  -Q) grep -Fxq "$2" "$HK_TEST_INSTALLED" ;;
  -T) shift; missing=$(printf '%s\n' "$@" | grep -Fxv -f "$HK_TEST_INSTALLED"); [[ -z "$missing" ]] || { printf '%s\n' "$missing"; exit 127; } ;;
  -Syu) shift 3; [[ $# -gt 0 ]] && printf '%s\n' "$*" >> "$HK_TEST_INSTALL_LOG"; exit 0 ;;
  *) exit 0 ;;
esac
EOF

  cat > "$MOCKBIN/hk-pkg-remove" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >> "$HK_TEST_REMOVE_LOG"
if [[ "${HK_TEST_REMOVE_FAIL:-0}" -ne 0 ]]; then
  exit 1
fi
if [[ -n "${HK_TEST_REMOVE_CASCADE:-}" ]]; then
  grep -Fxv "$HK_TEST_REMOVE_CASCADE" "$HK_TEST_INSTALLED" \
    > "$HK_TEST_INSTALLED.next"
  mv "$HK_TEST_INSTALLED.next" "$HK_TEST_INSTALLED"
fi
EOF

  cat > "$MOCKBIN/hk-pkg-install-aur" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >> "$HK_TEST_INSTALL_LOG"
EOF

  cat > "$MOCKBIN/sudo" <<'EOF'
#!/bin/bash
[[ "$1" == "-v" ]] && exit 0
exec "$@"
EOF

  cat > "$MOCKBIN/qs" <<'EOF'
#!/bin/bash
if [[ "${HK_TEST_SHELL_RUNNING:-0}" -eq 1 ]] && [[ "$1" == "list" ]]; then
  printf '[{"id":"test","pid":123,"launch_time":"now"}]\n'
else
  printf '[]\n'
fi
EOF

  cat > "$MOCKBIN/hk-shell" <<'EOF'
#!/bin/bash
printf '%s %s\n' "$1" "$(git -C "$HYPRKARL_PATH" rev-parse HEAD)" >> "$HK_TEST_SHELL_LOG"
EOF

  for command in hk-wallpaper-init hk-wallpaper-cycle hk-terminal-reload hk-btop-reload hyprctl notify-send; do
    cat > "$MOCKBIN/$command" <<'EOF'
#!/bin/bash
exit 0
EOF
  done

  chmod +x "$MOCKBIN"/*
}

run_isolated() {
  HOME="$FAKEHOME" \
  XDG_CONFIG_HOME="$FAKEHOME/.config" \
  XDG_STATE_HOME="$FAKEHOME/.local/state" \
  XDG_CACHE_HOME="$FAKEHOME/.cache" \
  XDG_DATA_HOME="$FAKEHOME/.local/share" \
  XDG_RUNTIME_DIR="$WORK/runtime" \
  GSETTINGS_BACKEND=memory \
  HYPRKARL_PATH="$CLONE" \
  HK_TEST_INSTALLED="$WORK/installed-all" \
  HK_TEST_INSTALL_LOG="$WORK/apply-installs.log" \
  HK_TEST_REMOVE_LOG="$WORK/apply-removals.log" \
  HK_TEST_GUM_LOG="$WORK/apply-gum.log" \
  PATH="$MOCKBIN:$ORIG/bin:$PATH" \
  "$@"
}

setup_source_sandbox() {
  git clone --bare -q "$ORIG" "$UPSTREAM" || exit 1
  git clone -q "$UPSTREAM" "$CLONE" || exit 1
  git -C "$CLONE" config user.email test@example.com
  git -C "$CLONE" config user.name "Hyprkarl Update Test"
  branch=$(git -C "$CLONE" branch --show-current)
  git -C "$CLONE" config hyprkarl.updateRemote origin
  git -C "$CLONE" config hyprkarl.updateBranch "$branch"
  mkdir -p "$FAKEHOME/.config" "$FAKEHOME/.cache" \
    "$FAKEHOME/.local/state" "$FAKEHOME/.local/share/applications" "$WORK/runtime"

  # Every required package is installed, and the shipped migrations already
  # ran, so apply's package and migration steps touch nothing real.
  sed 's/#.*//' "$CLONE/packages/pacman.txt" "$CLONE/packages/aur.txt" \
    | tr -s ' \t' '\n' | grep . > "$WORK/installed-all"
  mkdir -p "$FAKEHOME/.local/state/hyprkarl/update/migrations"
  for migration in "$CLONE/migrations"/*; do
    : > "$FAKEHOME/.local/state/hyprkarl/update/migrations/${migration##*/}"
  done
}

test_source_and_theme_apply() {
  printf 'Testing reviewed source and theme application...\n'
  run_isolated "$ORIG/bin/hk-update-apply" >/dev/null || fail "initial configuration apply failed"

  repair_link="$FAKEHOME/.config/kitty/kitty.conf"
  [[ -L "$repair_link" ]] || fail "initial apply did not stow shipped configuration"
  rm "$repair_link"
  run_isolated "$ORIG/bin/hk-update-apply" >/dev/null \
    || fail "same-revision configuration repair failed"
  [[ -L "$repair_link" ]] \
    || fail "same-revision apply did not restore a missing shipped symlink"

  sed -i 's/background: "#1b1519"/background: "#101820"/' \
    "$CLONE/themes/hyprkarl/theme.yaml"
  sed -i 's/foreground: "#d2ccd2"/foreground: "#aabbcc"/' \
    "$CLONE/themes/hyprkarl/theme.yaml"
  git -C "$CLONE" add themes/hyprkarl/theme.yaml
  git -C "$CLONE" commit -q -m "test: update active theme"
  target=$(git -C "$CLONE" rev-parse HEAD)
  git -C "$CLONE" push -q origin "$branch"
  git -C "$CLONE" reset --hard HEAD~1 -q
  old_head=$(git -C "$CLONE" rev-parse HEAD)
  shell_log="$WORK/shell.log"

  printf '\n# local test change\n' >> "$CLONE/themes/hyprkarl/theme.yaml"
  if run_isolated "$ORIG/bin/hk-update-sync" >/dev/null 2>&1; then
    fail "source review accepted a dirty tracked checkout"
  fi
  git -C "$CLONE" restore themes/hyprkarl/theme.yaml

  run_isolated "$ORIG/bin/hk-update-sync" >/dev/null || fail "source review failed"
  assert_equal "$(git -C "$CLONE" rev-parse HEAD)" "$old_head" \
    "sync changed the live checkout before apply"
  assert_equal "$(cat "$FAKEHOME/.local/state/hyprkarl/update/pending-source.revision")" "$target" \
    "sync did not pin the reviewed revision"

  HK_TEST_SHELL_RUNNING=1 HK_TEST_SHELL_LOG="$shell_log" \
    run_isolated "$ORIG/bin/hk-update-apply" >/dev/null \
    || fail "reviewed update apply failed"
  assert_equal "$(git -C "$CLONE" rev-parse HEAD)" "$target" \
    "apply did not fast-forward to the reviewed revision"
  assert_equal "$(sed -n '1p' "$shell_log")" "stop $old_head" \
    "apply did not stop Quickshell before advancing the checkout"
  assert_equal "$(sed -n '2p' "$shell_log")" "start $target" \
    "apply did not restart Quickshell from the complete reviewed tree"
  assert_file_contains \
    "$FAKEHOME/.local/state/hyprkarl/current/theme/quickshell.json" "#101820" \
    "runtime theme did not contain the updated source"
  assert_file_contains \
    "$FAKEHOME/.local/share/themes/hyprkarl/gtk-3.0/gtk.css" "aabbcc" \
    "GTK payload did not contain the updated source"

  old_selector=$(readlink "$FAKEHOME/.local/state/hyprkarl/current/theme")
  old_applied=$(cat "$FAKEHOME/.local/state/hyprkarl/update/configuration.revision")
  sed -i 's/background: "#101820"/background: "{{missing.value}}"/' \
    "$CLONE/themes/hyprkarl/theme.yaml"
  git -C "$CLONE" add themes/hyprkarl/theme.yaml
  git -C "$CLONE" commit -q -m "test: invalid active theme"
  invalid_target=$(git -C "$CLONE" rev-parse HEAD)
  git -C "$CLONE" push -q origin "$branch"
  git -C "$CLONE" reset --hard HEAD~1 -q

  run_isolated "$ORIG/bin/hk-update-sync" >/dev/null || fail "invalid source review failed"
  : > "$shell_log"
  if HK_TEST_SHELL_RUNNING=1 HK_TEST_SHELL_LOG="$shell_log" \
      run_isolated "$ORIG/bin/hk-update-apply" >/dev/null 2>&1; then
    fail "invalid theme apply unexpectedly succeeded"
  fi
  assert_equal "$(cut -d' ' -f1 "$shell_log" | paste -sd,)" "stop,start" \
    "failed apply did not stop Quickshell and start it again"
  assert_equal "$(readlink "$FAKEHOME/.local/state/hyprkarl/current/theme")" "$old_selector" \
    "failed theme build replaced the active selector"
  assert_equal "$(cat "$FAKEHOME/.local/state/hyprkarl/update/configuration.revision")" "$old_applied" \
    "failed theme build recorded configuration success"
  assert_equal "$(cat "$FAKEHOME/.local/state/hyprkarl/update/pending-source.revision")" "$invalid_target" \
    "failed apply discarded its reviewed source marker"

  git -C "$CLONE" revert --no-edit "$invalid_target" >/dev/null \
    || fail "could not create repaired source revision"
  repaired_target=$(git -C "$CLONE" rev-parse HEAD)
  printf '%s\n' "$repaired_target" \
    > "$FAKEHOME/.local/state/hyprkarl/update/pending-source.revision"
  : > "$shell_log"
  HK_TEST_SHELL_RUNNING=1 HK_TEST_SHELL_LOG="$shell_log" \
    run_isolated "$ORIG/bin/hk-update-apply" >/dev/null \
    || fail "repaired configuration retry failed"
  assert_equal "$(tail -n 1 "$shell_log")" "start $repaired_target" \
    "successful retry did not start Quickshell from the repaired revision"
}

test_package_review() {
  printf 'Testing one-time package removal review...\n'
  package_state="$WORK/package-state"
  installed_file="$WORK/installed"
  remove_log="$WORK/removals.log"
  install_log="$WORK/installs.log"
  gum_log="$WORK/gum.log"
  printf 'base\nold-one\nold-two\nold-three\nold-four\n' > "$installed_file"
  printf 'base\n' > "$CLONE/packages/pacman.txt"
  : > "$CLONE/packages/aur.txt"
  printf 'old-one # first\nold-two # second\n' > "$CLONE/packages/remove.txt"

  HOME="$FAKEHOME" XDG_STATE_HOME="$package_state" HYPRKARL_PATH="$CLONE" \
    HK_TEST_INSTALLED="$installed_file" HK_TEST_REMOVE_LOG="$remove_log" \
    HK_TEST_INSTALL_LOG="$install_log" HK_TEST_GUM_LOG="$gum_log" \
    HK_TEST_GUM_SELECTED="old-one" PATH="$MOCKBIN:$ORIG/bin:$PATH" \
    "$ORIG/bin/hk-update-packages" || fail "package review failed"
  assert_equal "$(cat "$remove_log")" "old-one" "package deselection was not honored"

  HOME="$FAKEHOME" XDG_STATE_HOME="$package_state" HYPRKARL_PATH="$CLONE" \
    HK_TEST_INSTALLED="$installed_file" HK_TEST_REMOVE_LOG="$remove_log" \
    HK_TEST_INSTALL_LOG="$install_log" HK_TEST_GUM_LOG="$gum_log" \
    PATH="$MOCKBIN:$ORIG/bin:$PATH" "$ORIG/bin/hk-update-packages" >/dev/null \
    || fail "acknowledged package rerun failed"
  assert_equal "$(wc -l < "$gum_log")" "1" "acknowledged removals were shown again"

  printf 'old-one # first\nold-two # second\nold-three # third\n' \
    > "$CLONE/packages/remove.txt"
  HOME="$FAKEHOME" XDG_STATE_HOME="$package_state" HYPRKARL_PATH="$CLONE" \
    HK_TEST_INSTALLED="$installed_file" HK_TEST_REMOVE_LOG="$remove_log" \
    HK_TEST_INSTALL_LOG="$install_log" HK_TEST_GUM_LOG="$gum_log" \
    HK_TEST_GUM_SELECTED="old-three" HK_TEST_REMOVE_FAIL=1 \
    PATH="$MOCKBIN:$ORIG/bin:$PATH" "$ORIG/bin/hk-update-packages" >/dev/null 2>&1
  assert_equal "$?" "1" "failed removal did not fail the package step"

  HOME="$FAKEHOME" XDG_STATE_HOME="$package_state" HYPRKARL_PATH="$CLONE" \
    HK_TEST_INSTALLED="$installed_file" HK_TEST_REMOVE_LOG="$remove_log" \
    HK_TEST_INSTALL_LOG="$install_log" HK_TEST_GUM_LOG="$gum_log" \
    PATH="$MOCKBIN:$ORIG/bin:$PATH" "$ORIG/bin/hk-update-packages" >/dev/null \
    || fail "failed removal acknowledgement rerun failed"
  assert_equal "$(wc -l < "$gum_log")" "2" "failed removal was presented more than once"

  before=$(sha256sum "$package_state/hyprkarl/update/packages.json" | cut -d' ' -f1)
  printf 'old-one\nold-two\nold-three\nold-four\n' > "$CLONE/packages/remove.txt"
  HOME="$FAKEHOME" XDG_STATE_HOME="$package_state" HYPRKARL_PATH="$CLONE" \
    HK_TEST_INSTALLED="$installed_file" HK_TEST_REMOVE_LOG="$remove_log" \
    HK_TEST_INSTALL_LOG="$install_log" HK_TEST_GUM_LOG="$gum_log" \
    HK_TEST_GUM_MODE=escape PATH="$MOCKBIN:$ORIG/bin:$PATH" \
    "$ORIG/bin/hk-update-packages" >/dev/null 2>&1
  assert_equal "$?" "1" "Escape did not cancel the package step"
  after=$(sha256sum "$package_state/hyprkarl/update/packages.json" | cut -d' ' -f1)
  assert_equal "$after" "$before" "cancelled package review changed state"

  printf 'base\nnewdep\nold-four\n' > "$installed_file"
  printf 'base\nnewdep\n' > "$CLONE/packages/pacman.txt"
  : > "$install_log"
  HOME="$FAKEHOME" XDG_STATE_HOME="$package_state" HYPRKARL_PATH="$CLONE" \
    HK_TEST_INSTALLED="$installed_file" HK_TEST_REMOVE_LOG="$remove_log" \
    HK_TEST_INSTALL_LOG="$install_log" HK_TEST_GUM_LOG="$gum_log" \
    HK_TEST_GUM_SELECTED="old-four" HK_TEST_REMOVE_CASCADE="newdep" \
    PATH="$MOCKBIN:$ORIG/bin:$PATH" "$ORIG/bin/hk-update-packages" >/dev/null \
    || fail "post-removal package refresh failed"
  assert_equal "$(cat "$install_log")" "newdep" \
    "dependency removed by a package cascade was not reinstalled"

  printf 'old-five\n' >> "$installed_file"
  printf 'old-five\n' > "$WORK/required"
  printf 'old-five # needed elsewhere\n' >> "$CLONE/packages/remove.txt"
  : > "$remove_log"
  : > "$WORK/asdeps.log"
  HOME="$FAKEHOME" XDG_STATE_HOME="$package_state" HYPRKARL_PATH="$CLONE" \
    HK_TEST_INSTALLED="$installed_file" HK_TEST_REQUIRED="$WORK/required" \
    HK_TEST_ASDEPS_LOG="$WORK/asdeps.log" HK_TEST_REMOVE_LOG="$remove_log" \
    HK_TEST_INSTALL_LOG="$install_log" HK_TEST_GUM_LOG="$gum_log" \
    PATH="$MOCKBIN:$ORIG/bin:$PATH" "$ORIG/bin/hk-update-packages" >/dev/null \
    || fail "a removal still required by another package failed the step"
  [[ ! -s "$remove_log" ]] || fail "a package other packages need was removed"
  assert_equal "$(cat "$WORK/asdeps.log")" "-D --asdeps old-five" \
    "a still-needed package was not marked as a dependency"
}

test_migrations() {
  printf 'Testing ordered migrations during apply...\n'
  migration_log="$WORK/migrations.log"
  git -C "$CLONE" checkout -q packages
  cat > "$CLONE/migrations/900-first" <<'EOF'
#!/bin/bash
printf 'first\n' >> "$HK_TEST_MIGRATION_LOG"
EOF
  cat > "$CLONE/migrations/910-second" <<'EOF'
#!/bin/bash
printf 'second\n' >> "$HK_TEST_MIGRATION_LOG"
[[ "${HK_TEST_MIGRATION_FAIL:-0}" -eq 0 ]]
EOF
  chmod +x "$CLONE/migrations"/9*
  git -C "$CLONE" add migrations
  git -C "$CLONE" commit -q -m "test: add migrations"

  HK_TEST_MIGRATION_LOG="$migration_log" HK_TEST_MIGRATION_FAIL=1 \
    run_isolated "$ORIG/bin/hk-update-apply" >/dev/null 2>&1
  assert_equal "$?" "1" "a failed migration did not fail apply"
  state="$FAKEHOME/.local/state/hyprkarl/update/migrations"
  [[ -e "$state/900-first" ]] || fail "successful migration was not recorded"
  [[ ! -e "$state/910-second" ]] || fail "failed migration was recorded"

  HK_TEST_MIGRATION_LOG="$migration_log" \
    run_isolated "$ORIG/bin/hk-update-apply" >/dev/null \
    || fail "apply did not resume after the migration was fixed"
  assert_equal "$(paste -sd, "$migration_log")" "first,second,second" \
    "migrations did not resume in order"
}

make_mock_commands
setup_source_sandbox
test_source_and_theme_apply
test_package_review
test_migrations
printf 'All update acceptance checks passed.\n'
