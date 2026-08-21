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
- Disabled built-in shell groups create none of the windows, services, timers,
  watchers, or IPC targets they own. The panels group only owns the popup host;
  bar status widgets remain until the owner removes them from the layout.
- Each application uses the simplest customization method it supports. There
  is no universal configuration merger.
- Updates never need a destructive "adopt" or "force" path during ordinary
  use.

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
Remove stale Rofi instructions and permanent Quickshell pinning claims.

Trim the root and Quickshell `AGENTS.md` files after the code settles. Keep
current safety rules, directory ownership, framework lifetime facts, extension
rules, and required checks. Remove completed migration history, obsolete
warnings, copied architecture descriptions, and exact visual values better
kept beside theme data or components.

## Delivery order

Implement the work as reviewable changes in this order:

1. Reuse the shared menu frame and investigate the remaining reload failure.
2. Finish the documentation and agent-instruction cleanup.

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

The remaining overhaul is complete when:

- the command menu uses the shared overlay frame and scrolling behavior without
  losing its compact layout or navigation;
- the Quickshell reload failure has a minimal reproducer and any Hyprkarl-owned
  lifetime bug is fixed; and
- the final documentation pass removes retired plans and leaves one current
  owner for each configuration and operational contract.
