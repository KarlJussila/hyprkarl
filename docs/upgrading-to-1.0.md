# Upgrading to 1.0 from an older install

This guide is for an install from before the August 2026 overhaul: the `develop`
branch at or before commit `3df882e`, or anything older. You have one if
`~/.local/share/hyprkarl/config/ags/` exists. Those versions used an AGS bar,
rofi menus, mako, hyprlock, and `hk-update tui`.

There is no automatic upgrade from those versions. The steps below are written
so you, or an AI agent working for you, can follow them in order. Plan for a
session restart at the end.

## What changed

- **Personal configuration moved out of the checkout.** Old installs were
  customized by editing the checkout itself, because every file in `~/.config`
  was a symlink into it. Now the checkout stays clean, and your changes live in
  personal files that updates never touch. See
  [Extending Hyprkarl](extending-hyprkarl.md#choose-the-right-place).
- **Quickshell replaced** the AGS bar, rofi menus and launcher, mako, the
  polkit agent, the OSD, and hyprlock.
- **Themes are compiled from one `theme.yaml`** instead of a directory of
  hand-written per-app files. Builds live under `~/.local/state/hyprkarl/`.
- **Many application configs are now starting copies.** btop, fastfetch, fish,
  GTK, nvim, Qt, the portals, yazi, Hypridle, Hyprpaper, Hyprsunset, and
  `uwsm/default` are copied into `~/.config` once and are yours from then on.
  Terminals keep a small shipped config that includes your `local.*` file.
- **The updater was rewritten.** `hk-update sync` reviews incoming commits and
  `hk-update apply` applies them. `tui`, `dotfiles`, `--force`, and `--adopt`
  are gone. Update records live under `~/.local/state/hyprkarl/update/`.

## 1. Save your customizations

Run this in the old checkout before changing anything. It records every change
you made to tracked files (committed or not) and copies out your untracked
personal files.

```bash
cd ~/.local/share/hyprkarl
backup=~/hyprkarl-backup
mkdir -p "$backup"
base=$(git merge-base HEAD origin/develop)
git diff "$base" > "$backup/changes.patch"
git diff --stat "$base" > "$backup/changed-files.txt"
git status --porcelain --ignored > "$backup/status.txt"
cp -a config/uwsm/env.local "$backup/" 2>/dev/null
cp -a --parents themes/*/wallpapers "$backup/"
```

`changes.patch` holds your edits to shipped files. `status.txt` lists untracked
(`??`) and ignored (`!!`) files: wallpapers you added show up as ignored, and
any other personal file you created in the checkout appears there too. Copy
those into the backup as well (`config/ags/node_modules` and
`config/hyprkarl/update/` can be skipped).

## 2. Remove the old links

The old uninstaller removes every Hyprkarl symlink from `~/.config`, the old
GTK theme copy, and the old update records. It leaves real files alone.

```bash
./uninstall.sh
```

Hyprland and your terminal keep running, but the bar and `hk-*` keybindings
stop working until step 4 finishes.

## 3. Update the checkout

This discards your local edits in the checkout; they are in the backup.

```bash
git fetch origin
git reset --hard
git clean -fdx config applications themes
git checkout -B main origin/main
```

Hyprkarl updates from `main`. To follow `develop` instead, check it out and
run `git config --local hyprkarl.updateBranch develop`.

## 4. Run setup

```bash
./setup-all.sh
```

It installs the new packages and reviews the retired ones (AGS and its astal
libraries, rofi, mako, hyprlock, hyprpolkitagent, and others) in one list.
Then it copies starting configs, links the shipped ones, builds the theme, and
starts the shell. Last, it reruns the one-time system migrations. They write
the same files the old `setup-system.sh` did; `010-sddm-autologin` replaces
`/etc/sddm.conf`, so reapply any personal edit to that file afterwards.

## 5. Restore personal files

```bash
cp ~/hyprkarl-backup/env.local ~/.config/uwsm/env.local
```

For wallpapers you added, copy each theme's extra files to
`~/.config/hyprkarl/themes/<theme>/wallpapers/`, then run
`hk-theme set <theme>`.

## 6. Reapply your edits

Go through `changes.patch` file by file and move each change to its new home.
Do not copy old files over new ones: most shipped files changed, and several
old settings no longer apply.

| Old path in the checkout | New home |
|---|---|
| `config/hypr/*.lua`, `config/hypr/bindings/*`, `config/hypr/windows/*` | `~/.config/hyprkarl/hypr/<module>.lua`, loaded after the shipped module of the same name. Write only your additions; use `hl.unbind()` before rebinding a shipped key. |
| `config/hypr/hypridle.conf`, `hyprpaper.conf`, `hyprsunset.conf` | The new copies in `~/.config/hypr/`. Apply your edit there; the new Hypridle file uses Lua dispatcher syntax and locks before sleep. |
| `config/hypr/hyprlock.conf` | Gone. Lock appearance is theme data under `shell.lock`; see [Authentication](authentication-surfaces.md). |
| `config/ags/**` | `~/.config/quickshell/settings/shell.json`; custom widgets become command or QML widgets. See [Customizing the bar](customizing-bar.md). |
| `config/rofi/**`, `bin/hk-menu-*` | `~/.config/quickshell/settings/menu.json`. See [Menu configuration](menu-configuration.md). |
| `config/mako/**` | The `notifications` section of `shell.json`. See [Shell configuration](shell-configuration.md). |
| `config/alacritty/alacritty.toml`, `config/foot/foot.ini`, `config/ghostty/config.ghostty`, `config/kitty/kitty.conf` | `~/.config/<terminal>/local.toml`, `local.ini`, or `local.conf`. |
| `config/btop`, `fastfetch`, `fish`, `gtk-3.0`, `gtk-4.0`, `nvim`, `qt5ct`, `qt6ct`, `xdg-desktop-portal*`, `xdg-terminals.list`, `yazi` | The new copies in `~/.config/<app>/`. |
| `config/uwsm/default` | `~/.config/uwsm/default`, or run `hk-default-terminal`, `hk-default-editor`, `hk-default-shell`. |
| `config/uwsm/env` | Put additions in `~/.config/uwsm/env.local`. |
| Edits to `themes/<name>/*` | Values in `~/.config/hyprkarl/themes/<name>/theme.yaml`, or a template under its `overrides/`. See [Themes](themes.md). |
| A theme directory you added | Recreate it as `~/.config/hyprkarl/themes/<name>/theme.yaml`; `themes/AGENTS.md` explains translating a palette. |
| New or edited scripts in `bin/` | `~/.local/bin/`, or a hook in `~/.config/hyprkarl/hooks/<event>.d/`. |
| `applications/*.desktop` | `~/.local/share/applications/`. |
| `packages/*.txt` | Install extra packages yourself; Hyprkarl does not track personal packages. |

Retired commands: `hk-update tui` and `hk-update dotfiles` became
`hk-update sync` and `hk-update apply`; `hk-menu-*` became `hk-shell menu`;
`hk-ags` became `hk-shell`; `hk-wallpaper-select` became `hk-shell wallpaper`.
Check personal scripts and bindings for the old names.

## 7. Restart and check

Log out and back in, since the session environment changed. Then:

```bash
Hyprland --verify-config
hk-shell status
hk-update check
```

Lock with `hk-lock`, unlock with your password, and suspend once to confirm
the lock is up on resume. When everything works, delete `~/hyprkarl-backup`.
