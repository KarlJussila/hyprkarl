#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/state.sh"
source "$SCRIPT_DIR/pkg_helpers.sh"

PACKAGES_DIR="$HYPRKARL_PATH/packages"
HEAD=$(update_head_commit)

check_dotfiles() {
  local baseline
  baseline=$(update_read_commit dotfiles)

  if [[ -z "$baseline" ]]; then
    printf '  No baseline recorded. Run setup-dotfiles.sh or hk-update dotfiles to establish one.\n'
    return
  fi

  if [[ "$baseline" == "$HEAD" ]]; then
    printf '  Up to date.\n'
    return
  fi

  local changed
  changed=$(git -C "$HYPRKARL_PATH" diff --name-only "$baseline" HEAD -- config/ applications/ 2>/dev/null)
  if [[ -n "$changed" ]]; then
    printf '  Changed since last dotfiles update:\n'
    printf '%s\n' "$changed" | sed 's/^/    /'
  else
    printf '  No config file changes since last dotfiles update.\n'
  fi

  local stale_found=0
  while IFS= read -r link; do
    if [[ ! -e "$link" ]]; then
      target=$(readlink "$link")
      if [[ "$target" == *"hyprkarl"* ]]; then
        if [[ "$stale_found" -eq 0 ]]; then
          printf '  Stale symlinks that would be removed:\n'
          stale_found=1
        fi
        printf '    %s\n' "$link"
      fi
    fi
  done < <(find "$HOME/.config" "$HOME/.local/share/applications" -type l 2>/dev/null)
}

check_packages() {
  local baseline
  baseline=$(update_read_commit packages)

  if [[ -n "$baseline" ]] && ! update_commit_valid "$baseline"; then
    printf '  Warning: recorded baseline commit is no longer in git history.\n'
    baseline=""
  fi

  if [[ -z "$baseline" ]]; then
    printf '  No baseline recorded. Checking for missing required packages...\n'
    local missing=()
    while IFS= read -r pkg; do
      [[ -z "$pkg" ]] && continue
      pacman -Q "$pkg" &>/dev/null || missing+=("$pkg")
    done < <(grep -hv '^[[:space:]]*#' "$PACKAGES_DIR/pacman.txt" "$PACKAGES_DIR/aur.txt" 2>/dev/null \
               | grep -v '^[[:space:]]*$' | sed 's/[[:space:]]*#.*//')
    if [[ ${#missing[@]} -gt 0 ]]; then
      printf '  Missing required packages:\n'
      printf '    %s\n' "${missing[@]}"
    else
      printf '  All required packages are installed.\n'
    fi
    return
  fi

  if [[ "$baseline" == "$HEAD" ]]; then
    printf '  Up to date.\n'
    return
  fi

  pkg_diff "packages/pacman.txt" "$baseline"
  local ap="$added" rp="$removed"
  pkg_diff "packages/aur.txt" "$baseline"
  local aa="$added" ra="$removed"
  pkg_diff "packages/remove.txt" "$baseline"
  local ar="$added"

  local any=0

  if [[ -n "$ap" ]]; then
    printf '  New required packages to install:\n'
    printf '%s\n' "$ap" | sed 's/^/    /'
    any=1
  fi
  if [[ -n "$aa" ]]; then
    printf '  New required AUR packages to install:\n'
    printf '%s\n' "$aa" | sed 's/^/    /'
    any=1
  fi
  if [[ -n "$ar" ]]; then
    printf '  Packages newly added to removal list:\n'
    printf '%s\n' "$ar" | sed 's/^/    /'
    any=1
  fi
  if [[ -n "$rp" ]] || [[ -n "$ra" ]]; then
    printf '  Packages dropped from required list (will prompt for removal):\n'
    { [[ -n "$rp" ]] && printf '%s\n' "$rp"; [[ -n "$ra" ]] && printf '%s\n' "$ra"; } | sed 's/^/    /'
    any=1
  fi

  [[ "$any" -eq 0 ]] && printf '  No package changes.\n'
}

check_system() {
  local baseline
  baseline=$(update_read_commit system)

  if [[ -z "$baseline" ]]; then
    printf '  No baseline recorded. Run setup-system.sh or hk-update system to establish one.\n'
    return
  fi

  if [[ "$baseline" == "$HEAD" ]]; then
    printf '  Up to date.\n'
    return
  fi

  local changed
  changed=$(git -C "$HYPRKARL_PATH" diff --name-only "$baseline" HEAD -- setup-system.sh templates/setup/ 2>/dev/null)
  if [[ -n "$changed" ]]; then
    printf '  System setup files changed since last system update:\n'
    printf '%s\n' "$changed" | sed 's/^/    /'
  else
    printf '  System setup files unchanged.\n'
  fi
}

printf '=== Dotfiles ===\n'
check_dotfiles

printf '\n=== Packages ===\n'
check_packages

printf '\n=== System ===\n'
check_system
