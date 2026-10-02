# Updating Hyprkarl

An update has two steps: review what is coming, then apply it. Your personal
configuration lives outside the checkout, so an update never touches it.

```bash
hk-update all
```

This runs `hk-update sync`, then `hk-update apply`, then your `post-update`
hooks, and stops at the first failure. When new commits are waiting, an update
icon appears in the bar; clicking it, or the update menu entry, runs the same
command in a terminal. `hk-version` prints the installed release. System packages are separate: `hk-pkg-upgrade` runs `paru -Syu`.

## Review: `hk-update sync`

`sync` fetches the configured branch, shows what the update adds to
`CHANGELOG.md` and the incoming commits, and asks whether to stage that exact
revision. Staging records it in XDG state; nothing in the checkout changes
yet. It needs a clean checkout on the configured branch. Running `sync` again
reviews a newer revision.

Fresh installs follow `origin/main`. To follow another remote or branch:

```bash
git -C ~/.local/share/hyprkarl config hyprkarl.updateRemote origin
git -C ~/.local/share/hyprkarl config hyprkarl.updateBranch develop
```

## Apply: `hk-update apply`

`apply` brings the machine to the staged revision:

1. stops Quickshell, which runs from the checkout;
2. fast-forwards to the staged revision;
3. installs new required packages and reviews retired ones
   (`hk-update packages`);
4. runs pending migrations;
5. copies starting configs for applications you have none of
   (`hk-config-seed`);
6. restows shipped links and removes stale ones;
7. rebuilds the selected theme;
8. restores the wallpaper and reloads Hyprland, terminals, and Btop;
9. starts Quickshell again, whether or not the steps succeeded.

The applied revision is recorded only when every step succeeds. If one fails,
the staged revision stays staged: fix the problem and run `hk-update apply`
again. Steps that already finished are safe to repeat.

With nothing staged, `apply` reapplies the current checkout. Use that to repair
missing links, rebuild the theme, or apply a custom branch you merged by hand.

### Stow conflicts

Hyprkarl does not overwrite a real file at a path it links. `hk-update check`
and `apply` list any such conflict; move or rename the file and run `apply`
again.

## Packages: `hk-update packages`

`apply` runs this, and you can run it alone. It compares
`packages/pacman.txt`, `aur.txt`, and `remove.txt` with what it recorded last
time. Missing required packages install automatically, together with a full
system upgrade, since installing from an out-of-date package database fails. Packages dropped from
the lists or added to `remove.txt` appear once in a checklist, all selected;
uncheck any you want to keep. The comment on a `remove.txt` line is the reason
shown. Escape cancels without recording anything. Once reviewed, a removal is
not offered again, even if you kept the package. A retired package that another
installed package still needs is not offered; Hyprkarl marks it as a
dependency instead, so pacman removes it once nothing needs it.

## Migrations

Some updates need a one-time change on each machine: enabling a service,
writing a file under `/etc`, or converting a renamed setting in your personal
config. These are numbered scripts in `migrations/`. `apply` runs the ones this
machine has not run yet, in order, after packages and before configuration.
Each is recorded only when it succeeds, so a failed one runs again on the next
`apply`. Scripts that change the system ask for your password through `sudo`.

## Custom branches

You do not need a branch for personal configuration. If you maintain changes
to Hyprkarl itself on a branch, `sync` will not merge for you: fetch and merge
or rebase with Git, then run `hk-update apply`.

## Checking and cleanup

`hk-update check` reports, without changing anything, the staged revision, the
last applied revision, Stow conflicts, package changes waiting for review, and
pending migrations.

`hk-update remove-stale` removes broken links into the checkout. `apply` does
this too.

## Update state

```text
~/.local/state/hyprkarl/update/
  configuration.revision    last revision applied successfully
  pending-source.revision   revision staged by sync
  packages.json             package lists as last applied and reviewed
  migrations/<id>           one file per migration that has run
```

`uninstall.sh` deletes this directory. Keep personal configuration out of it.
