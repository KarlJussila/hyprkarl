#!/bin/bash
# tests/hk-update-tui.sh
# Manual sandbox harness for exercising hk-update-tui's sync, conflict, and
# apply phases without touching your real repo, ~/.config, or GitHub.
#
# How isolation works:
#  - A throwaway clone of this repo gets a *local* fake remote (never GitHub).
#  - HYPRKARL_PATH points the TUI at the clone, so all git/baseline operations
#    stay in the sandbox.
#  - The TUI itself runs from the working tree (bin/hk-update-tui), so you test
#    your current, possibly-uncommitted code against a disposable git history.
#  - Apply-dotfiles additionally redirects $HOME to a throwaway dir so stow
#    targets a fake ~/.config.
#
# Usage:
#   tests/hk-update-tui.sh setup     # create the sandbox (run once)
#   tests/hk-update-tui.sh a         # Scenario A: clean merge + review browser
#   tests/hk-update-tui.sh b         # Scenario B: dirty tree -> stash path
#   tests/hk-update-tui.sh c         # Scenario C: real merge conflict
#   tests/hk-update-tui.sh d         # Scenario D: stash-pop conflict
#
#   tests/hk-update-tui.sh apply-dotfiles          # APPLY dotfiles into a fake $HOME
#   tests/hk-update-tui.sh apply-dotfiles-conflict # APPLY with a planted stow conflict
#   tests/hk-update-tui.sh apply-packages          # APPLY: installs the tiny 'sl' package
#   tests/hk-update-tui.sh apply-packages-cleanup  # uninstall 'sl' again
#
#   tests/hk-update-tui.sh status    # show sandbox git state
#   tests/hk-update-tui.sh clean     # remove the sandbox
#
# SAFETY:
#  - Scenarios a-d: sandboxed git only. Choose **Quit** at Review; don't apply.
#  - apply-dotfiles[-conflict]: fully isolated. $HOME is redirected to a throwaway
#    dir, so stow targets a fake ~/.config — your real config is never touched.
#    (It still runs `hyprctl reload`, a harmless no-op reload of your real config.)
#  - apply-packages: NOT isolated — pacman is system-wide. It installs the real
#    but inconsequential `sl` package (10 KB, no deps) via sudo, then you remove
#    it with apply-packages-cleanup. System apply (setup-system.sh) is too
#    invasive to fake and is intentionally not covered here.

ORIG=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
WORK="/tmp/hk-update-tui-test"
UPSTREAM="$WORK/upstream.git"
CLONE="$WORK/clone"
FAKEHOME="$WORK/home"
BASE_FILE="$WORK/base-sha"

require_sandbox() {
  if [[ ! -d "$CLONE/.git" ]]; then
    echo "No sandbox yet. Run: $0 setup" >&2
    exit 1
  fi
  BRANCH=$(git -C "$CLONE" symbolic-ref --short HEAD)
  BASE=$(cat "$BASE_FILE")
}

reset_to_base() {
  # Rewind the fake remote and the clone to the pristine tip so scenarios are
  # independent of each other.
  git -C "$UPSTREAM" update-ref "refs/heads/$BRANCH" "$BASE"
  git -C "$CLONE" fetch origin -q
  git -C "$CLONE" reset --hard "origin/$BRANCH" -q
  git -C "$CLONE" clean -fd -q
}

push_upstream_commit() {
  # Commit the currently staged/working changes, publish to the fake remote,
  # then rewind the clone one commit so it is "behind" upstream.
  git -C "$CLONE" commit -q -m "$1"
  git -C "$CLONE" push -q origin "$BRANCH"
  git -C "$CLONE" reset --hard HEAD~1 -q
}

run_tui() {
  echo
  echo "============================================================"
  echo " Launching hk-update-tui against the sandbox ($CLONE)"
  echo " Reminder: explore Sync + Review, then QUIT. Do not apply."
  echo "============================================================"
  echo
  HYPRKARL_PATH="$CLONE" PATH="$ORIG/bin:$PATH" hk-update-tui
}

run_tui_fakehome() {
  rm -rf "$FAKEHOME"
  mkdir -p "$FAKEHOME/.config" \
           "$FAKEHOME/.local/share/applications" \
           "$FAKEHOME/.local/share/themes/hyprkarl"
  "$@"   # optional pre-seed hook (e.g. plant a conflict file) runs after dirs exist
  echo
  echo "============================================================"
  echo " Launching hk-update-tui with an ISOLATED fake \$HOME:"
  echo "   $FAKEHOME"
  echo " Apply Dotfiles here — your real ~/.config is NOT touched."
  echo "============================================================"
  echo
  HOME="$FAKEHOME" HYPRKARL_PATH="$CLONE" PATH="$ORIG/bin:$PATH" hk-update-tui
}

# Make a local commit that changes TYPE's tracked files, then point that
# category's baseline one commit back so the change shows up as pending.
seed_pending_change() {
  local type="$1" file="$2"
  case "$type" in
    dotfiles) printf '\n# apply-test tweak %s\n' "$(date +%s)" >> "$CLONE/$file" ;;
    packages) printf 'sl\n' >> "$CLONE/$file" ;;
  esac
  git -C "$CLONE" commit -q -am "test: $type change"
  mkdir -p "$CLONE/config/hyprkarl/update"
  git -C "$CLONE" rev-parse HEAD~1 > "$CLONE/config/hyprkarl/update/$type.commit"
}

plant_stow_conflict() {
  mkdir -p "$FAKEHOME/.config/hypr"
  printf '# my hand-edited local file\n' > "$FAKEHOME/.config/hypr/hyprland.conf"
}

cmd_setup() {
  rm -rf "$WORK"
  mkdir -p "$WORK"
  git clone --bare -q "$ORIG" "$UPSTREAM"
  git clone -q "$UPSTREAM" "$CLONE"
  git -C "$CLONE" config user.email test@example.com
  git -C "$CLONE" config user.name "Update TUI Test"
  BRANCH=$(git -C "$CLONE" symbolic-ref --short HEAD)
  git -C "$CLONE" rev-parse "$BRANCH" > "$BASE_FILE"
  echo "Sandbox ready at $WORK (branch: $BRANCH)"
  echo "Fake remote: $UPSTREAM (no network / GitHub involved)"
  echo "Now run: $0 a|b|c|d"
}

cmd_a() {
  require_sandbox
  reset_to_base
  # Upstream-only change to a config file so the Review diff browser has content.
  printf '\n# upstream test tweak\n' >> "$CLONE/config/hypr/hyprland.conf"
  git -C "$CLONE" add config/hypr/hyprland.conf
  push_upstream_commit "upstream: hyprland.conf tweak"
  run_tui
}

cmd_b() {
  require_sandbox
  reset_to_base
  printf '\n# upstream test tweak\n' >> "$CLONE/config/hypr/hyprland.conf"
  git -C "$CLONE" add config/hypr/hyprland.conf
  push_upstream_commit "upstream: hyprland.conf tweak"
  # Local UNcommitted change to a DIFFERENT file -> stash pops cleanly.
  printf 'sandbox scratch\n' >> "$CLONE/README.md"
  run_tui
}

cmd_c() {
  require_sandbox
  reset_to_base
  printf 'UPSTREAM\n' > "$CLONE/conflict.txt"
  git -C "$CLONE" add conflict.txt
  push_upstream_commit "upstream: conflict.txt"
  # Local COMMITTED change to the same file -> real merge conflict.
  printf 'LOCAL\n' > "$CLONE/conflict.txt"
  git -C "$CLONE" add conflict.txt
  git -C "$CLONE" commit -q -m "local: conflict.txt"
  run_tui
}

cmd_d() {
  require_sandbox
  reset_to_base
  printf 'UPSTREAM\n' > "$CLONE/conflict.txt"
  git -C "$CLONE" add conflict.txt
  push_upstream_commit "upstream: conflict.txt"
  # Local UNcommitted change to the same file -> stash pop conflicts.
  printf 'LOCAL\n' > "$CLONE/conflict.txt"
  run_tui
}

cmd_apply_dotfiles() {
  require_sandbox
  reset_to_base
  seed_pending_change dotfiles config/hypr/hyprland.conf
  run_tui_fakehome
  echo
  echo "Result — these should be symlinks pointing into the clone:"
  ls -l "$FAKEHOME/.config/hypr/hyprland.conf" 2>/dev/null
  echo "Baseline now equals clone HEAD?"
  echo "  baseline: $(cat "$CLONE/config/hyprkarl/update/dotfiles.commit" 2>/dev/null)"
  echo "  HEAD:     $(git -C "$CLONE" rev-parse HEAD)"
}

cmd_apply_dotfiles_conflict() {
  require_sandbox
  reset_to_base
  seed_pending_change dotfiles config/hypr/hyprland.conf
  run_tui_fakehome plant_stow_conflict
  echo
  echo "After 'Keep repo versions': the file below should be a symlink again."
  echo "After 'Adopt my versions':  the clone repo is now dirty (git -C $CLONE status)."
  ls -l "$FAKEHOME/.config/hypr/hyprland.conf" 2>/dev/null
}

cmd_apply_packages() {
  require_sandbox
  reset_to_base
  seed_pending_change packages packages/pacman.txt
  echo
  echo "############################################################"
  echo " This will install the REAL 'sl' package (10 KB, no deps)"
  echo " via sudo when you confirm at the Apply step. Select only"
  echo " 'Packages'. Undo afterwards with: $0 apply-packages-cleanup"
  echo "############################################################"
  run_tui
  echo
  echo "Installed?"; pacman -Q sl 2>/dev/null || echo "  sl not installed (you may have skipped)"
}

cmd_apply_packages_cleanup() {
  if pacman -Q sl >/dev/null 2>&1; then
    sudo pacman -Rns --noconfirm sl && echo "Removed sl."
  else
    echo "sl is not installed; nothing to clean up."
  fi
}

cmd_status() {
  require_sandbox
  echo "Sandbox: $CLONE (branch: $BRANCH, base: ${BASE:0:9})"
  echo "--- behind/ahead vs origin/$BRANCH ---"
  git -C "$CLONE" rev-list --left-right --count "HEAD...origin/$BRANCH" \
    | awk '{print "ahead: "$1"   behind: "$2}'
  echo "--- working tree ---"
  git -C "$CLONE" status --short
}

cmd_clean() {
  rm -rf "$WORK"
  echo "Removed $WORK"
}

case "${1:-}" in
  setup)  cmd_setup ;;
  a)      cmd_a ;;
  b)      cmd_b ;;
  c)      cmd_c ;;
  d)      cmd_d ;;
  apply-dotfiles)          cmd_apply_dotfiles ;;
  apply-dotfiles-conflict) cmd_apply_dotfiles_conflict ;;
  apply-packages)          cmd_apply_packages ;;
  apply-packages-cleanup)  cmd_apply_packages_cleanup ;;
  status) cmd_status ;;
  clean)  cmd_clean ;;
  *)
    grep '^#' "$0" | sed 's/^# \{0,1\}//'
    exit 1 ;;
esac
