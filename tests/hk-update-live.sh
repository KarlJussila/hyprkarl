#!/bin/bash
# tests/hk-update-live.sh
# Live update stress tests against your REAL hyprkarl install.
#
# Unlike the sandbox harness, these touch your actual ~/.config, install real
# packages, and check out real old commits.  There is no isolation.  The point
# is to hit code paths that only emerge against a real stow state and real
# git history.
#
# Recovery: `tests/hk-update-live.sh reset` returns to HEAD and re-stows.
# You can always recover manually with:
#   git -C ~/.local/share/hyprkarl checkout main
#   ~/.local/share/hyprkarl/setup-dotfiles.sh
#
# Usage:
#   tests/hk-update-live.sh status           show baselines, HEAD, waybar state
#   tests/hk-update-live.sh reset            return to HEAD + re-stow
#   tests/hk-update-live.sh <scenario>
#
# Scenarios:
#
#   A  no-baseline
#      Deletes all .commit files; runs hk-update check, then dotfiles, then
#      packages — exercising the complete "first time hk-update runs on a
#      stowed system" path.  No checkout.
#
#   B  stale-waybar
#      Checks out d97bf78^ (waybar still in config/), stows it so
#      ~/.config/waybar/ gets real symlinks, then advances to d97bf78 where
#      config/waybar/ is deleted.  Runs hk-update dotfiles and verifies the
#      broken symlinks are pruned.  Ends on d97bf78 — run reset afterward.
#      CAUTION: re-stows the old config (some current-HEAD files will be
#      absent until reset).
#
#   C  long-hop
#      Writes the 124964f SHA (first hk-update commit, ~3 weeks before HEAD)
#      as the packages baseline, then runs hk-update check and hk-update
#      packages from current HEAD.  Exercises the multi-version package diff:
#      ~20 packages to add, waybar to prompt for removal, libastal-* AUR adds.
#      No checkout.  Interactive: gum will prompt for waybar removal if waybar
#      is installed.
#
#   D  invalid-baseline
#      Writes a nonexistent SHA to packages.commit and dotfiles.commit, runs
#      hk-update check then packages.  Exercises the "baseline not in git
#      history" fallback path (force-push simulation, shallow clone, etc.).
#      No checkout.
#
#   E  conflict
#      Removes ~/.config/hypr/hyprland.conf (currently a symlink), plants a
#      real file in its place, then runs hk-update dotfiles (expected: error)
#      followed by hk-update dotfiles --force (expected: symlink restored).
#      No checkout.

HK="$HOME/.local/share/hyprkarl"

# SHA constants for key milestone commits
COMMIT_FIRST_UPDATE="124964f"   # Added update helper scripts
COMMIT_PRE_WAYBAR="d97bf78^"    # Just before waybar removed (waybar still in config/)
COMMIT_WAYBAR_GONE="d97bf78"    # Removed waybar, replaced with AGS bar
COMMIT_FAKE="deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"

banner() { printf '\n=== %s ===\n' "$1"; }
ok()     { printf '  ok  %s\n' "$1"; }
bad()    { printf '  BAD %s\n' "$1"; }
note()   { printf '  --  %s\n' "$1"; }

verify_symlink() {
  local path="$1"
  if [[ -L "$path" ]] && [[ -e "$path" ]]; then
    ok "$path is a valid symlink -> $(readlink "$path" | sed "s|$HK|HK|")"
  elif [[ -L "$path" ]]; then
    bad "$path is a BROKEN symlink -> $(readlink "$path")"
  elif [[ -e "$path" ]]; then
    bad "$path is a regular file, not a symlink"
  else
    bad "$path does not exist"
  fi
}

verify_gone() {
  local path="$1"
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    ok "$path removed"
  else
    bad "$path still exists: $(ls -la "$path" 2>/dev/null)"
  fi
}

verify_baseline() {
  local type="$1" head expected actual
  head=$(git -C "$HK" rev-parse HEAD 2>/dev/null)
  actual=$(cat "$HK/config/hyprkarl/update/$type.commit" 2>/dev/null || printf '(missing)')
  if [[ "$actual" == "$head" ]]; then
    ok "$type baseline == HEAD (${actual:0:9})"
  elif [[ -z "$actual" || "$actual" == "(missing)" ]]; then
    note "$type baseline: (none)"
  else
    note "$type baseline: ${actual:0:9} (HEAD is ${head:0:9})"
  fi
}

write_baseline() {
  # write_baseline <type> <sha>
  local type="$1" sha="$2"
  mkdir -p "$HK/config/hyprkarl/update"
  printf '%s\n' "$sha" > "$HK/config/hyprkarl/update/$type.commit"
}

# ─── status / reset ───────────────────────────────────────────────────────

cmd_status() {
  printf 'HEAD:  %s\n' "$(git -C "$HK" log --oneline -1 --no-decorate 2>/dev/null)"
  printf 'Branch/detached: %s\n' "$(git -C "$HK" branch --show-current 2>/dev/null || echo "(detached)")"
  printf '\nBaseline .commit files:\n'
  for t in dotfiles packages system; do
    local f="$HK/config/hyprkarl/update/$t.commit"
    if [[ -f "$f" ]]; then
      printf '  %s: %s  (%s)\n' "$t" "$(head -c9 "$f")" \
        "$(git -C "$HK" log --oneline -1 --no-decorate "$(cat "$f")" 2>/dev/null || echo "not in history")"
    else
      printf '  %s: (none)\n' "$t"
    fi
  done
  printf '\nwaybar in ~/.config:\n'
  if ls "$HOME/.config/waybar/" &>/dev/null; then
    ls -la "$HOME/.config/waybar/"
  else
    printf '  (no ~/.config/waybar/)\n'
  fi
  printf '\nGit working tree:\n'
  git -C "$HK" status --short | sed 's/^/  /' || true
}

cmd_reset() {
  banner "reset"
  printf 'Returning to HEAD (main) and re-stowing...\n'
  git -C "$HK" checkout main || {
    printf 'ERROR: git checkout main failed. Resolve manually.\n' >&2; exit 1
  }
  "$HK/setup-dotfiles.sh"
  printf '\nDone. Current state:\n'
  cmd_status
}

# ─── Scenario A: no-baseline ──────────────────────────────────────────────

cmd_no_baseline() {
  banner "A: no-baseline"
  cat <<'EOF'
Scenario: .commit files don't exist — simulates running hk-update for the
first time on an install that predates hk-update tracking.

Steps:
  1. Delete all .commit files
  2. hk-update check  → should report "No baseline recorded" for all sections
  3. hk-update dotfiles → restow + write dotfiles baseline
  4. hk-update packages → install any missing required packages + write baseline

No checkout. This leaves baselines set to HEAD when done.
EOF
  printf '\nPress Enter to begin, Ctrl-C to cancel.\n'; read -r

  printf '\n[1] Removing .commit files...\n'
  rm -f "$HK/config/hyprkarl/update/"{dotfiles,packages,system}".commit"
  verify_gone "$HK/config/hyprkarl/update/dotfiles.commit"

  printf '\n[2] hk-update check (expect: No baseline recorded for all)\n\n'
  hk-update check

  printf '\n[3] hk-update dotfiles\n\n'
  hk-update dotfiles

  printf '\n[4] hk-update packages\n\n'
  hk-update packages

  printf '\nVerification:\n'
  verify_baseline dotfiles
  verify_baseline packages
  verify_symlink "$HOME/.config/hypr/hyprland.conf"
}

# ─── Scenario B: stale-waybar ─────────────────────────────────────────────

cmd_stale_waybar() {
  banner "B: stale-waybar"
  cat <<'EOF'
Scenario: config files deleted upstream leave broken symlinks in ~/.config.

Steps:
  1. Checkout d97bf78^ (waybar still in config/waybar/)
  2. setup-dotfiles.sh → stow everything including waybar
  3. Verify ~/.config/waybar/ has live symlinks
  4. Advance to d97bf78 (config/waybar/ deleted upstream)
  5. Confirm ~/.config/waybar/ symlinks are now broken
  6. Set dotfiles baseline to d97bf78^ so hk-update sees the diff
  7. hk-update dotfiles → restow + remove_stale_symlinks
  8. Verify ~/.config/waybar/ is gone

CAUTION: This re-stows the old config. Some current-HEAD config files will
be absent from ~/.config until you run reset. Hyprland won't crash but some
bar/widget configs will reflect the older state.
EOF
  printf '\nPress Enter to begin, Ctrl-C to cancel.\n'; read -r

  printf '\n[1] Checking out %s (waybar still in config/)...\n' "$COMMIT_PRE_WAYBAR"
  git -C "$HK" checkout -f "$COMMIT_PRE_WAYBAR"

  printf '\n[2] setup-dotfiles.sh (stows old config including config/waybar/)...\n'
  "$HK/setup-dotfiles.sh"

  printf '\n[3] Verify ~/.config/waybar/ has live symlinks:\n'
  if find "$HOME/.config/waybar/" -maxdepth 1 -type l 2>/dev/null | grep -q .; then
    ok "~/.config/waybar/ symlinks exist"
    ls -la "$HOME/.config/waybar/" | sed 's/^/    /'
  else
    bad "~/.config/waybar/ not found or has no symlinks — setup may have failed"
  fi

  printf '\n[4] Advancing to %s (config/waybar/ deleted)...\n' "$COMMIT_WAYBAR_GONE"
  # Reset the .commit file change that setup-dotfiles.sh made so git can advance cleanly
  git -C "$HK" checkout -- config/hyprkarl/update/ 2>/dev/null || true
  git -C "$HK" checkout -f "$COMMIT_WAYBAR_GONE"

  printf '\n[5] Confirm waybar symlinks are now broken:\n'
  local broken=0
  while IFS= read -r link; do
    if [[ ! -e "$link" ]] && [[ "$(readlink "$link")" == *"hyprkarl"* ]]; then
      note "broken: $link -> $(readlink "$link")"
      broken=1
    fi
  done < <(find "$HOME/.config/waybar" -type l 2>/dev/null)
  if [[ "$broken" -eq 0 ]]; then
    note "No broken waybar symlinks found — they may have already been removed"
  fi

  printf '\n[6] Setting dotfiles baseline to d97bf78^ (so hk-update sees the transition)...\n'
  local pre_sha
  pre_sha=$(git -C "$HK" rev-parse "$COMMIT_WAYBAR_GONE^")
  write_baseline dotfiles "$pre_sha"
  note "dotfiles baseline: ${pre_sha:0:9}"

  printf '\n[7] hk-update dotfiles (should restow + remove broken waybar symlinks)...\n\n'
  hk-update dotfiles

  printf '\n[8] Verify waybar symlinks removed:\n'
  if ls "$HOME/.config/waybar/" 2>/dev/null | grep -q .; then
    bad "~/.config/waybar/ still has content:"
    ls -la "$HOME/.config/waybar/" | sed 's/^/    /'
  else
    ok "~/.config/waybar/ is empty or gone"
  fi

  printf '\n'
  verify_baseline dotfiles

  printf '\nDone. System is at %s with old config stowed.\n' "$COMMIT_WAYBAR_GONE"
  printf 'Run: tests/hk-update-live.sh reset\n'
}

# ─── Scenario C: long-hop ─────────────────────────────────────────────────

cmd_long_hop() {
  banner "C: long-hop"
  local first_sha
  first_sha=$(git -C "$HK" rev-parse "$COMMIT_FIRST_UPDATE")
  cat <<'EOF'
Scenario: user last ran hk-update at 124964f (first hk-update commit, before
the waybar→AGS migration, before ~20 packages were added).  Baseline is valid
but far behind HEAD.

Steps:
  1. Write 124964f as the packages baseline
  2. hk-update check → shows full diff: many packages to add, waybar to remove
  3. hk-update packages → installs missing packages, prompts for waybar

Interactive: gum will ask to remove 'waybar' if it's installed on your system.
No checkout. When done, baselines are at HEAD.
EOF
  printf '\nPress Enter to begin, Ctrl-C to cancel.\n'; read -r

  printf '\n[1] Writing packages baseline to 124964f (%s)...\n' "${first_sha:0:9}"
  write_baseline packages "$first_sha"
  note "baseline points to: $(git -C "$HK" log --oneline -1 --no-decorate "$first_sha")"

  printf '\n[2] hk-update check (expect: many packages to add, waybar to remove)...\n\n'
  hk-update check

  printf '\n[3] hk-update packages (interactive if waybar is installed)...\n\n'
  hk-update packages

  printf '\nVerification:\n'
  verify_baseline packages
  printf '\nNote: waybar should appear exactly ONCE in any removal prompts.\n'
  printf 'If it appeared twice (once as "No longer required", once from remove.txt),\n'
  printf 'the deduplication fix in hk-update-packages is not in effect.\n'
}

# ─── Scenario D: invalid-baseline ─────────────────────────────────────────

cmd_invalid_baseline() {
  banner "D: invalid-baseline"
  cat <<'EOF'
Scenario: .commit files contain a SHA that doesn't exist in git history.
Could happen after a force-push, a rebase, or cloning from a shallow repo
that later got more history pruned.

Steps:
  1. Write a fake SHA to dotfiles.commit and packages.commit
  2. hk-update check  → should warn "baseline not in git history" for both
                         dotfiles and packages sections
  3. hk-update packages → falls back to no-baseline path (installs all missing)
  4. hk-update dotfiles → restows + writes new baseline

No checkout.
EOF
  printf '\nPress Enter to begin, Ctrl-C to cancel.\n'; read -r

  printf '\n[1] Writing invalid SHA to dotfiles.commit and packages.commit...\n'
  write_baseline dotfiles "$COMMIT_FAKE"
  write_baseline packages "$COMMIT_FAKE"
  note "dotfiles.commit: ${COMMIT_FAKE:0:9} (does not exist)"
  note "packages.commit: ${COMMIT_FAKE:0:9} (does not exist)"

  printf '\n[2] hk-update check...\n\n'
  hk-update check

  printf '\n[3] hk-update packages (expect: warning + fallback to no-baseline path)...\n\n'
  hk-update packages

  printf '\n[4] hk-update dotfiles (observe behavior with invalid baseline SHA)...\n\n'
  hk-update dotfiles

  printf '\nVerification:\n'
  verify_baseline dotfiles
  verify_baseline packages
}

# ─── Scenario E: conflict ─────────────────────────────────────────────────

cmd_conflict() {
  banner "E: conflict"
  local target="$HOME/.config/hypr/hyprland.conf"
  cat <<'EOF'
Scenario: a real file exists where stow wants to create a symlink — the
"user has locally edited a tracked config file" case.  Tests that conflict
detection fires, and that --force cleanly resolves it.

Steps:
  1. Remove the current hyprland.conf symlink, plant a real file
  2. hk-update dotfiles     → should fail with conflict error
  3. hk-update dotfiles --force → should overwrite the real file with symlink
  4. Verify hyprland.conf is a valid symlink again

No checkout.
EOF

  # --force requires a clean config/ working tree; warn early if it isn't.
  local dirty
  dirty=$(git -C "$HK" diff --name-only HEAD -- config/ applications/ 2>/dev/null)
  if [[ -n "$dirty" ]]; then
    printf '\nWARNING: uncommitted changes in config/ — hk-update dotfiles --force will\n'
    printf 'refuse to run until they are committed or stashed.  Dirty files:\n'
    printf '%s\n' "$dirty" | sed 's/^/  /'
    printf '\nStash with: git -C %s stash\n' "$HK"
    printf 'Continue anyway? (y/N) '; read -r yn
    [[ "$yn" == [yY] ]] || { printf 'Cancelled.\n'; return 0; }
  fi

  printf '\nPress Enter to begin, Ctrl-C to cancel.\n'; read -r

  printf '\n[1] Current state of hyprland.conf:\n'
  ls -la "$target" 2>/dev/null | sed 's/^/  /'
  printf '\nReplacing symlink with a real file...\n'
  rm -f "$target"
  printf '# local edit — should be overwritten by --force\n' > "$target"
  ls -la "$target" | sed 's/^/  /'

  printf '\n[2] hk-update dotfiles (expect: conflict error, exit 1)...\n\n'
  hk-update dotfiles
  local rc=$?
  printf '\nExit code: %d\n' "$rc"
  if [[ "$rc" -ne 0 ]]; then
    ok "exited non-zero as expected"
  else
    bad "exited 0 — conflict was not detected"
  fi
  printf 'File is still a real file? '
  if [[ ! -L "$target" ]]; then
    ok "(yes, symlink not yet restored)"
  else
    bad "(no — already a symlink before --force ran)"
  fi

  printf '\n[3] hk-update dotfiles --force (expect: symlink restored, exit 0)...\n\n'
  hk-update dotfiles --force
  local rc2=$?
  printf '\nExit code: %d\n' "$rc2"

  printf '\n[4] Verification:\n'
  if [[ "$rc2" -eq 0 ]]; then
    ok "exited 0"
  else
    bad "exited non-zero"
  fi
  verify_symlink "$target"
  verify_baseline dotfiles
}

# ─── dispatch ─────────────────────────────────────────────────────────────

case "${1:-}" in
  reset)           cmd_reset ;;
  status)          cmd_status ;;
  no-baseline|A)   cmd_no_baseline ;;
  stale-waybar|B)  cmd_stale_waybar ;;
  long-hop|C)      cmd_long_hop ;;
  invalid-baseline|D) cmd_invalid_baseline ;;
  conflict|E)      cmd_conflict ;;
  *)
    grep '^#' "$0" | sed 's/^# \{0,1\}//'
    exit 1 ;;
esac
