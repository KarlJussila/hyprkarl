#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/state.sh"
source "$SCRIPT_DIR/pkg_helpers.sh"

PKG_LIB_DIR="$SCRIPT_DIR/../pkg"
PACKAGES_DIR="$HYPRKARL_PATH/packages"

prompt_remove() {
  local pkg="$1" reason="$2"
  pacman -Q "$pkg" &>/dev/null || return 0
  gum confirm "Remove '$pkg'? ($reason)" || return 0
  "$PKG_LIB_DIR/remove.sh" "$pkg"
}

baseline=$(update_read_commit packages)
head=$(update_head_commit)

if [[ -n "$baseline" ]] && ! update_commit_valid "$baseline"; then
  printf 'Warning: recorded baseline commit is no longer in git history. Treating as no baseline.\n' >&2
  baseline=""
fi

if [[ -n "$baseline" ]] && [[ "$baseline" == "$head" ]]; then
  printf 'Packages already up to date.\n'
  update_write_commit packages
  exit 0
fi

if [[ -z "$baseline" ]]; then
  printf 'No package baseline recorded. Installing any missing required packages.\n'
  printf 'Drop detection is unavailable until a baseline is established.\n'

  mapfile -t pacman_pkgs < <(grep -v '^[[:space:]]*#' "$PACKAGES_DIR/pacman.txt" | grep -v '^[[:space:]]*$' | sed 's/[[:space:]]*#.*//')
  mapfile -t aur_pkgs    < <(grep -v '^[[:space:]]*#' "$PACKAGES_DIR/aur.txt"    | grep -v '^[[:space:]]*$' | sed 's/[[:space:]]*#.*//')

  [[ ${#pacman_pkgs[@]} -gt 0 ]] && "$PKG_LIB_DIR/install.sh"     "${pacman_pkgs[@]}"
  [[ ${#aur_pkgs[@]} -gt 0 ]]    && "$PKG_LIB_DIR/install-aur.sh" "${aur_pkgs[@]}"

  update_write_commit packages
  exit 0
fi

pkg_diff "packages/pacman.txt" "$baseline"
added_pacman="$added"
removed_pacman="$removed"

pkg_diff "packages/aur.txt" "$baseline"
added_aur="$added"
removed_aur="$removed"

pkg_diff "packages/remove.txt" "$baseline"
added_remove="$added"

# Prompt for all removals before installing, so conflicting replacements don't block installs
while IFS= read -r pkg; do
  [[ -z "$pkg" ]] && continue
  comment=$(pkg_comment "$pkg" "$PACKAGES_DIR/remove.txt")
  prompt_remove "$pkg" "${comment:-Added to removal list}" || exit 1
done <<< "$added_remove"

while IFS= read -r pkg; do
  [[ -z "$pkg" ]] && continue
  prompt_remove "$pkg" "No longer required" || exit 1
done <<< "$removed_pacman"

while IFS= read -r pkg; do
  [[ -z "$pkg" ]] && continue
  prompt_remove "$pkg" "AUR, no longer required" || exit 1
done <<< "$removed_aur"

if [[ -n "$added_pacman" ]]; then
  mapfile -t pkgs <<< "$added_pacman"
  printf 'Installing new required packages: %s\n' "${pkgs[*]}"
  "$PKG_LIB_DIR/install.sh" "${pkgs[@]}" || exit 1
fi

if [[ -n "$added_aur" ]]; then
  mapfile -t pkgs <<< "$added_aur"
  printf 'Installing new required AUR packages: %s\n' "${pkgs[*]}"
  "$PKG_LIB_DIR/install-aur.sh" "${pkgs[@]}" || exit 1
fi

update_write_commit packages
printf 'Packages updated.\n'
