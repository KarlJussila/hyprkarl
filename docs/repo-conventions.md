# Repo Conventions

This guide is for contributors changing Hyprkarl's shipped code, defaults, or
installation behavior in the checkout. For personal configuration and
extensions, use [Extending Hyprkarl](extending-hyprkarl.md).

## Readability First

Hyprkarl favors direct, readable configuration over clever abstraction.

That means:

- keep the files people are likely to edit easy to find
- prefer small scripts with one clear path through them
- prefer a plain config file when that is enough
- document what changed for the user or editor when you add or change behavior

## Trust User-Owned Code

The documented user paths and extension contracts are the supported,
update-friendly route, not a sandbox. Hyprkarl does not block user-authored
QML, scripts, or configuration merely because it goes beyond that contract.
Off-contract changes may work, and users are free to accept the maintenance
and debugging cost when they do. When they fail, Hyprkarl should add concise
context for failures it can identify cheaply, then let the underlying runtime
report the user's error.

Hyprkarl will not have a plugin marketplace: personal code is referenced
explicitly by path, and nothing is discovered, installed, or approved. What
personal code may rely on is listed under [What updates keep
stable](updating.md#what-updates-keep-stable).

## Put Changes in the Right Layer

The [configuration map](configuration-map.md#hyprkarls-files) describes each
part of the checkout. Appearance belongs in the theme compiler's defaults and
templates, behavior in `config/` or `defaults/`, and commands in `bin/` (see
`bin/AGENTS.md`). Never ship or edit a file in a user's own locations.

## Stateful Paths

The current theme and wallpaper live outside Git under
`${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/current/`. Everything that
reads the active theme, including shipped and starting configs, points at
`current/theme` there.

Theme sources under `themes/` are upstream-owned; personal themes, same-name
overlays, wallpaper additions, and removal markers belong under
`${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/themes/`.
Switching themes builds into a new directory before moving the `current/theme`
symlink, so a failed build never changes the active theme.

`~/.local/share/themes/hyprkarl/` is derived runtime output, not an editing
surface. It is a copy of the active build's `gtk-theme/` because GTK does not
reliably follow symlinked theme directories.

## Branches and Releases

- `main` is the released branch: what a fresh install clones and what the
  default `hk-update sync` source points to.
- `develop` is the integration branch. Work lands there first and is merged to
  `main` when it's ready to ship.
- A release is an annotated tag `vX.Y.Z` on `main`, cut together with a
  hand-written entry in `CHANGELOG.md`. Nothing lands on `main` except
  releases, so `main` always fast-forwards to `develop` and the release is cut
  there, without checking out `main`:

  ```bash
  # on develop: move the Unreleased notes under "## vX.Y.Z (date)", commit
  git tag -a vX.Y.Z -m "Hyprkarl vX.Y.Z"
  git push origin develop develop:main vX.Y.Z
  ```

- The version number follows [Versions](updating.md#versions): major for a
  change to anything under [What updates keep
  stable](updating.md#what-updates-keep-stable), which is also called out in
  the changelog and comes with a migration when Hyprkarl can convert the
  user's files; minor for additions; patch for fixes and adjustments.

The normal checkout stays on `main`. `hk-update sync` fetches and pins an exact
confirmed `origin/main` commit without moving the checkout; `hk-update apply`
performs the fast-forward. A custom branch is maintained with ordinary Git,
then applied with `hk-update apply`.

## Stow Behavior

Everything under `config/` is linked into `~/.config/` through GNU Stow.
Files under `defaults/` are found through the XDG search paths. Files under
`templates/config/` and `templates/starter/` are copied to their normal
`~/.config/` paths by `hk-config-seed`, which never overwrites a file that
exists. Personal configuration is read from the application's own directory
or `${XDG_CONFIG_HOME:-$HOME/.config}/hyprkarl/`, as documented in
[Configuration Map](configuration-map.md). It is never stowed or owned by a
Git branch.

- editing an existing linked or `defaults/` file needs no extra step
- editing a template changes only machines that do not have the file yet
- editing a real application config under `~/.config/` is immediate and
  update-safe
- adding or removing a file under `config/` requires re-stowing with
  `hk-update apply`

## Migrations

When a release needs a one-time change on each machine, add an executable
script to `migrations/` named with the next number (`060-...`). `hk-update
apply` runs pending migrations in order, after packages and before
configuration, and records each one only when it exits successfully. Use them
for system changes (call `sudo` for those lines) and for converting a user's
personal config when a setting is renamed or removed.

Migrations also run on fresh installs, where there may be nothing to convert,
so make each one safe there: check before changing, and succeed when nothing
needs doing. Never rewrite a personal file beyond the change the migration
exists for.

For a new application integration, pick the first of these the application
supports, so Hyprkarl's defaults keep reaching users:

1. a config under `config/` that loads a personal file last, with an empty
   starting copy of that file at its `~/.config` path under
   `templates/config/`;
2. a default under `defaults/config/` or `defaults/share/`, found through
   `XDG_CONFIG_DIRS` or `XDG_DATA_DIRS`, which a user's own file replaces;
3. output of the theme, for anything that is appearance; when the
   application can only read it from its own folder, add a link into
   `current/theme` under `config/`;
4. as a last resort, a starting config under `templates/starter/<app>/`.

New files under `templates/config/` reach existing machines on their next
update. A starting config does not, since those machines already have one.

## Contributor guides

- [Command script style](shell-style.md) for shipped commands and dispatchers
- [Quickshell project guide](../config/quickshell/README.md) for shell code
- [Theme compiler guide](../theme-generator/README.md) for generated consumers
- [Tests](../tests/README.md) for validation
