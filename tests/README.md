# Tests

Manual test harnesses for hyprkarl. These are interactive sandboxes, not an
automated CI suite — you run a scenario, drive the TUI by hand, and observe.

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
