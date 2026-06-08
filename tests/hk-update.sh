#!/bin/bash
# tests/hk-update.sh
# Manual sandbox harness for exercising hk-update-* commands without touching
# your real repo, ~/.config, or system packages.
#
# Isolation:
#  - HYPRKARL_PATH points to a throwaway clone at /tmp/hk-update-test/hyprkarl.
#    The clone path contains "hyprkarl" so stale-link detection works as in prod.
#  - Dotfiles tests redirect $HOME to a fake dir; real ~/.config is never touched.
#  - Packages tests inject mock hk-pkg-install / hk-pkg-install-aur / hk-pkg-remove
#    via PATH (these print "DRY RUN" instead of running pacman). Two *-real scenarios
#    install/uninstall the inconsequential 'sl' package without mocking.
#  - All hk-update-* scripts run from your working tree so uncommitted changes
#    are tested live.
#
# Usage:
#   tests/hk-update.sh setup                 build the sandbox (run once)
#   tests/hk-update.sh reset                 reset sandbox to clean state
#   tests/hk-update.sh status                show sandbox state
#   tests/hk-update.sh clean                 remove sandbox
#   tests/hk-update.sh <scenario>            run one scenario
#
# Check scenarios (read-only, no $HOME redirect):
#   check-no-baseline        hk-update check with no .commit files (pre-hk-update)
#   check-uptodate           hk-update check when all baselines equal HEAD
#   check-pending            hk-update check with pending dotfiles + package changes
#   check-invalid-baseline   hk-update check when .commit SHA not in git history
#
# Dotfiles scenarios ($HOME redirected to fake dir):
#   dotfiles-clean           normal restow, no conflicts; verifies symlinks + baseline
#   dotfiles-conflict        real file at stow target -> exits error
#   dotfiles-force           --force overwrites the conflicting file
#   dotfiles-force-dirty     --force with uncommitted config change in clone -> error
#   dotfiles-adopt           --adopt absorbs a user-modified file into the repo
#   dotfiles-adopt-clean     --adopt when user file matches repo -> no-change path
#   dotfiles-stale           broken hyprkarl symlink removed during update
#
# Remove-stale scenario:
#   remove-stale             two stale symlinks removed; valid symlinks preserved
#
# Packages scenarios (mock installer unless stated):
#   packages-uptodate        baseline == HEAD -> "already up to date", no pacman
#   packages-no-baseline     no .commit file -> installs all required pkgs (mock)
#   packages-added           new package in list since baseline (mock)
#   packages-invalid-baseline SHA not in history -> falls back to no-baseline path (mock)
#   packages-removed         interactive: package dropped from list, removal prompt
#                            (hk-pkg-remove is mocked so "Yes" is safe)
#   packages-remove-txt      interactive: package added to remove.txt, removal prompt
#                            (hk-pkg-remove is mocked so "Yes" is safe)
#   packages-real            REAL: installs 'sl' (10 KB, no deps) via sudo
#   packages-real-cleanup    REAL: removes 'sl'

ORIG=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
WORK="/tmp/hk-update-test"
CLONE="$WORK/hyprkarl"    # must contain 'hyprkarl' — stale-link detection checks this
FAKEHOME="$WORK/home"
MOCKBIN="$WORK/mockbin"
BASE_FILE="$WORK/base-sha"

# ─── core helpers ─────────────────────────────────────────────────────────

require_sandbox() {
  if [[ ! -d "$CLONE/.git" ]]; then
    printf 'No sandbox. Run: %s setup\n' "$0" >&2; exit 1
  fi
}

reset_sandbox() {
  require_sandbox
  git -C "$CLONE" reset --hard "$(cat "$BASE_FILE")" -q
  git -C "$CLONE" clean -fd -q
  reset_fakehome
}

reset_fakehome() {
  rm -rf "$FAKEHOME"
  mkdir -p "$FAKEHOME/.config" \
           "$FAKEHOME/.local/share/applications" \
           "$FAKEHOME/.local/share/themes/hyprkarl"
}

remove_baselines() {
  rm -f "$CLONE/config/hyprkarl/update/"{dotfiles,packages,system}".commit"
}

set_baselines_to_head() {
  local head
  head=$(git -C "$CLONE" rev-parse HEAD)
  mkdir -p "$CLONE/config/hyprkarl/update"
  for t in dotfiles packages system; do
    printf '%s\n' "$head" > "$CLONE/config/hyprkarl/update/$t.commit"
  done
}

write_invalid_baseline() {
  # Write a SHA that does not exist in git history.
  mkdir -p "$CLONE/config/hyprkarl/update"
  for t in "$@"; do
    printf 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef\n' \
      > "$CLONE/config/hyprkarl/update/$t.commit"
  done
}

seed_dotfiles_change() {
  # Add a comment to hyprland.conf, commit, set dotfiles baseline to HEAD~1
  printf '\n# test: seed_dotfiles_change\n' >> "$CLONE/config/hypr/hyprland.conf"
  git -C "$CLONE" commit -q -am "test: dotfiles change"
  git -C "$CLONE" rev-parse HEAD~1 > "$CLONE/config/hyprkarl/update/dotfiles.commit"
}

seed_packages_add() {
  # Add 'sl' to pacman.txt, commit, set packages baseline to HEAD~1.
  # 'sl' may or may not be installed — no interactive prompt if not installed.
  printf 'sl\n' >> "$CLONE/packages/pacman.txt"
  git -C "$CLONE" commit -q -am "test: add sl to packages"
  git -C "$CLONE" rev-parse HEAD~1 > "$CLONE/config/hyprkarl/update/packages.commit"
}

seed_packages_drop() {
  # Drop 'stow' from the list since the baseline. stow IS installed on this
  # machine, so hk-update-packages will hit the gum confirm removal prompt.
  # hk-pkg-remove is mocked so "Yes" is harmless.
  sed -i '/^stow[[:space:]]*$/d; /^stow[[:space:]]*#/d' "$CLONE/packages/pacman.txt"
  git -C "$CLONE" commit -q -am "test: drop stow from packages"
  git -C "$CLONE" rev-parse HEAD~1 > "$CLONE/config/hyprkarl/update/packages.commit"
}

seed_remove_txt_add() {
  # Add 'stow' to remove.txt since the baseline.
  printf 'stow  # test: replaced by something-better\n' >> "$CLONE/packages/remove.txt"
  git -C "$CLONE" commit -q -am "test: add stow to remove.txt"
  git -C "$CLONE" rev-parse HEAD~1 > "$CLONE/config/hyprkarl/update/packages.commit"
}

plant_stow_conflict() {
  # Place a real file where stow wants to create a symlink.
  mkdir -p "$FAKEHOME/.config/hypr"
  printf '# my hand-edited local file\n' > "$FAKEHOME/.config/hypr/hyprland.conf"
}

# ─── run wrappers ─────────────────────────────────────────────────────────

run_check() {
  HYPRKARL_PATH="$CLONE" PATH="$ORIG/bin:$PATH" hk-update check
}

run_dotfiles() {
  HOME="$FAKEHOME" HYPRKARL_PATH="$CLONE" PATH="$ORIG/bin:$PATH" hk-update-dotfiles "$@"
}

run_packages_mock() {
  HOME="$FAKEHOME" HYPRKARL_PATH="$CLONE" \
    PATH="$MOCKBIN:$ORIG/bin:$PATH" hk-update-packages
}

run_packages_real() {
  HYPRKARL_PATH="$CLONE" PATH="$ORIG/bin:$PATH" hk-update-packages
}

run_remove_stale() {
  HOME="$FAKEHOME" HYPRKARL_PATH="$CLONE" PATH="$ORIG/bin:$PATH" hk-update-remove-stale
}

# ─── verification helpers ─────────────────────────────────────────────────

verify_baseline() {
  local type="$1" expected actual
  expected=$(git -C "$CLONE" rev-parse HEAD)
  actual=$(cat "$CLONE/config/hyprkarl/update/$type.commit" 2>/dev/null || printf '(missing)')
  if [[ "$actual" == "$expected" ]]; then
    printf '  ok  %s baseline == HEAD (%.9s)\n' "$type" "$actual"
  else
    printf '  BAD %s baseline: got %.9s, expected HEAD (%.9s)\n' \
      "$type" "$actual" "$expected"
  fi
}

verify_no_baseline() {
  local type="$1"
  if [[ ! -f "$CLONE/config/hyprkarl/update/$type.commit" ]]; then
    printf '  ok  %s has no baseline\n' "$type"
  else
    printf '  BAD %s still has a baseline\n' "$type"
  fi
}

verify_symlink() {
  local path="$1"
  if [[ -L "$path" ]]; then
    printf '  ok  %s -> %s\n' "$path" "$(readlink "$path")"
  elif [[ -e "$path" ]]; then
    printf '  BAD %s is a regular file, not a symlink\n' "$path"
  else
    printf '  BAD %s is missing\n' "$path"
  fi
}

verify_gone() {
  local path="$1"
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    printf '  ok  %s removed\n' "$path"
  else
    printf '  BAD %s still exists\n' "$path"
  fi
}

verify_exit() {
  local code="$1" expected="$2"
  if [[ "$code" -eq "$expected" ]]; then
    printf '  ok  exit code = %d\n' "$code"
  else
    printf '  BAD exit code %d, expected %d\n' "$code" "$expected"
  fi
}

banner() {
  printf '\n=== %s ===\n' "$1"
}

# ─── setup / teardown ─────────────────────────────────────────────────────

cmd_setup() {
  rm -rf "$WORK"; mkdir -p "$WORK"
  git clone -q "$ORIG" "$CLONE"
  git -C "$CLONE" config user.email test@example.com
  git -C "$CLONE" config user.name "Update Test"
  git -C "$CLONE" rev-parse HEAD > "$BASE_FILE"

  mkdir -p "$MOCKBIN"
  for cmd in hk-pkg-install hk-pkg-install-aur hk-pkg-remove; do
    printf '#!/bin/bash\nprintf "[DRY RUN] %s %%s\\n" "$*"\n' "$cmd" \
      > "$MOCKBIN/$cmd"
    chmod +x "$MOCKBIN/$cmd"
  done

  reset_fakehome
  printf 'Sandbox ready.\n'
  printf '  clone:    %s\n' "$CLONE"
  printf '  fakehome: %s\n' "$FAKEHOME"
  printf '  mockbin:  %s\n' "$MOCKBIN"
}

cmd_clean() {
  rm -rf "$WORK"
  printf 'Removed %s\n' "$WORK"
}

cmd_status() {
  require_sandbox
  printf 'clone:    %s\n' "$CLONE"
  printf 'HEAD:     %s\n' "$(git -C "$CLONE" log --oneline -1 --no-decorate)"
  printf 'base:     %.9s\n' "$(cat "$BASE_FILE")"
  printf '\nbaseline commits:\n'
  for t in dotfiles packages system; do
    local f="$CLONE/config/hyprkarl/update/$t.commit"
    if [[ -f "$f" ]]; then
      printf '  %s: %.9s\n' "$t" "$(cat "$f")"
    else
      printf '  %s: (none)\n' "$t"
    fi
  done
  printf '\nworking tree:\n'
  git -C "$CLONE" status --short
}

# ─── check scenarios ──────────────────────────────────────────────────────

cmd_check_no_baseline() {
  banner "check-no-baseline"
  printf 'Scenario: pre-hk-update system — no .commit files exist.\n'
  printf 'Expected: "No baseline recorded" for all three sections.\n\n'
  reset_sandbox
  remove_baselines
  run_check
}

cmd_check_uptodate() {
  banner "check-uptodate"
  printf 'Scenario: all baselines == HEAD.\n'
  printf 'Expected: "Up to date." for all three sections.\n\n'
  reset_sandbox
  set_baselines_to_head
  run_check
}

cmd_check_pending() {
  banner "check-pending"
  printf 'Scenario: dotfiles + packages changed since last baseline.\n'
  printf 'Expected: lists changed config files and new packages to install.\n\n'
  reset_sandbox
  seed_dotfiles_change
  seed_packages_add
  run_check
}

cmd_check_invalid_baseline() {
  banner "check-invalid-baseline"
  printf 'Scenario: .commit files contain a SHA not in git history.\n'
  printf 'Expected: packages warns about invalid baseline and falls back to\n'
  printf '          missing-package scan; dotfiles/system show stale baseline.\n\n'
  reset_sandbox
  write_invalid_baseline dotfiles packages system
  run_check
}

# ─── dotfiles scenarios ───────────────────────────────────────────────────

cmd_dotfiles_clean() {
  banner "dotfiles-clean"
  printf 'Scenario: dotfiles pending since last baseline, no conflicts.\n'
  printf 'Expected: symlinks created in fakehome, dotfiles baseline written to HEAD.\n\n'
  reset_sandbox
  seed_dotfiles_change
  run_dotfiles; local rc=$?
  printf '\nVerification:\n'
  verify_exit "$rc" 0
  verify_symlink "$FAKEHOME/.config/hypr/hyprland.conf"
  verify_baseline dotfiles
}

cmd_dotfiles_conflict() {
  banner "dotfiles-conflict"
  printf 'Scenario: a real file sits where stow wants to create a symlink.\n'
  printf 'Expected: exits 1, prints conflict list.\n\n'
  reset_sandbox
  seed_dotfiles_change
  plant_stow_conflict
  run_dotfiles; local rc=$?
  printf '\nVerification:\n'
  verify_exit "$rc" 1
  printf '  (hyprland.conf should still be a regular file:)\n'
  ls -la "$FAKEHOME/.config/hypr/hyprland.conf" 2>/dev/null | sed 's/^/  /'
}

cmd_dotfiles_force() {
  banner "dotfiles-force"
  printf 'Scenario: same conflict, resolved with --force (overwrites real file).\n'
  printf 'Expected: exits 0, target becomes a symlink, baseline updated.\n\n'
  reset_sandbox
  seed_dotfiles_change
  plant_stow_conflict
  run_dotfiles --force; local rc=$?
  printf '\nVerification:\n'
  verify_exit "$rc" 0
  verify_symlink "$FAKEHOME/.config/hypr/hyprland.conf"
  verify_baseline dotfiles
}

cmd_dotfiles_force_dirty() {
  banner "dotfiles-force-dirty"
  printf 'Scenario: --force requested but clone has uncommitted changes in config/.\n'
  printf 'Expected: exits 1, warns about uncommitted changes, leaves tree dirty.\n\n'
  reset_sandbox
  seed_dotfiles_change
  plant_stow_conflict
  # Add an uncommitted change to the clone's config (on top of the test commit)
  printf '# dirty sandbox change\n' >> "$CLONE/config/hypr/hyprland.conf"
  run_dotfiles --force; local rc=$?
  printf '\nVerification:\n'
  verify_exit "$rc" 1
  printf '  (clone working tree should be dirty:)\n'
  git -C "$CLONE" status --short -- config/ | sed 's/^/  /'
}

cmd_dotfiles_adopt() {
  banner "dotfiles-adopt"
  printf 'Scenario: user has a modified real file; --adopt absorbs it into the repo.\n'
  printf 'Expected: exits 0; git diff shows the adopted content differs from repo.\n\n'
  reset_sandbox
  seed_dotfiles_change
  plant_stow_conflict  # plants hyprland.conf with content different from repo
  run_dotfiles --adopt; local rc=$?
  printf '\nVerification:\n'
  verify_exit "$rc" 0
  printf '  Adopted files (clone git diff HEAD -- config/):\n'
  git -C "$CLONE" diff --name-only HEAD -- config/ applications/ | sed 's/^/    /'
  printf '  (config/hypr/hyprland.conf should appear above)\n'
}

cmd_dotfiles_adopt_clean() {
  banner "dotfiles-adopt-clean"
  printf 'Scenario: user file has identical content to repo — adopt finds no differences.\n'
  printf 'Expected: "No conflicts found — all files already matched the repo."\n'
  printf '          Baseline written to HEAD.\n\n'
  reset_sandbox
  seed_dotfiles_change
  # Plant a conflict file with IDENTICAL content to the clone's version
  mkdir -p "$FAKEHOME/.config/hypr"
  cat "$CLONE/config/hypr/hyprland.conf" > "$FAKEHOME/.config/hypr/hyprland.conf"
  run_dotfiles --adopt; local rc=$?
  printf '\nVerification:\n'
  verify_exit "$rc" 0
  verify_baseline dotfiles
  printf '  git diff should be empty:\n'
  local diff_out
  diff_out=$(git -C "$CLONE" diff --name-only HEAD -- config/ applications/)
  if [[ -z "$diff_out" ]]; then
    printf '    ok  (no diff)\n'
  else
    printf '    BAD diff found:\n'
    printf '%s\n' "$diff_out" | sed 's/^/      /'
  fi
}

cmd_dotfiles_stale() {
  banner "dotfiles-stale"
  printf 'Scenario: a broken symlink pointing into the hyprkarl clone exists.\n'
  printf 'Expected: stale symlink removed; real symlinks survive; baseline updated.\n\n'
  reset_sandbox
  seed_dotfiles_change
  # Pre-stow to create real symlinks
  HOME="$FAKEHOME" HYPRKARL_PATH="$CLONE" \
    stow --restow --no-folding --ignore='@girs' --ignore='node_modules' \
      --dir="$CLONE" --target="$FAKEHOME/.config" config 2>/dev/null || true
  # Plant a broken symlink pointing to a nonexistent file in the clone
  ln -sf "$CLONE/config/hypr/nonexistent.conf" \
    "$FAKEHOME/.config/hypr/stale-test.conf"
  printf '  Planted stale link: %s\n' "$FAKEHOME/.config/hypr/stale-test.conf"
  run_dotfiles; local rc=$?
  printf '\nVerification:\n'
  verify_exit "$rc" 0
  verify_gone "$FAKEHOME/.config/hypr/stale-test.conf"
  verify_symlink "$FAKEHOME/.config/hypr/hyprland.conf"
  verify_baseline dotfiles
}

# ─── remove-stale scenario ────────────────────────────────────────────────

cmd_remove_stale() {
  banner "remove-stale"
  printf 'Scenario: two broken symlinks pointing into the hyprkarl clone path.\n'
  printf 'Expected: both removed; valid symlinks and real files are preserved.\n\n'
  reset_sandbox
  # Stow to produce real symlinks first (they should survive)
  HOME="$FAKEHOME" HYPRKARL_PATH="$CLONE" \
    stow --restow --no-folding --ignore='@girs' --ignore='node_modules' \
      --dir="$CLONE" --target="$FAKEHOME/.config" config 2>/dev/null || true
  # Plant two broken symlinks into the clone path
  ln -sf "$CLONE/config/gone1.conf" "$FAKEHOME/.config/stale1.conf"
  ln -sf "$CLONE/config/gone2.conf" "$FAKEHOME/.config/stale2.conf"
  printf '  Planted: %s\n' "$FAKEHOME/.config/stale1.conf"
  printf '  Planted: %s\n' "$FAKEHOME/.config/stale2.conf"
  run_remove_stale
  printf '\nVerification:\n'
  verify_gone "$FAKEHOME/.config/stale1.conf"
  verify_gone "$FAKEHOME/.config/stale2.conf"
  verify_symlink "$FAKEHOME/.config/hypr/hyprland.conf"
}

# ─── packages scenarios ───────────────────────────────────────────────────

cmd_packages_uptodate() {
  banner "packages-uptodate"
  printf 'Scenario: packages baseline == HEAD. Nothing to do.\n'
  printf 'Expected: "Packages already up to date." — pacman not called.\n\n'
  reset_sandbox
  set_baselines_to_head
  run_packages_mock
}

cmd_packages_no_baseline() {
  banner "packages-no-baseline"
  printf 'Scenario: no packages.commit (pre-hk-update install).\n'
  printf 'Expected: "No package baseline recorded." then mock-installs all\n'
  printf '          required packages and writes baseline to HEAD.\n\n'
  reset_sandbox
  remove_baselines
  run_packages_mock
  printf '\nVerification:\n'
  verify_baseline packages
}

cmd_packages_added() {
  banner "packages-added"
  printf 'Scenario: "sl" added to pacman.txt since last baseline.\n'
  printf 'Expected: "[DRY RUN] hk-pkg-install sl", baseline updated.\n\n'
  reset_sandbox
  seed_packages_add
  run_packages_mock
  printf '\nVerification:\n'
  verify_baseline packages
}

cmd_packages_invalid_baseline() {
  banner "packages-invalid-baseline"
  printf 'Scenario: packages.commit contains a SHA not in git history.\n'
  printf 'Expected: warning about invalid baseline, then falls back to the\n'
  printf '          no-baseline path (mock-installs all required packages).\n\n'
  reset_sandbox
  write_invalid_baseline packages
  run_packages_mock
  printf '\nVerification:\n'
  verify_baseline packages
}

cmd_packages_removed() {
  banner "packages-removed"
  printf 'Scenario: "stow" dropped from pacman.txt since baseline.\n'
  printf 'Interactive: gum will ask "Remove '\''stow'\''?" — stow IS installed so\n'
  printf '             the prompt will appear. Answer Yes or No; hk-pkg-remove\n'
  printf '             is mocked so your system is safe either way.\n\n'
  reset_sandbox
  seed_packages_drop
  run_packages_mock
  printf '\nVerification:\n'
  verify_baseline packages
}

cmd_packages_remove_txt() {
  banner "packages-remove-txt"
  printf 'Scenario: "stow" added to packages/remove.txt since baseline.\n'
  printf 'Interactive: gum will ask "Remove '\''stow'\''?" — stow IS installed so\n'
  printf '             the prompt will appear. Answer Yes or No; hk-pkg-remove\n'
  printf '             is mocked so your system is safe either way.\n\n'
  reset_sandbox
  seed_remove_txt_add
  run_packages_mock
  printf '\nVerification:\n'
  verify_baseline packages
}

cmd_packages_real() {
  banner "packages-real"
  printf '###########################################################\n'
  printf ' REAL: installs the sl package (10 KB, no deps) via sudo.\n'
  printf ' Undo afterwards with: %s packages-real-cleanup\n' "$0"
  printf '###########################################################\n\n'
  reset_sandbox
  seed_packages_add
  run_packages_real
  printf '\nVerification:\n'
  if pacman -Q sl >/dev/null 2>&1; then
    printf '  ok  sl is installed\n'
  else
    printf '  BAD sl not installed (may have been skipped at prompt)\n'
  fi
  verify_baseline packages
}

cmd_packages_real_cleanup() {
  if pacman -Q sl >/dev/null 2>&1; then
    sudo pacman -Rns --noconfirm sl && printf 'Removed sl.\n'
  else
    printf 'sl is not installed; nothing to clean up.\n'
  fi
}

# ─── dispatch ─────────────────────────────────────────────────────────────

case "${1:-}" in
  setup)   cmd_setup ;;
  clean)   cmd_clean ;;
  status)  cmd_status ;;
  reset)   reset_sandbox; printf 'Sandbox reset.\n' ;;

  check-no-baseline)        cmd_check_no_baseline ;;
  check-uptodate)           cmd_check_uptodate ;;
  check-pending)            cmd_check_pending ;;
  check-invalid-baseline)   cmd_check_invalid_baseline ;;

  dotfiles-clean)           cmd_dotfiles_clean ;;
  dotfiles-conflict)        cmd_dotfiles_conflict ;;
  dotfiles-force)           cmd_dotfiles_force ;;
  dotfiles-force-dirty)     cmd_dotfiles_force_dirty ;;
  dotfiles-adopt)           cmd_dotfiles_adopt ;;
  dotfiles-adopt-clean)     cmd_dotfiles_adopt_clean ;;
  dotfiles-stale)           cmd_dotfiles_stale ;;

  remove-stale)             cmd_remove_stale ;;

  packages-uptodate)        cmd_packages_uptodate ;;
  packages-no-baseline)     cmd_packages_no_baseline ;;
  packages-added)           cmd_packages_added ;;
  packages-invalid-baseline) cmd_packages_invalid_baseline ;;
  packages-removed)         cmd_packages_removed ;;
  packages-remove-txt)      cmd_packages_remove_txt ;;
  packages-real)            cmd_packages_real ;;
  packages-real-cleanup)    cmd_packages_real_cleanup ;;

  *)
    grep '^#' "$0" | sed 's/^# \{0,1\}//'
    exit 1 ;;
esac
