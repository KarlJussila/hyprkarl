# Menu Configuration

Hyprkarl's static command hierarchy is rendered by Quickshell and defined as
data. The shipped definition lives at `defaults/menu.json`; personal changes
belong in the optional `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/settings/menu.json` override.

The shell watches both files and merges your object over the shipped one, key
by key, so you only write the menus and entries you add or change. Edits apply
live. If your file does not parse, `hk-shell logs` shows the error and the
shipped menu runs until you fix it. Deleting
`${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/settings/menu.json` returns to
the shipped definition.

## Document Shape

```json
{
  "menus": {
    "main": { "title": "Main Menu" },
    "tools": { "title": "Tools" }
  },
  "entries": {
    "main.tools": {
      "parent": "main",
      "order": 40,
      "icon": "󰒓",
      "label": "Tools",
      "action": { "type": "menu", "menu": "tools" }
    },
    "tools.example": {
      "parent": "tools",
      "order": 10,
      "icon": "󰆍",
      "label": "Example",
      "action": { "type": "command", "command": "example-command" }
    }
  }
}
```

`hk-shell menu toggle <id>` opens a menu by ID; the bar's menu button opens
`main` and passes its output so the menu appears on the same monitor.
Each object in `menus` supplies a title and may also define `sourceCommand`
plus `emptyLabel` for entries discovered when that menu opens. Every menu has
an in-process fuzzy-search field. It searches the current menu and every
declared descendant, keeps direct matches before deeper matches, and shows the
parent path on deeper rows. Default-width menus hide that field and its divider
until printable input reveals them; `search` and `reference` widths keep theirs
visible, as do the launcher and calculator overlays. `widthRole` may be `default`, `search`, or
`reference` and selects the corresponding themed width. Searching keeps that
width. `entryAlignment` may be `left`, `center`, or `right`; it defaults to
`center`. Each object in `entries` has a stable dotted ID and:

- `parent`: the menu containing the entry
- `order`: numeric display order; IDs break ties deterministically
- `label`: displayed text
- `icon`: optional displayed glyph
- `enabled`: optional boolean; `false` removes the entry from rendering
- `disabled`: optional boolean; `true` leaves the entry dimmed in its own menu
  but prevents selection and omits it from search results
- `checkedCommand`: optional command evaluated when the menu opens; exit zero
  replaces the icon with a check mark
- `action`: a `menu` destination, shell `command`, Quickshell `surface`, or
  `dismiss` action for an informational row

Commands launch through `uwsm-app -- bash -c` after the menu closes. Keep
interaction-heavy work in a separate script and reference it from the data;
personal commands belong in `~/.local/bin/`. The menu definition owns
navigation. Themes, live keybindings,
Nerd Font icons, Docker services, and every fingerprint choice are dynamic
Quickshell menus. The app launcher, open-with chooser, calculator, and
wallpaper carousel are dedicated Quickshell overlays because their
rows and actions do not fit the command-menu data contract. Package pickers
retain their focused terminal interfaces.

A `surface` action switches directly to another Quickshell overlay without
starting a process or calling back through shell IPC. The menu remains its
return destination until the new overlay closes or replaces the request:

```json
{
  "type": "surface",
  "surface": "wallpaper",
  "parameters": { "action": "set" }
}
```

The shipped surface IDs are `launcher`, `calculator`, and `wallpaper`.
`wallpaper` accepts an `action` parameter of `set` or `remove`; the other two
need no parameters. The surface ID and optional parameter object are passed
through as authored, so a user composition may respond to its own surface IDs
and parameter vocabulary without changing the menu engine. In the launcher,
Left on an empty query returns to the menu that opened it. A
directly opened launcher closes because it has no return destination.

For example, this personal entry asks a user root to show a dashboard on the
selected output:

```json
{
  "entries": {
    "main.dashboard": {
      "parent": "main",
      "order": 45,
      "icon": "󰨇",
      "label": "Dashboard",
      "action": {
        "type": "surface",
        "surface": "dashboard",
        "parameters": { "section": "weather" }
      }
    }
  }
}
```

The action replaces the visible menu with `dashboard` while retaining the menu
as its return destination. An application-wide
user root reads `context.overlayName`, `context.overlayOutput`, and
`context.overlayValues`, creates its own window for that name, and calls
`context.backOverlay()` to return or `context.closeOverlay()` to close the
whole request chain. See [Application-wide user
QML](shell-configuration.md#application-wide-user-qml) for the full context.

If `modules.menu` is disabled, the menu IPC target and its windows do not
exist. Disabling another built-in module does not rewrite menu rows that point
to it. Hide a no-longer-useful shipped row with `enabled: false`, or replace it
with an entry for the program or personal overlay that takes over that job.

Keyboard navigation skips disabled rows and keeps the selected row immediately
in view, including when wrapping between the first and last entries. Moving
the pointer selects the row beneath it, but a stationary pointer does not
override keyboard selection as the list moves. Wheel and touchpad gestures
scroll the list directly with shared kinetic behavior. Repeated gestures in the
same direction build momentum through a soft cap. Starting another gesture
pauses existing momentum so the gesture has direct control. On release, a
recency-weighted velocity from that gesture is added through the soft cap.
Reversing within the gesture clears both the retained momentum and its earlier
samples. Opening a fresh menu or changing a search highlights the first result
as the Enter default and visible selection while keeping the list at the top.
Typing in a default-width menu reveals its search field; clearing it hides the
field again. Returning from a submenu or the
launcher restores the previous query, selected entry, and scroll position.

Use `checkedCommand` only for a cheap external state probe whose status belongs
in the menu. Checks run when the menu opens; they are not long-running monitors
and do not replace shell-native service state in feature panels.

A `sourceCommand` must print one JSON array and exit. Each array item has a
stable `id`, a `label`, optional `icon`, `searchText`, and `disabled` fields,
and a `command`, `menu`, `surface`, or `dismiss` action; array order is display
order. The shell shows `emptyLabel` for an empty array, and reports output that
does not parse in the menu and in `hk-shell logs`.
Sources refresh on every open and when returning to a dynamic parent, so
filesystem, hardware, and service state do not go stale. Domain commands own
discovery: for example, `hk-fingerprint menu-entries remove` supplies only
enrolled fingers and `hk-docker menu-entries install` supplies only missing
services. Docker service manifests are loaded independently; a broken shipped
manifest is logged and skipped without preventing the other services from
appearing.

Global search walks the declared static hierarchy. It includes provider rows
already loaded for the current menu, but it does not start every descendant
provider merely because the owner typed a query. Selecting a dynamic submenu
loads its current rows through the normal provider boundary.

The shell runs both providers and command actions with `bash -c`, inheriting
the session environment without starting a login shell. A dynamic destination
is revealed only after its complete result has been parsed, so
users never interact with a partially populated model. Keep providers fast by
doing only the discovery their rows require. If a large catalog changes only
when an update command runs, generate provider-ready JSON during that update
and make `sourceCommand` print the finished file; the shipped icon picker uses
this pattern. Runtime caching is not part of the menu contract.

Write providers that construct or transform entries in Python. Lists and
dictionaries map directly to the menu contract, and the standard `json` module
handles quoting and Unicode without shell string manipulation. Bash remains a
good fit when a provider only prints an already-generated JSON file.

For example, a personal dynamic menu needs only a menu declaration, an entry
that navigates to it, and a provider on `$PATH`:

```json
{
  "menus": {
    "projects": {
      "title": "Projects",
      "sourceCommand": "my-project-menu-entries",
      "widthRole": "search",
      "emptyLabel": "No projects"
    }
  },
  "entries": {
    "main.projects": {
      "parent": "main",
      "order": 45,
      "label": "Projects",
      "action": { "type": "menu", "menu": "projects" }
    }
  }
}
```

The provider is an executable on `$PATH`. A typical provider uses Python's
standard library directly:

```python
#!/usr/bin/env python3
"""Print project entries for the Quickshell menu."""

import json
from pathlib import Path
import shlex
import sys


def project_entries() -> list[dict]:
    projects_root = Path.home() / "Projects"
    projects = (
        sorted(
            (path for path in projects_root.iterdir() if path.is_dir()),
            key=lambda path: path.name.casefold(),
        )
        if projects_root.is_dir()
        else []
    )
    return [
        {
            "id": f"project.{project.name}",
            "label": project.name,
            "searchText": f"{project.name} repository source code",
            "action": {
                "type": "command",
                "command": f"foot --working-directory={shlex.quote(str(project))}",
            },
        }
        for project in projects
    ]


def main() -> int:
    json.dump(
        project_entries(),
        sys.stdout,
        ensure_ascii=False,
        separators=(",", ":"),
    )
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

Save it as `bin/my-project-menu-entries` and make it executable. Its stdout is
the provider array; array order is row order. No Hyprkarl-specific Python
package is required.

## Sparse User Overrides

Objects merge recursively by key. This means a personal file can change one
field without copying the entry:

```json
{
  "entries": {
    "main.launch": {
      "label": "Applications"
    },
    "main.uninstall": {
      "enabled": false
    },
    "main.update": {
      "disabled": true
    }
  }
}
```

To add a submenu, add its menu object and the entries that point to and live
inside it. To add a command to an existing menu, only add a new entry with a
unique stable ID:

```json
{
  "entries": {
    "utilities.files": {
      "parent": "utilities",
      "order": 25,
      "icon": "",
      "label": "Files",
      "action": { "type": "command", "command": "thunar" }
    }
  }
}
```

The override cannot delete object keys because removal would make future
upstream additions ambiguous. Set an entry's `enabled` field to `false`
instead.

## Appearance

Menu appearance is theme-owned rather than part of either menu JSON file. It
uses the active Quickshell theme and its nested `menu` object. The shipped
composition preserves Hyprkarl's original Rofi menu identity through its
compact width, centered icon-and-label rows, title band, nested frame, row
gaps, and bordered selection. Its palette, typography, rounded geometry,
border treatment, translucent accent states, and subtle backdrop scrim make
it part of the current shell instead of a literal reproduction.

The object owns `scrim`, `fontSize`, `width`, `searchWidth`, `referenceWidth`,
`searchRows`, `outerRadius`, `innerRadius`, `entryRadius`, `outerBorderWidth`,
`outerPadding`, `innerBorderWidth`, `headerPadding`, `entryMargin`,
`entryPadding`, `selectionBorderWidth`, `headerAccentOpacity`, and
`selectionAccentOpacity`. It may also override the inherited `background`,
`foreground`, `accent`, `border`, `font`, and `fontWeight` tokens when a theme
needs a menu-specific treatment. Omitted semantic tokens fall back to the
corresponding top-level shell theme values, so a new theme normally needs only
the menu-specific metrics and modifiers. `innerBorderWidth` sets both the
nested frame thickness and the divider that supports the title band; the
band's lower corners stay square against it. `searchRows` fixes the visible
maximum viewport height while a query filters the current menu and its
descendants. Short result sets use only their natural height.

## Opening Menus Directly

The public command boundary is:

```bash
hk-shell menu toggle main
hk-shell menu open utilities
hk-shell menu close
```

Menu IDs include `main`, `config`, `defaults`, `install`, `uninstall`,
`utilities`, `update`, `power`, `power-profile`, `theme`, `keybindings`,
`icons`, `fingerprint`, `fingerprint-enroll`, and `fingerprint-remove`.
Static forwarding `hk-menu-*` aliases are intentionally absent: custom
bindings call the relevant `hk-shell` boundary directly. Use `hk-shell
launcher`, `hk-shell calculator`, and `hk-shell wallpaper` for the dedicated
overlays.

Keyboard navigation supports Up/Down, Home/End, and Enter to choose. Escape or
an unmodified lowercase Q closes the whole menu. Left on an empty
query goes to the parent, closing at the root, while Right enters the selected
submenu. Clicking outside closes the whole menu. Typing filters the current
menu and all declared descendants.
