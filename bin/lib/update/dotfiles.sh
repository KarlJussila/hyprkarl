#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/state.sh"

force=0
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; exit 1 ;;
  esac
done

if [[ "$force" -eq 1 ]]; then
  dirty=$(git -C "$HYPRKARL_PATH" diff --name-only HEAD -- config/ applications/)
  if [[ -n "$dirty" ]]; then
    printf 'Cannot force update — uncommitted changes would be overwritten:\n%s\n' "$dirty" >&2
    printf 'Commit your changes first.\n' >&2
    exit 1
  fi

  printf 'Restowing config files...\n'
  stow -D --ignore='@girs' --ignore='node_modules' --no-folding \
    --dir="$HYPRKARL_PATH" --target="$HOME/.config" config
  stow --ignore='@girs' --ignore='node_modules' --adopt --no-folding \
    --dir="$HYPRKARL_PATH" --target="$HOME/.config" config
  stow --adopt --no-folding \
    --dir="$HYPRKARL_PATH" --target="$HOME/.local/share/applications" applications
  git -C "$HYPRKARL_PATH" checkout config/ applications/
else
  stow_conflicts() {
    stow -n -v "$@" 2>&1 | grep '^CONFLICT:'
  }

  printf 'Checking for conflicts...\n'
  conflicts=$(
    stow_conflicts --restow --no-folding --ignore='@girs' --ignore='node_modules' \
      --dir="$HYPRKARL_PATH" \
      --target="$HOME/.config" \
      config

    stow_conflicts --restow --no-folding \
      --dir="$HYPRKARL_PATH" \
      --target="$HOME/.local/share/applications" \
      applications

    mkdir -p "$HOME/.local/share/themes/hyprkarl"
    stow_conflicts --restow --no-folding \
      --dir="$HYPRKARL_PATH/config/hyprkarl/current/theme" \
      --target="$HOME/.local/share/themes/hyprkarl" \
      gtk-theme
  )

  if [[ -n "$conflicts" ]]; then
    printf 'Cannot update dotfiles — resolve these conflicts first:\n%s\n' "$conflicts" >&2
    exit 1
  fi

  printf 'Restowing config files...\n'
  stow --restow --no-folding --ignore='@girs' --ignore='node_modules' \
    --dir="$HYPRKARL_PATH" \
    --target="$HOME/.config" \
    config

  stow --restow --no-folding \
    --dir="$HYPRKARL_PATH" \
    --target="$HOME/.local/share/applications" \
    applications
fi

mkdir -p "$HOME/.local/share/themes/hyprkarl"
stow --restow --no-folding \
  --dir="$HYPRKARL_PATH/config/hyprkarl/current/theme" \
  --target="$HOME/.local/share/themes/hyprkarl" \
  gtk-theme || exit 1

printf 'Removing stale symlinks...\n'
while IFS= read -r link; do
  if [[ ! -e "$link" ]]; then
    target=$(readlink "$link")
    if [[ "$target" == *"hyprkarl"* ]]; then
      rm "$link"
    fi
  fi
done < <(find "$HOME/.config" "$HOME/.local/share/applications" "$HOME/.local/share/themes/hyprkarl" -type l 2>/dev/null)

if pgrep -x Hyprland >/dev/null; then
  hyprctl reload >/dev/null
fi

update_write_commit dotfiles
printf 'Dotfiles updated.\n'
