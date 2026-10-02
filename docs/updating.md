# Updating Hyprkarl

Hyprkarl separates reviewing upstream source from changing the live checkout.
The normal installation stays on the released branch with personal settings
outside the repository.

## Normal update flow

Run the complete workflow with:

```bash
hk-update all
```

It runs these steps in order and stops at the first failure:

1. `hk-update sync` fetches the configured source, shows the incoming commits
   and file summary, and asks whether to pin that exact revision.
2. `hk-update apply` fast-forwards to the pinned revision and applies shipped
   configuration.
3. `hk-update packages` reviews removals once and installs new requirements.
4. `hk-update system` runs pending one-time system migrations.
5. `hk-hook-run post-update` runs personal post-update hooks.

The update menu launches the same `hk-update all` command in a terminal. System
package upgrades remain separate; use `hk-pkg-upgrade` for `paru -Syu`.

## Review source without applying it

```bash
hk-update sync
```

`sync` fetches the remote and branch configured in the checkout. Fresh setup
records `origin` and `main`; change them with ordinary Git configuration when
needed:

```bash
git -C ~/.local/share/hyprkarl config hyprkarl.updateRemote origin
git -C ~/.local/share/hyprkarl config hyprkarl.updateBranch main
```

Before staging a newer commit, the command requires a clean tracked tree on the
configured branch. It prints the incoming commit list and diff summary, then
asks for confirmation. Approval writes the exact commit to XDG state. It does
not move `HEAD`, restow files, or restart anything.

Running `sync` again can review a newer revision. If the checkout is already at
the fetched revision, the command marks that revision pending when its
configuration has not been applied, or clears the marker when it has.

## Apply reviewed source and configuration

```bash
hk-update apply
```

`apply` requires a clean tracked checkout. If `sync` pinned a newer revision,
it also confirms that the checkout is on the expected branch and can
fast-forward. It then:

1. Stops the running Hyprkarl Quickshell instance.
2. Fast-forwards to the reviewed commit.
3. Runs pending personal-configuration migrations.
4. Checks for Stow conflicts, restows shipped entry points, and removes stale
   links into the checkout.
5. Rebuilds and validates the selected theme from the current shipped source
   and personal theme source. Activation also refreshes the real-file GTK
   payload.
6. Restores the wallpaper, reloads Hyprland, terminals, and Btop, then restarts
   Quickshell if it was running before the update.
7. Records the applied configuration revision and clears the pending source
   marker.

The configuration revision is recorded only after all configuration and reload
work finishes, then the pending source marker is cleared. A failed theme build
leaves the previous generated theme selected. The reviewed source marker
remains so the failed apply can be retried after the problem is fixed.
If source already advanced while Quickshell was stopped, the shell remains
stopped rather than starting from an incompletely applied tree. The retry
remembers that it owes the session a restart and starts Quickshell after the
apply completes.

`apply` also works without a pending source revision and always reapplies the
current committed checkout. Use it after committing shipped changes or
manually updating a custom branch, and to repair missing Stow links or rebuild
the current generated theme at the same revision.

### Stow conflicts

Hyprkarl does not adopt or overwrite an unrelated real file at a managed Stow
path. `hk-update check` and `hk-update apply` list the conflicts. Move, rename,
or otherwise resolve those files yourself, then run `hk-update apply` again.
Personal configuration under `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/` and
user-owned application configs are not Stow targets.

## Custom branches and forks

A personal branch is unnecessary for ordinary configuration. Use one only when
you intend to maintain changes to Hyprkarl's shipped code or defaults.

`hk-update sync` does not merge into a custom branch. Fetch and merge or rebase
your chosen source with Git, resolve the changes as the branch owner, then run:

```bash
hk-update apply
hk-update packages
hk-update system
hk-hook-run post-update
```

This keeps automatic source movement limited to the clean released-branch
case. The apply, package, and migration commands still work on a manually
maintained checkout. Run the hook command only after the preceding steps
succeed.

## Review package changes

```bash
hk-update packages
```

Package state is a snapshot of the last applied and last reviewed lists, not a
Git commit. The command reads `packages/pacman.txt`, `packages/aur.txt`, and
`packages/remove.txt`.

New missing requirements install automatically. Packages removed from the
required lists or newly added to `remove.txt` appear in one multi-select list,
selected by default. Uncheck anything you want to keep. Hyprkarl records the
whole removal change as reviewed, including unchecked packages and removals
that need a manual retry, so the same change is not presented again.

Pressing Escape cancels the review without changing package state. If a
selected removal fails, the command prints an `hk-pkg remove ...` retry command
and exits before installing additions.

Package list lines may contain comments:

```text
packages/pacman.txt    pacman requirements
packages/aur.txt       AUR requirements
packages/remove.txt    packages to offer for removal, with optional reasons
```

An inline comment in `remove.txt` becomes the reason shown in the review.

## Run system migrations

```bash
hk-update system
```

System changes live as focused executable migrations under
`system/migrations/`. The command lists every pending migration in lexical
order, asks once for confirmation, acquires administrator access, and runs them
in that order. It records each migration only after that file succeeds. A retry
therefore resumes at the first unfinished migration instead of rerunning every
older system setup action.

`setup-system.sh` calls this same migration workflow during installation.

## Check pending work

```bash
hk-update check
```

This read-only report shows:

- the exact reviewed source revision, if one is pending;
- the current checkout and last successfully applied configuration revision;
- Stow or GTK destinations that would block configuration application;
- package-list additions and removal changes awaiting review; and
- pending system migration IDs.

## Remove stale links only

```bash
hk-update remove-stale
```

This removes broken symlinks whose resolved targets point into this checkout,
then prunes empty directories left below the managed roots. Normal
`hk-update apply` includes this cleanup after restowing.

## Update state

Machine update state lives under:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/update/
  configuration.revision
  pending-source.revision
  packages.json
  restart-shell-after-apply
  system-migrations/<migration-id>
```

`restart-shell-after-apply` is a temporary recovery marker. It exists only
when an interrupted or failed source transition left Quickshell intentionally
stopped; a successful retry removes it after restarting the shell.

`uninstall.sh` removes the machine update-state directory. Do not put personal
configuration there. Personal settings belong under `~/.config`, while this
directory records what Hyprkarl has applied on this machine.
