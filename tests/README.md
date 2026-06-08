# Tests

Manual test harnesses for hyprkarl. These are interactive sandboxes, not an
automated CI suite — you run a scenario, drive the TUI or observe output, and
verify the result.

## `hk-update-tui.sh`

Exercises [`hk-update tui`](../docs/updating.md#guided-update-tui) (the guided
update TUI) end to end without touching your real repo, `~/.config`, or GitHub.

It builds a throwaway clone of this repo at `/tmp/hk-update-tui-test` with a
**local** fake remote, points the TUI at it via `HYPRKARL_PATH`, and runs the
TUI from your working tree (`bin/hk-update-tui`) so you can test uncommitted
changes against a disposable git history. The apply-dotfiles scenarios also
redirect `$HOME` so stow targets a fake `~/.config`.

```bash
tests/hk-update-tui.sh setup     # once — build the sandbox + fake remote

# Sync + conflict resolution (sandboxed git; choose Quit at Review):
tests/hk-update-tui.sh a         # clean merge + browse review diffs
tests/hk-update-tui.sh b         # dirty tree -> stash / commit / abort chooser
tests/hk-update-tui.sh c         # real merge conflict (theirs / ours / edit)
tests/hk-update-tui.sh d         # stash-pop conflict (editor loop + recovery msg)

# Apply phase:
tests/hk-update-tui.sh apply-dotfiles           # isolated: stows into a fake $HOME
tests/hk-update-tui.sh apply-dotfiles-conflict  # planted stow conflict -> chooser
tests/hk-update-tui.sh apply-packages           # installs the tiny 'sl' package (sudo)
tests/hk-update-tui.sh apply-packages-cleanup   # uninstall 'sl'

tests/hk-update-tui.sh status    # sandbox ahead/behind + working tree
tests/hk-update-tui.sh clean     # delete the sandbox
```

### Safety

- **Scenarios a–d** touch only the sandboxed git clone. Explore Sync + Review,
  then choose **Quit** at the Review screen — don't apply from these.
- **apply-dotfiles / apply-dotfiles-conflict** are fully isolated: `$HOME` is
  redirected to a throwaway dir, so stow targets a fake `~/.config` and your
  real config is never touched. (They still run `hyprctl reload`, a harmless
  no-op reload of your real config.)
- **apply-packages** is *not* isolated — `pacman` is system-wide. It installs
  the real but inconsequential `sl` package (10 KB, no deps) via `sudo`; undo
  with `apply-packages-cleanup`.
- System apply (`setup-system.sh`) is too invasive to fake and is intentionally
  not covered.

---

## `hk-update.sh`

Sandboxed harness for `hk-update-*` action commands. All scenarios run against
a throwaway git clone at `/tmp/hk-update-test/hyprkarl` (the path deliberately
contains "hyprkarl" so stale-link detection works identically to production).
Package commands use mock installers that print "DRY RUN" instead of calling
pacman, except the two `-real` scenarios which install the inconsequential `sl`
package.

```bash
tests/hk-update.sh setup    # once — build the sandbox clone
tests/hk-update.sh reset    # reset sandbox to a clean state
tests/hk-update.sh status   # show sandbox HEAD, baselines, fakehome
tests/hk-update.sh clean    # delete the sandbox

# Check scenarios (read-only, no $HOME redirect):
tests/hk-update.sh check-no-baseline       # no .commit files (pre-hk-update era)
tests/hk-update.sh check-uptodate          # all baselines == HEAD
tests/hk-update.sh check-pending           # pending dotfiles + package changes
tests/hk-update.sh check-invalid-baseline  # .commit SHA not in git history

# Dotfiles scenarios ($HOME redirected to fake dir):
tests/hk-update.sh dotfiles-clean          # normal restow; verifies symlinks + baseline
tests/hk-update.sh dotfiles-conflict       # real file at stow target -> exits error
tests/hk-update.sh dotfiles-force          # --force overwrites the conflicting file
tests/hk-update.sh dotfiles-force-dirty    # --force with uncommitted config change -> error
tests/hk-update.sh dotfiles-adopt          # --adopt absorbs a user-modified file
tests/hk-update.sh dotfiles-adopt-clean    # --adopt when file already matches repo
tests/hk-update.sh dotfiles-stale          # broken hyprkarl symlink removed during update

# Stale-symlink scenario:
tests/hk-update.sh remove-stale            # two stale symlinks removed; valid ones kept

# Packages scenarios (mock installer unless stated):
tests/hk-update.sh packages-uptodate        # baseline == HEAD -> "already up to date"
tests/hk-update.sh packages-no-baseline     # no .commit -> installs all required (mock)
tests/hk-update.sh packages-added           # new package in list since baseline (mock)
tests/hk-update.sh packages-invalid-baseline # invalid SHA -> falls back to no-baseline
tests/hk-update.sh packages-removed         # interactive: drop prompt (mock remove, safe)
tests/hk-update.sh packages-remove-txt      # interactive: remove.txt prompt (mock, safe)
tests/hk-update.sh packages-real            # REAL: installs 'sl' (10 KB, no deps, sudo)
tests/hk-update.sh packages-real-cleanup    # REAL: removes 'sl'
```

---

## `hk-update-live.sh`

Live stress tests against your **real** hyprkarl install — no isolation.
These check out real old commits, stow real config files, and run real package
operations. They hit code paths that only emerge against actual stow state and
real git history. Recovery is always available via `reset`.

```bash
tests/hk-update-live.sh status   # show HEAD, baselines, waybar state, working tree
tests/hk-update-live.sh reset    # git checkout main + setup-dotfiles.sh

tests/hk-update-live.sh A        # no-baseline: simulates first hk-update run on a
                                  #   stowed system that predates baseline tracking
tests/hk-update-live.sh B        # stale-waybar: checkout old commit → stow waybar
                                  #   → advance → verify broken symlinks are pruned
                                  #   CAUTION: re-stows old config; run reset after
tests/hk-update-live.sh C        # long-hop: write 124964f baseline → verify
                                  #   ~20-package diff + waybar removal prompt
                                  #   Interactive: gum prompts for waybar if installed
tests/hk-update-live.sh D        # invalid-baseline: write fake SHA → verify graceful
                                  #   fallback in check + packages
tests/hk-update-live.sh E        # conflict: plant real file at hyprland.conf →
                                  #   verify failure → verify --force restores symlink
```

### Recovery

If a scenario leaves the system in a broken state:

```bash
tests/hk-update-live.sh reset
# or manually:
git -C ~/.local/share/hyprkarl checkout main
~/.local/share/hyprkarl/setup-dotfiles.sh
```
