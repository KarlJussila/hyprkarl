#!/bin/bash

# Remove hyprkarl's config symlinks from ~/.config and
# ~/.local/share/applications, reversing setup-dotfiles.sh. Installed packages
# and setup-system.sh changes are left in place and listed at the end.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HYPRKARL_PATH="${HYPRKARL_PATH:-$SCRIPT_DIR}"
source "$SCRIPT_DIR/bin/lib/update.sh"

gum confirm "Remove all hyprkarl config symlinks for this user? The current session keeps running, but Hyprland and hk-* commands will not work correctly until you set up another configuration." || exit 1

stow -D --no-folding --dir="$HYPRKARL_PATH" --target="$HOME/.config" config
stow -D --no-folding --dir="$HYPRKARL_PATH" --target="$HOME/.local/share/applications" applications
rm -rf "$HOME/.local/share/themes/hyprkarl"

# Catch anything a plain unstow missed (renamed files, older install layouts)
remove_stale_symlinks
remove_empty_dirs

# Drop the update baselines so a future reinstall starts fresh
rm -f "$HYPRKARL_PATH"/config/hyprkarl/update/*.commit

printf 'Hyprkarl config symlinks removed.\n\n'
printf 'Left in place:\n'
printf '  - the repo at %s (delete it when you are done)\n' "$HYPRKARL_PATH"
printf '  - personal configuration under ~/.config/hyprkarl/\n'
printf '  - installed packages (see packages/*.txt; remove with pacman -Rns)\n'
printf '  - system settings from setup-system.sh: /etc/sddm.conf (autologin),\n'
printf '    /etc/systemd/logind.conf.d/lid.conf, /etc/sudoers.d/passwd-tries,\n'
printf '    the faillock deny count, ufw LocalSend rules, and the docker\n'
printf '    service/group membership\n'
printf '  - ~/.config/uwsm/default and env.local\n'
printf '  - ~/.config/xdg-terminals.list\n'
