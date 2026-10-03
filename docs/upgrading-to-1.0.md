# Upgrading to 1.0 from an older install

This guide is for an install from before 1.0, including `develop` and `main`
from before the August 2026 overhaul and branches made from them. You have one
if `~/.local/share/hyprkarl/config/ags/` exists. Those versions used an AGS bar,
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
- **Application configs keep receiving Hyprkarl's defaults.** Terminals and
  the Hypr tools load a personal `local` file after Hyprkarl's settings; the
  portal and terminal choices are defaults your own file replaces; GTK and Qt
  follow the theme, and fastfetch comes from the theme. Only btop, Neovim, and
  Yazi are copied into `~/.config` once and are yours from then on.
- **The updater was rewritten.** `hk-update sync` reviews incoming commits and
  `hk-update apply` applies them. `tui`, `dotfiles`, `--force`, and `--adopt`
  are gone. Update records live under `~/.local/state/hyprkarl/update/`.

## 1. Save your customizations

Copy the whole checkout aside before changing anything. The copy keeps your
commits, uncommitted edits, and untracked and ignored files, and is usually a
few hundred megabytes at most.

```bash
cp -a ~/.local/share/hyprkarl ~/hyprkarl-backup
```

Later steps read your changes from it:

```bash
cd ~/hyprkarl-backup
git status --short --ignored     # edits, plus untracked (??) and ignored (!!) files
git diff                         # uncommitted edits
git log --oneline --branches --not --remotes   # your commits not on GitHub
```

Wallpapers you added show up as ignored files under `themes/*/wallpapers/`.
`config/ags/node_modules`, `config/ags/@girs`, and `config/hyprkarl/` are
generated and can be ignored.

## 2. Remove the old links

The old uninstaller removes every Hyprkarl symlink from `~/.config`, the old
GTK theme copy, and the old update records. It leaves real files alone.

```bash
./uninstall.sh
```

It asks for confirmation first. Hyprland and your terminal keep running, but the bar and `hk-*` keybindings
stop working until step 4 finishes.

## 3. Update the checkout

This discards your local edits in the checkout; they are in the backup.

```bash
git remote set-branches origin '*'
git fetch origin
git reset --hard
git clean -fdx config applications themes
git checkout -B main origin/main
```

`set-branches` matters if the checkout was cloned with `--single-branch` or
`--depth`: otherwise `fetch` only updates the branch it was cloned from.

Hyprkarl updates from `main`. To follow `develop` instead, check it out and
run `git config --local hyprkarl.updateBranch develop`.

## 4. Run the installer

```bash
./install.sh
```

It upgrades the system, installs the new packages, and reviews the retired
ones (AGS and its astal libraries, rofi, mako, hyprlock, hyprpolkitagent,
SDDM, and others) in one list. Removing them also removes dependencies
nothing else needs, such as Node.js, which came in with AGS; reinstall any you
use yourself, for example for an npm-installed tool.
Then it runs the one-time migrations, copies starting configs, links the
shipped ones, and builds the theme. The migrations write the same files the
old `setup-system.sh` did, except login: Hyprkarl now logs in through greetd
instead of SDDM. `060-greetd` writes `/etc/greetd/config.toml`, makes greetd
the display manager, and deletes `/etc/sddm.conf`; the switch takes effect at
the next boot.

## 5. Restore personal files

If `config/uwsm/env.local` exists in the backup, copy it to
`~/.config/uwsm/env.local`. Newer installs already keep that file in
`~/.config/uwsm/`, where the uninstall left it alone.

For wallpapers you added, copy each theme's extra files to
`~/.config/hyprkarl/themes/<theme>/wallpapers/`, then run
`hk-theme set <theme>`.

## 6. Reapply your edits

Go through `changes.patch` file by file and move each change to its new home.
Do not copy old files over new ones: most shipped files changed, and several
old settings no longer apply.

| Old path in the checkout | New home |
|---|---|
| `config/hypr/*.lua`, `config/hypr/bindings/*`, `config/hypr/windows/*` | `~/.config/hypr/hyprland.local.lua`, loaded after all of Hyprkarl's settings. Write only your changes; use `hl.unbind()` before rebinding a shipped key. |
| `~/.config/hypr/hyprland.conf` (a real file, not a link) | Lines other installers appended, such as autostart entries. Hyprland ignores this file because `hyprland.lua` exists; move them into a `hl.on("hyprland.start", ...)` block in `~/.config/hypr/hyprland.local.lua`. |
| `config/hypr/hypridle.conf`, `hyprpaper.conf`, `hyprsunset.conf` | `~/.config/hypr/hypridle.local.conf` and its Hyprpaper and Hyprsunset siblings, loaded after Hyprkarl's files. For Hypridle, redefine the timeout and command variables listed at the top of the shipped `hypridle.conf` rather than copying listeners. |
| `config/hypr/hyprlock.conf` | Gone. Lock appearance is theme data under `shell.lock`; see [Authentication](authentication-surfaces.md). |
| `config/ags/**` | `~/.config/quickshell/settings/shell.json`; custom widgets become command or QML widgets. See [Shell configuration](shell-configuration.md). |
| `config/rofi/**`, `bin/hk-menu-*` | `~/.config/quickshell/settings/menu.json`. See [Menu configuration](menu-configuration.md). |
| `config/mako/**` | The `notifications` section of `shell.json`. See [Shell configuration](shell-configuration.md). |
| `config/alacritty/alacritty.toml`, `config/foot/foot.ini`, `config/ghostty/config.ghostty`, `config/kitty/kitty.conf` | `~/.config/<terminal>/local.toml`, `local.ini`, or `local.conf`. |
| `config/btop`, `nvim`, `yazi` | The new copies in `~/.config/<app>/`. |
| `config/fastfetch` | The `fastfetch` keys in a theme overlay. See [Themes](themes.md). |
| `config/fish` | Your own `~/.config/fish/config.fish`; Hyprkarl no longer ships one. |
| `config/gtk-3.0`, `gtk-4.0`, `qt5ct`, `qt6ct` | A personal theme; GTK and Qt follow the theme. See [Themes](themes.md). |
| `config/xdg-desktop-portal`, `xdg-terminals.list` | Your own file at the same path in `~/.config/`, which replaces Hyprkarl's default. |
| `config/uwsm/default` | Run `hk-default-terminal`, `hk-default-editor`, or `hk-default-shell`, or set variables in `~/.config/uwsm/env.local`. |
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

Reboot, since the session environment and the display manager changed. With
an encrypted disk, do it where you can type the passphrase. After the
passphrase, greetd should start your session without a login prompt. If it
does not, switch to another console with Ctrl+Alt+F2, log in, and check
`systemctl status greetd`. Then:

```bash
Hyprland --verify-config
hk-shell status
hk-update check
```

Lock with `hk-lock`, unlock with your password, and suspend once to confirm
the lock is up on resume. When everything works, delete `~/hyprkarl-backup`.
