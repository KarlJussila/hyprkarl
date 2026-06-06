# Updating Hyprkarl

This page covers how to pull upstream changes into a customized Hyprkarl
installation using `hk-update`.

## The Update Model

Each update category — dotfiles, packages, system — tracks the last commit it
was applied at in `config/hyprkarl/update/`. When you run `hk-update`, it
compares that recorded commit to `HEAD` to determine what needs to run.

The setup scripts (`setup-dotfiles.sh`, `setup-packages.sh`,
`setup-system.sh`) write this baseline when they run, so `hk-update`
immediately knows the starting state after a fresh install.

## Guided Update (TUI)

```bash
hk-update tui
```

The recommended interactive path — also reachable from the main menu under
**Update → Update Hyprkarl**, which opens it in a floating terminal. It walks
the whole config-sync process in three phases:

1. **Sync** — fetches from `origin` and merges the upstream branch. Because the
   live `~/.config/` files are symlinks into the repo the working tree is
   usually dirty, so it offers to stash-and-restore (or commit first) before
   merging, and guides you through any merge or stash conflicts file by file
   (edit in `$EDITOR`, take theirs, or keep yours).
2. **Review** — summarizes the pending dotfile, package, and system changes and
   lets you browse the diffs (rendered with `delta` inside an `fzf` preview
   pane) before committing to anything.
3. **Apply** — you pick which categories to apply. It delegates to the same
   `hk-update-dotfiles` / `hk-update-packages` / `hk-update-system` commands
   documented below (so baselines stay correct), surfacing stow conflicts with
   a clear repo-vs-adopt choice and prompting per package removal.

It deliberately excludes the system package upgrade (`paru -Syu`); run that
separately via **Update → Upgrade Packages** / `hk-pkg-upgrade`.

The manual flow below does the same work step by step and is still available if
you prefer to drive each stage yourself.

## Normal Update Flow

```bash
cd ~/.local/share/hyprkarl
git fetch origin
git merge origin/main        # or rebase, depending on your branch setup
hk-update all
```

`hk-update all` runs dotfiles → packages → system in sequence and stops at the
first failure. Pass `--force` or `--adopt` to have that flag applied to the
dotfiles step. Run categories individually if you only want specific ones or
need to handle them separately.

## Checking Before Applying

```bash
hk-update check
```

Prints a summary of what each category would do without touching anything:
changed config files, packages to install or remove, whether system setup files
changed. Useful for reviewing a merge before applying it.

## Dotfiles Update

```bash
hk-update dotfiles
```

The normal path pre-checks for stow conflicts. If `~/.config/` or
`~/.local/share/applications/` contain plain files (not symlinks) where
Hyprkarl expects to manage a file, it aborts and lists the conflicts before
touching anything.

### Resolving Conflicts

**If the conflicting files are yours and you want to review them:**

```bash
hk-update dotfiles --adopt
```

Adopts the conflicting files into the repo without overwriting them. The repo
becomes dirty with your local versions. Review the diff, then either commit
what you want to keep or discard and re-run:

```bash
git -C ~/.local/share/hyprkarl diff config/ applications/
git -C ~/.local/share/hyprkarl checkout config/ applications/  # to discard
hk-update dotfiles
```

**If you just want to blast through and apply the repo versions:**

```bash
hk-update dotfiles --force
```

Unstows, re-adopts, then runs `git checkout config/ applications/` to apply
the repo versions. This overwrites conflicting files without prompting.
Requires a clean git working tree — if you have uncommitted changes to config
files, it will refuse and tell you to commit first.

### Force vs Adopt

|                      | `--force`                     | `--adopt`                               |
|----------------------|-------------------------------|-----------------------------------------|
| Conflicting files    | Overwritten with repo version | Pulled into repo for review             |
| Git state after      | Clean                         | Dirty (your versions staged as changes) |
| Writes update commit | Yes                           | Only if no conflicts found              |
| Use when             | You trust the repo version    | You want to inspect what diverged       |

## Stale Symlink Removal

```bash
hk-update remove-stale
```

Removes broken symlinks that point into the hyprkarl repo, then prunes any
empty directories left behind. Useful after deleting or renaming files in the
repo when you don't need to restow everything — `hk-update dotfiles` also
removes stale symlinks as part of its normal run, so use `remove-stale` only
when you want that cleanup step in isolation.

## Packages Update

```bash
hk-update packages
```

Reads `packages/pacman.txt`, `packages/aur.txt`, and `packages/remove.txt` and
diffs them against the recorded baseline commit to determine what changed.

- **New packages** are installed automatically.
- **Dropped packages** (removed from the required lists) prompt for removal via
  `gum confirm`.
- **Packages added to `remove.txt`** also prompt for removal, showing the
  inline comment as the reason (e.g. `Replaced with wifitui`).

All removal prompts run before any installs, so package swaps (remove old,
install new) don't block on conflicts.

**No baseline recorded** (first run or deleted commit file): installs any
missing required packages from the current lists. Drop detection is unavailable
until a baseline is established, which is written at the end of the run.

## System Update

```bash
hk-update system
```

Re-runs `setup-system.sh`. All operations in that script are idempotent, so
re-running it is safe.

## Package Lists

Required packages live as plain text files, one package per line. Comments
with `#` are allowed:

```
packages/pacman.txt    pacman packages to install
packages/aur.txt       AUR packages to install
packages/remove.txt    packages to remove (with reason comments)
```

To add a required package, add it to the appropriate file and commit. The next
`hk-update packages` run will install it. To remove a required package from
the install list, remove it from the file. If it's a package being replaced by
another, add it to `remove.txt` with a comment explaining why — that comment
is shown in the removal prompt.

## Resetting Update State

Each category has a commit file in `config/hyprkarl/update/`. Deleting one
forces `hk-update` to re-run that category on the next invocation:

```bash
rm ~/.local/share/hyprkarl/config/hyprkarl/update/dotfiles.commit
hk-update dotfiles   # will run regardless of whether HEAD changed
```

The setup scripts also write these files, so re-running a setup script resets
the baseline for that category.
