#!/bin/bash

# Install hyprkarl's configs via symlink in ~/.config and ~/.local/share/applications.
# WARNING: This will replace any identically named files.
# Please back up anything that you might want to keep.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HYPRKARL_PATH="${HYPRKARL_PATH:-$SCRIPT_DIR}"

# Early copy of the hk-update-dotfiles --force guard (which stows below), so a
# doomed run fails here instead of after the slow AGS type generation.
dirty=$(git -C "$SCRIPT_DIR" diff --name-only HEAD -- config/ applications/)
if [[ -n "$dirty" ]]; then
  printf 'Cannot install dotfiles — uncommitted changes would be overwritten:\n%s\n' "$dirty" >&2
  printf 'Commit your changes first.\n' >&2
  exit 1
fi

# Build the AGS bar's generated, gitignored artifacts BEFORE stowing, so stow
# symlinks them into ~/.config/ags like everything else (config/ags/node_modules
# and config/ags/@girs are never committed):
#   - npm install builds node_modules with RELATIVE ags/gnim symlinks (recorded
#     as links in package-lock.json, so no registry fetch). Relative is the
#     point: GNU Stow aborts the whole operation on an ABSOLUTE symlink, so the
#     links must be relative to be stowable.
#   - `ags types` (no -u) generates the @girs type defs without touching the
#     tracked tsconfig.json — that is refreshed after the stow step below.
AGS_REPO_DIR="$SCRIPT_DIR/config/ags"
npm --prefix "$AGS_REPO_DIR" install
ags types -d "$AGS_REPO_DIR"

# Older installs generated real @girs/node_modules directly under ~/.config/ags
# (they were stow-ignored then); remove them so stow replaces them with symlinks
# into the repo. No-op on a fresh install.
rm -rf "$HOME/.config/ags/@girs" "$HOME/.config/ags/node_modules"

# Stow config/, applications/, and the GTK theme, replacing any conflicting
# files with the repo versions. This refuses to run if the repo has uncommitted
# config changes (the reset to HEAD would silently discard them) and records
# the installed commit for update tracking.
"$SCRIPT_DIR/bin/hk-update-dotfiles" --force || exit 1

# Create personal env var file from template if it doesn't exist
if [[ ! -f ~/.config/uwsm/env.local ]]; then
  cp "$SCRIPT_DIR/templates/setup/env.local.example" ~/.config/uwsm/env.local
fi

# The stow step reverted tsconfig.json to HEAD; (re)apply the AGS type paths.
# `ags types -u` rewrites tsconfig for the installed astal versions and refreshes
# the node_modules/ags link. If it differs from what's committed the file goes
# dirty — review the diff before committing.
ags types -u -d "$AGS_REPO_DIR"
if ! git -C "$SCRIPT_DIR" diff --quiet -- config/ags/tsconfig.json 2>/dev/null; then
  printf 'Note: AGS type paths updated in config/ags/tsconfig.json\n'
  printf '  Review: git -C %s diff config/ags/tsconfig.json\n' "$SCRIPT_DIR"
  printf '  Commit if the changes look correct.\n'
fi
