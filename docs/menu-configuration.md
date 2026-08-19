# Menu Configuration

Hyprkarl's static command hierarchy is rendered by Quickshell and defined as
data. The shipped definition lives at `defaults/menu.json`; personal changes
belong in the optional `user/menu.json` override.

Both files use JSON version 1. The shell watches them, recursively merges the
user object over the shipped object, and validates the effective result. A
valid edit applies live. An invalid edit is reported in `hk-shell logs` while
the last valid menu remains active; deleting `user/menu.json` returns to the
shipped definition.

## Document Shape

```json
{
  "version": 1,
  "root": "main",
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

`root` names the menu opened by `hk-shell menu toggle main` and the bar button.
Each object in `menus` supplies a title and may also define `sourceCommand`
plus `emptyLabel` for entries discovered when that menu opens. Set
`searchable` to `true` for an in-process fuzzy-search field. `widthRole` may be
`default`, `search`, or `reference` and selects the corresponding themed menu
width. `entryAlignment` may be `left`, `center`, or `right`; it defaults to
`center`. Each object in `entries` has a stable dotted ID and:

- `parent`: the menu containing the entry
- `order`: numeric display order; IDs break ties deterministically
- `label`: displayed text
- `icon`: optional displayed glyph
- `enabled`: optional boolean; `false` removes the entry from rendering
- `checkedCommand`: optional command evaluated when the menu opens; exit zero
  replaces the icon with a check mark
- `action`: a `menu` destination, shell `command`, or `dismiss` action for an
  informational row

Commands run through `bash -c` after the menu closes. Keep interaction-heavy
work in a dedicated `hk-*` command and reference it from the data; the menu
definition owns navigation, not application logic. Themes, live keybindings,
Nerd Font icons, Docker services, and every fingerprint choice are dynamic
Quickshell menus. The app launcher, calculator, wallpaper thumbnail picker,
and package pickers retain their focused Rofi or terminal interfaces.

Use `checkedCommand` only for a cheap external state probe whose status belongs
in the menu. Checks run when the menu opens; they are not long-running monitors
and do not replace shell-native service state in feature panels.

A `sourceCommand` must print one JSON array and exit. Each array item has a
stable `id`, a `label`, optional `icon` and `searchText` fields, and a
`command`, `menu`, or `dismiss` action; array order is display order. The shell
validates the result before rendering it, shows `emptyLabel` for an empty
array, and reports provider or schema failure in the menu and `hk-shell logs`.
Sources refresh on every open and when returning to a dynamic parent, so
filesystem, hardware, and service state do not go stale. Domain commands own
discovery: for example, `hk-fingerprint menu-entries remove` supplies only
enrolled fingers and `hk-docker menu-entries install` supplies only missing
services.

The shell runs both providers and command actions with `bash -c`, inheriting
the session environment without starting a login shell. A dynamic destination
is revealed only after its complete result has been parsed and validated, so
users never interact with a partially populated model. Keep providers fast by
doing only the discovery their rows require. If a large catalog changes only
when an update command runs, generate provider-ready JSON during that update
and make `sourceCommand` print the finished file; the shipped icon picker uses
this pattern. Runtime caching is not part of the menu contract.

For example, a personal searchable menu needs only a menu declaration, an
entry that navigates to it, and a provider on `$PATH`:

```json
{
  "version": 1,
  "menus": {
    "projects": {
      "title": "Projects",
      "sourceCommand": "my-project-menu-entries",
      "searchable": true,
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

`my-project-menu-entries` can discover rows at runtime or simply print a
prebuilt file. Its entire output uses the same provider shape:

```json
[
  {
    "id": "project.notes",
    "label": "Notes",
    "searchText": "writing markdown",
    "action": { "type": "command", "command": "foot -D ~/Notes" }
  }
]
```

## Sparse User Overrides

Objects merge recursively by key. This means a personal file can change one
field without copying the entry:

```json
{
  "version": 1,
  "entries": {
    "main.launch": {
      "label": "Applications"
    },
    "main.uninstall": {
      "enabled": false
    }
  }
}
```

To add a submenu, add its menu object and the entries that point to and live
inside it. To add a command to an existing menu, only add a new entry with a
unique stable ID:

```json
{
  "version": 1,
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
viewport height of searchable menus while their contents filter.

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
bindings call the public `hk-shell menu` boundary directly. Commands that own
a distinct interface remain, including `hk-menu-launcher`,
`hk-menu-calculator`, and `hk-menu-wallpaper`.

Keyboard navigation supports Up/Down (or J/K), Home/End, Enter/Space/Right (or
L) to choose, and Escape/Left/Backspace to go back. In a searchable menu,
typing edits the query, Up/Down changes the selection, and Escape clears a
non-empty query before navigating back. Going back from the root closes the
menu. Clicking outside goes back from a submenu and closes the root.
