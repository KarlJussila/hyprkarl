# Tests

Focused checks and isolated acceptance harnesses for Hyprkarl. Tests that need
a running Wayland session say so; the others keep their changes under `/tmp`.

## `hk-config-seed.sh`

Seeds starting configs into a disposable home. It checks that an existing
application config is left alone, that an unrelated file does not block a
seed, that links are preserved, and that a second run never overwrites a
file.

```bash
tests/hk-config-seed.sh
```

## `hk-theme-runtime.sh`

Builds a shipped theme into disposable XDG state, applies a sparse same-name
source overlay, checks wallpaper precedence and wallpaper-free themes, proves
that a failed build leaves the active theme unchanged, and checks that the GTK
theme is a real copy and older builds are deleted.

```bash
tests/hk-theme-runtime.sh
```

## `hk-shell-modules.sh`

Starts an isolated Quickshell instance with every built-in module disabled and
an explicitly referenced personal QML root. It checks that disabled IPC targets
are absent, screenshot focus coordination remains available, the bar system
monitor does not start, and the root receives the resolved configuration,
theme, outputs, and overlay
open/replace/push/back/toggle/close context. It also imports `ui.modal.Modal`
from the public QML module and proves
that personal modal content is created on demand and recreated after closing.
A second pass starts the built-in bar without panels, with polled, streamed,
JSON, and button command widgets, and checks for runtime errors.

It needs a running Hyprland session with at least one output, plus `qs`,
`jq`, `hyprctl`, and the installed Quickshell QML modules. It copies the shell
into a temporary directory and removes it afterward.

```bash
tests/hk-shell-modules.sh
```

## `hk-shell-launch.py`

Exercises the production launcher and widget command with real `uwsm-app`
launches. It checks their process groups, preserves the widget's output context,
and stops an isolated test shell to prove both launched processes survive.

It needs the running UWSM session and user systemd manager. It briefly creates a
temporary desktop entry and transient test units, then removes them. It opens
no windows and leaves the production shell running.

```bash
python3 tests/hk-shell-launch.py
```

## `tst_menu_model.qml`

Runs the pure command-menu model under Qt Test. It checks direct ordering,
global descendant search, parent-path details, disabled-row filtering, loaded
provider rows, and cycle-safe traversal.

```bash
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner \
  -input tests/tst_menu_model.qml
```

## `tst_toggle_indicator.qml`

Checks that the shared toggle indicator reproduces the theme defaults, resolves
sparse per-instance geometry over them, and renders the trackless `mark`
variant as one stationary thumb.

```bash
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner \
  -input tests/tst_toggle_indicator.qml
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
without a state write, reinstall after a removal cascade, and ordered
migrations inside `apply` that resume after a failure. A failed apply still
starts Quickshell again.

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
