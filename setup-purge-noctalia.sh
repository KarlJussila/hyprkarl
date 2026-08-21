#!/bin/bash
# setup-purge-noctalia.sh
# Removes the CachyOS Noctalia desktop shell and its leftover configs so
# Hyprkarl installs onto a clean base.
#
# Run this BEFORE setup-all.sh. Ordering matters in both directions:
#
#   - cachyos-hypr-noctalia hard-depends on dolphin, so packages/remove.txt
#     cannot drop dolphin until this script has run.
#   - cachyos-hypr-noctalia is the ONLY requirer of uwsm, grim and slurp, so a
#     plain `pacman -Rns` would sweep them out. Hyprkarl needs uwsm (SDDM
#     autologin launches hyprland-uwsm.desktop) but does not list it in
#     packages/pacman.txt, so it would not come back. This script re-marks them
#     explicit first to pin them in place.
#
# Not removed here: dolphin. setup-packages.sh handles it via remove.txt once
# the dependency above is gone.

# --- Constants ---
PURGE_PKGS=(cachyos-hypr-noctalia noctalia)

# Swept by -Rns but needed afterwards, and NOT restored by packages/pacman.txt.
# Marked explicit so recursive removal skips them.
#
# Only uwsm qualifies. Deliberately absent: grim and slurp are also swept, but
# hyprshot (pacman.txt) depends on both and pulls them back as proper deps.
# Pinning them here would leave them explicit forever, masquerading as orphans.
KEEP_PKGS=(uwsm)

# Noctalia / CachyOS shell configs with no Hyprkarl counterpart. Stow never
# manages these, so they outlive the configuration install unless removed here.
NOCTALIA_CONFIGS=(
  "$HOME/.config/noctalia"
  "$HOME/.config/hypr/config"
  "$HOME/.config/hypr/xdph.conf"
  "$HOME/.config/autostart/cachyos-hello.desktop"
)

# CachyOS desktop defaults Hyprkarl replaces or does not use. Comment out any
# you would rather keep.
CACHYOS_CONFIGS=(
  "$HOME/.config/cachyos"
  "$HOME/.config/dolphinrc"
  "$HOME/.config/kdeglobals"
  "$HOME/.config/menus"
  "$HOME/.config/micro"
  "$HOME/.config/xsettingsd"
)

BACKUP_DIR="$HOME/.local/state/noctalia-purge-$(date +%Y%m%d-%H%M%S)"

# --- Functions ---
# Deliberately not gum: gum arrives with setup-packages.sh (packages/pacman.txt),
# and this script runs before that. Plain bash only — assume nothing is installed.
info()  { printf '\033[32m*\033[0m %s\n' "$*"; }
warn()  { printf '\033[33m!\033[0m %s\n' "$*" >&2; }
error() { printf '\033[31mx\033[0m %s\n' "$*" >&2; exit 1; }

confirm() {
  local reply
  read -r -p "$1 [y/N] " reply
  [[ "$reply" == [yY] ]]
}

installed_only() {
  local pkg
  for pkg in "$@"; do
    pacman -Q "$pkg" &>/dev/null && printf '%s\n' "$pkg"
  done
}

pin_shared_deps() {
  local pkgs
  mapfile -t pkgs < <(installed_only "${KEEP_PKGS[@]}")

  if [[ ${#pkgs[@]} -eq 0 ]]; then
    return
  fi

  info "Pinning shared dependencies as explicit: ${pkgs[*]}"
  if [[ "$DRY_RUN" -ne 0 ]]; then
    return
  fi
  sudo pacman -D --asexplicit "${pkgs[@]}" || error "Could not re-mark ${pkgs[*]}; aborting before removal"
}

# Dry-run preview. Uses -Rs, not -Rns: --nosave and --print are mutually
# exclusive. Read-only, so no sudo. The real run pins KEEP_PKGS first, which
# this preview cannot reflect, so those lines are annotated rather than dropped.
preview_removal() {
  local line
  local name
  local keep

  keep=" ${KEEP_PKGS[*]} "
  while read -r line; do
    name="$(sed 's/-[^-]*-[^-]*$//' <<<"$line")"
    if [[ "$keep" == *" $name "* ]]; then
      printf '  %-44s <- pinned, will be KEPT\n' "$line"
    else
      printf '  %s\n' "$line"
    fi
  done < <(pacman -Rs --print "$@")
}

purge_packages() {
  local pkgs
  mapfile -t pkgs < <(installed_only "${PURGE_PKGS[@]}")

  if [[ ${#pkgs[@]} -eq 0 ]]; then
    info "Noctalia packages already absent"
    return
  fi

  info "Removing: ${pkgs[*]}"
  if [[ "$DRY_RUN" -ne 0 ]]; then
    preview_removal "${pkgs[@]}"
    return
  fi

  # No --noconfirm: read the cascade list before agreeing to it.
  sudo pacman -Rns "${pkgs[@]}" || warn "Package removal did not complete; configs left untouched"
}

purge_configs() {
  local path
  local moved=0

  for path in "${NOCTALIA_CONFIGS[@]}" "${CACHYOS_CONFIGS[@]}"; do
    if [[ ! -e "$path" ]]; then
      continue
    fi

    if [[ "$DRY_RUN" -ne 0 ]]; then
      printf '  would back up and remove  %s\n' "$path"
      moved=1
      continue
    fi

    mkdir -p "$BACKUP_DIR"
    mv "$path" "$BACKUP_DIR/" || warn "Could not move $path"
    moved=1
  done

  if [[ "$moved" -eq 0 ]]; then
    info "No leftover configs found"
    return
  fi

  if [[ "$DRY_RUN" -eq 0 ]]; then
    info "Configs moved to $BACKUP_DIR"
  fi
}

# --- Script Body ---
DRY_RUN=0

case "${1:-}" in
  --dry-run) DRY_RUN=1 ;;
  "") ;;
  *) echo "Usage: setup-purge-noctalia.sh [--dry-run]" >&2; exit 1 ;;
esac

if [[ -L "$HOME/.config/hypr/hyprland.lua" ]]; then
  warn "Hyprkarl dotfiles already stowed — run this before setup-all.sh for a clean base"
fi

if [[ "$DRY_RUN" -eq 0 ]] && ! confirm "Purge Noctalia packages and CachyOS shell configs?"; then
  info "Aborted"
  exit 0
fi

pin_shared_deps
purge_packages
purge_configs

info "Done. Next: ./setup-all.sh (setup-packages.sh will now be able to drop dolphin)"

# Removing a running binary is safe: the kernel keeps the inode alive while the
# process holds it, so a running noctalia keeps going on its mapped pages. Only
# lazily-read data under /usr/share/noctalia (emoji picker, icons) breaks, and
# xdg-desktop-portal-hyprland runs a deleted binary until its unit restarts.
# Both clear on the reboot setup-all.sh already prompts for. Run from a TTY if
# you would rather not touch a half-removed shell at all.
if pgrep -x noctalia &>/dev/null; then
  warn "noctalia is still running from a deleted binary — it clears on reboot"
fi
