# Tests

Focused checks and isolated acceptance harnesses for Hyprkarl. Tests that need
a running Wayland session say so; the others keep their changes under `/tmp`.

## `hk-user-migrate.sh`

Runs the personal-configuration migration against a disposable checkout and
home. It verifies moved personal files, application-link materialization,
preservation of existing files and external symlink trees, terminal sidecars
and theme links, the XDG-state completion marker, deletion-safe idempotence,
and a real destination conflict.

```bash
tests/hk-user-migrate.sh
```

## `hk-theme-runtime.sh`

Builds a shipped theme into disposable XDG state, applies a sparse same-name
source overlay, checks wallpaper precedence and wallpaper-free themes, proves
that failed builds and GTK installation leave the active selector unchanged,
and verifies that GTK installs as marked real files.

```bash
tests/hk-theme-runtime.sh
```

## `hk-shell-modules.sh`

Starts an isolated Quickshell instance with every built-in module disabled and
an explicitly referenced personal QML root. It checks that disabled IPC targets
are absent, the bar system monitor does not start, and the root receives the
resolved configuration, theme, outputs, and overlay open/replace/toggle/close
context. It also imports `Hyprkarl.Modal` from the public QML module and proves
that personal modal content is created on demand and recreated after closing.

It needs a running Hyprland session with at least one output, plus `qs`,
`jq`, `hyprctl`, and the installed Quickshell QML modules. It copies the shell
into a temporary directory and removes it afterward.

```bash
tests/hk-shell-modules.sh
```

## `hk-update.sh`

Runs the updater end to end against a disposable bare remote, clone, home, XDG
state tree, and command mocks. It proves that source review does not move the
checkout, apply advances to the exact reviewed commit, Quickshell stops before
the source changes and restarts afterward, and theme plus GTK output comes from
the updated source. Applying the same revision repairs a missing shipped link.
A deliberately broken theme must leave the old selection and configuration
record intact while retaining the reviewed source marker.

The same harness exercises the single multi-select package-removal review,
one-time acknowledgement for kept and failed removals, Escape cancellation
without a state write, reinstall after a removal cascade, and ordered system
migrations that resume after a failure.

```bash
tests/hk-update.sh
```

It does not change the live checkout, home, package database, system files, or
running Quickshell session.

## `test_update_packages.py`

Unit checks for package-list parsing, additions, category moves, removal
acknowledgement, and atomic state replacement.

```bash
python3 -m unittest tests/test_update_packages.py
```

## `test_display.py`

Unit checks for logical output geometry, normalized display modes, complete
arrangement validation, position-and-transform persistence, overlap rejection,
and one-call live layout application. They also cover all-disabled rejection
plus preview, confirm, and rollback transaction behavior.

```bash
python3 -m unittest tests/test_display.py
```
