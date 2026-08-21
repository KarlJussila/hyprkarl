# Architecture overhaul plan

This plan covers the remaining work after the Quickshell shell foundation. It
replaces the old roadmap's record of completed migrations. Current behavior
belongs in the user guides and reference documentation; this file describes
work that has not shipped yet.

The overhaul has one main goal: a user should be able to change every part of
their system without maintaining routine edits to Hyprkarl's tracked files.
Hyprkarl still supplies a complete default configuration, but it does not own
the user's preferences after installation.

## Agreed end state

The normal installation uses the standard XDG directories for distinct jobs:

```text
~/.local/share/hyprkarl/    Hyprkarl code and shipped defaults
~/.config/hyprkarl/         Personal Hyprkarl configuration and QML
~/.local/state/hyprkarl/    Generated themes, display state, and update records
~/.cache/hyprkarl/          Disposable caches
~/.local/bin/               Personal commands
```

Other applications keep their personal settings in their normal configuration
directories. Hyprkarl does not create a private command directory when
`~/.local/bin` already has that job.

The default checkout stays on the released branch and contains no personal
configuration. A personal Git branch is optional and only needed when someone
wants to modify Hyprkarl's shipped implementation. It is no longer the normal
customization workflow.

The repository remains an installation on top of CachyOS and Hyprland. This
work does not turn Hyprkarl into a distribution, package manager, multi-user
provisioner, or plugin marketplace.

## Rules for the finished design

- Users own their configuration, scripts, QML, and system.
- A documented path is the update-friendly route, not a restriction.
- Hyprkarl validates the data it must interpret, but it does not sandbox or
  allowlist owner-authored code.
- Shipped files provide defaults and stable entry points. Settings commands do
  not modify those files.
- Generated files have one writer and are kept out of Git.
- Disabled shell modules create no windows, services, timers, watchers, or IPC
  targets.
- Each application uses the simplest customization method it supports. There
  is no universal configuration merger.
- Updates never need a destructive "adopt" or "force" path during ordinary
  use.

## Phase 3: give every managed application a user-owned configuration path

### Goal

Let users customize every application Hyprkarl configures without routinely
editing an upstream-owned file.

### Method

Audit every top-level directory under `config/`, including Alacritty, Btop,
Fastfetch, Fish, Foot, Ghostty, Hyprland helpers, Kitty, Neovim, Qt, UWSM,
portals, Yazi, and any configuration added before this phase lands.

Choose the simplest method each application supports:

1. Prefer a native include or override file. Keep the tracked entry point
   small and load a real user-owned file from the application's normal
   configuration directory.
2. If the application supports a complete alternate file or directory, allow
   the user to select or provide it directly.
3. If the application has neither mechanism, install a real starting file only
   when absent and let the user own it afterward. Do not overwrite it during
   updates.

Do not parse and merge unrelated configuration languages in Hyprkarl. Do not
add a generic overlay framework merely to make every row in the audit look the
same.

GTK theme payloads remain a deliberate exception. Hyprkarl materializes those
generated files because GTK theme discovery and assets have been unreliable
through symlinked theme trees. Users change the theme source rather than the
generated GTK copy.

### Required audit record

For each managed application, record:

- the shipped entry point;
- the personal file or directory;
- whether the application merges it or it replaces the default;
- which command, if any, writes it;
- whether a restart or new session is required;
- which files Hyprkarl may replace during an update.

This belongs in `docs/configuration-map.md` once implemented. The plan should
not guess at include behavior before checking the installed application.

### Acceptance

- Every managed application's documentation names a practical personal path.
- Ordinary preference changes leave the Hyprkarl checkout clean.
- No settings menu or `hk-*` command writes a tracked configuration file.
- A full replacement remains possible when a small override cannot express
  the desired change.
- Existing user files survive setup and update.

Personal package lists are not part of this phase. Users may install any extra
packages normally. Add declarative personal lists later only if someone wants
Hyprkarl to reproduce them on another machine.

## Phase 4: make every shell module optional and replaceable

### Goal

Allow users to keep any subset of the built-in Quickshell shell or disable it
all and supply their own composition.

### Built-in module switches

Add clear enable switches for at least:

- the bar;
- feature panels and their feature-owned services;
- notifications;
- the OSD;
- polkit authentication;
- the command menu;
- the launcher and open-with picker;
- the calculator;
- the wallpaper picker.

The final JSON grouping should follow actual runtime ownership. It does not
need one arbitrary flag per QML file.

Disabling a module prevents construction of its windows, singleton state,
timers, watchers, background commands, service registrations, and IPC targets.
For example, disabling notifications must allow another notification daemon to
register, and disabling polkit must allow another authentication agent.

Applying module switches may require `hk-shell restart`. Live creation and
destruction are not required unless Quickshell already makes that simpler.

### User QML

The application-wide personal QML file must load independently of the built-in
bar. Give it a small documented object containing:

- the resolved shell configuration;
- the active theme data, including user-defined values;
- the current output list;
- notification positioning support;
- the currently requested overlay name, output, and values;
- methods to open, replace, toggle, and close an overlay.

This completes the menu behavior that is currently only half documented. A
menu entry can request a user-defined overlay by name, and personal QML can
actually observe that request and display its window.

Built-in overlays should use the same overlay controller instead of a private
shortcut. Do not add plugin discovery, manifests, registration, or permission
checks.

### Authoring examples

The documentation and checks must cover:

1. Disabling one built-in module, such as notifications, and using an external
   replacement.
2. Adding one personal overlay and opening it from a menu entry.
3. Disabling the built-in bar and supplying a personal bar with reactive
   notification positioning.
4. Disabling every built-in window and running a complete personal QML
   composition.

### Acceptance

- Every listed built-in module can be disabled independently.
- Disabled modules are inert and release exclusive system services.
- The custom QML root works when the built-in bar is disabled.
- A user-defined menu overlay opens, receives its values, and closes through
  the documented object.
- Owner-authored QML receives normal QML errors without Hyprkarl trying to
  sandbox it.

## Phase 5: replace the update process

This phase follows the ownership and theme work. The updater should automate
the finished model, not preserve the old one.

### Source updates

The normal installation uses a clean checkout of the released branch. The
updater:

1. Fetches the explicitly configured canonical Hyprkarl remote and branch.
2. Shows the incoming release, commits, and relevant changes.
3. Fast-forwards the normal checkout after confirmation.
4. Leaves personal files below `~/.config` untouched.

Do not infer the upstream branch from the active branch's tracking branch. A
person maintaining a fork may configure a different source and merge or rebase
it themselves. The updater should identify that situation clearly rather than
pretending it is the ordinary path.

Remove routine adopt and force behavior. If a managed link meets an unrelated
real file, stop and show the exact paths. The owner decides what to move or
keep.

### Applying configuration

Applying an update is separate from fetching it. Configuration application:

1. Restows shipped entry points and removes stale Hyprkarl-owned links.
2. Runs any pending personal-path migrations.
3. Rebuilds the currently selected theme from the updated source and personal
   theme files.
4. Validates and atomically activates the new artifact.
5. Installs the GTK payload.
6. Reloads affected applications and services.
7. Records success only after the complete operation succeeds.

An update test must change the source of the active theme, apply the update,
and prove that both the selected artifact and installed GTK copy contain the
new result. A failed rebuild must leave the prior selection active and the
configuration update pending.

### Package changes

Keep snapshots of the last applied Hyprkarl package lists under:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/update/
```

Do not depend on an old Git commit remaining available.

When packages are added, show and install the additions. When packages are
removed from Hyprkarl's lists:

1. Present the full removal list with every package initially selected.
2. Let the user uncheck packages they want to keep.
3. Attempt removal of the selected packages.
4. Record the entire removal change as handled, including packages the user
   kept.
5. Do not present that same removal change again on a later update.

A failed removal is reported with enough information for a manual retry, but
the updater does not nag about the same change forever. Packages that the user
keeps become ordinary user-installed packages.

### System migrations

Replace routine reruns of `setup-system.sh` with ordered one-time migrations:

```text
system/migrations/<id>-<description>
```

Initial setup runs every required migration. Updates show pending migrations
and request privilege before running them. Record a migration under XDG state
only after it succeeds.

New migrations make one focused change. They do not rerun every old SDDM,
logind, PAM, firewall, Docker, or security operation because an unrelated
system setting changed.

Keep an explicit repair or reconciliation command only for a real supported
recovery task. It must not become the ordinary update path.

### Update records

Move all update records from `config/hyprkarl/update/` to XDG state. Store the
information needed for the next operation, such as:

- the last applied source revision;
- snapshots of applied package lists;
- handled package-removal changes;
- completed system migration IDs;
- the last successfully applied configuration revision or content hash.

These files describe this machine. They do not belong in the checkout or in a
personal configuration backup.

### Acceptance

- Normal updates require no personal Git branch and no stash operation.
- Source review, configuration application, packages, and privileged system
  migrations have clear separate steps.
- An interrupted operation does not claim success.
- A package-removal change is presented once and remains acknowledged when the
  user keeps some packages.
- System updates do not rewrite unrelated `/etc` configuration.
- `post-update` hooks run only after every selected update step succeeds, and
  the command states clearly if the main update succeeded but a hook failed.

## Phase 6: finish the remaining shell cleanup

### Reuse the shared overlay behavior

Change `MenuWindow.qml` to use the frame and momentum scrolling already shared
by the launcher, calculator, and wallpaper picker. Keep menu-specific search,
hierarchy, rows, selection, keyboard navigation, and Back behavior in the menu
feature.

Preserve top and bottom placement, focused-output routing, outside-click and
Escape dismissal, scroll reset, pointer selection, and the current compact
appearance. Do not create a larger generic window framework.

### Investigate Quickshell reload behavior

Reproduce the remaining reload crash or abort against the Quickshell package
currently installed from the CachyOS repositories. Record a minimal reproducer
and separate Hyprkarl-owned lifetime mistakes from upstream Qt or Quickshell
failures.

Fix Hyprkarl code when it owns the failure. If the minimal reproducer fails in
upstream code, keep the dated evidence and avoid building a compatibility
layer around it.

Do not describe one Quickshell package version as permanently pinned. The
supported target is the version currently installed by Hyprkarl's package
lists and verified by its checks.

## Phase 7: clean up documentation and agent instructions

Documentation changes land with each behavior change. After the implementation
phases, make one final pass so each document has one job:

- The root README introduces Hyprkarl, installation, and links to task guides.
- `docs/using-hyprkarl.md` explains ordinary user tasks.
- `docs/configuration-map.md` names every shipped, personal, generated, and
  system-managed path.
- `docs/shell-configuration.md` documents shell JSON, module switches, and
  personal QML.
- `docs/menu-configuration.md` documents entries, dynamic commands, and custom
  overlays.
- `docs/themes.md` documents integrated theme authoring and generated state.
- `docs/updating.md` documents source review, apply, packages, and migrations.
- `config/quickshell/README.md` helps contributors find implementation code and
  checks without copying the public configuration manual.

Move any still-useful requirements out of `docs/shell-product-brief.md` to the
document that owns them, then delete the brief if nothing unique remains.
Remove stale Rofi instructions, old branch recommendations, adopt and force
workflows, and permanent Quickshell pinning claims.

Trim the root and Quickshell `AGENTS.md` files after the code settles. Keep
current safety rules, directory ownership, framework lifetime facts, extension
rules, and required checks. Remove completed migration history, obsolete
warnings, copied architecture descriptions, and exact visual values better
kept beside theme data or components.

## Delivery order

Implement the work as reviewable changes in this order:

1. Audit every managed application and add its personal configuration method.
2. Add shell module switches and complete the personal QML overlay controls.
3. Replace the updater, package-removal flow, and system setup with the new
   source, apply, and migration model.
4. Reuse the shared menu frame and investigate the remaining reload failure.
5. Finish the documentation and agent-instruction cleanup.

Documentation and focused tests belong in each change. The final cleanup is
for consolidation, not for postponing behavioral documentation.

## Work deliberately left outside this overhaul

These remain possible later projects, but they do not block the ownership and
update work:

- declarative personal package lists;
- vertical bars;
- a Quickshell lock screen after the installed version passes the required
  session-lock tests;
- clipboard, emoji, and image-selection windows;
- display mode, arrangement, and external DDC brightness controls;
- further visual polish already noted in the shell backlog.

## Completion check

The overhaul is complete when a normal user can:

- update a clean Hyprkarl checkout without a personal branch;
- keep every ordinary preference in a user-owned file;
- replace any managed application configuration without update conflicts;
- build and modify themes without a second repository;
- disable any built-in shell module and replace it with personal QML or an
  external program;
- review package removals once and keep selected packages without repeat
  prompts;
- apply one-time system changes without rerunning unrelated setup; and
- identify every generated or replaceable file in the configuration map.
