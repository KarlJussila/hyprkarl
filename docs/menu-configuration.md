# Menu Configuration

The command menus are data: `defaults/menu.json`, with your
`~/.config/quickshell/settings/menu.json` merged over it key by key. Write only
the menus and entries you add or change. Edits apply live; a file that does not
parse leaves the shipped menus running and logs the error to `hk-shell logs`.

## Shape

```json
{
  "menus": {
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
      "label": "Example",
      "action": { "type": "command", "command": "example-command" }
    }
  }
}
```

A menu has a `title`, and optionally:

- `sourceCommand` and `emptyLabel` for [dynamic entries](#dynamic-menus);
- `widthRole`: `default`, `search` (wider, with the search field always
  shown), or `reference` (widest);
- `entryAlignment`: `left`, `center` (the default), or `right`.

An entry has a stable dotted ID and:

- `parent`: the menu it appears in;
- `order`: its position (ties sort by ID);
- `label`, and optionally `icon` and `searchText` (extra words search matches);
- `hidden: true` to leave it out, or `disabled: true` to show it dimmed and
  unselectable;
- `checkedCommand`: a quick command run when the menu opens; exit 0 shows a
  check mark;
- `action`, one of:
  - `{ "type": "menu", "menu": "<id>" }` opens a submenu;
  - `{ "type": "command", "command": "..." }` closes the menu and runs the
    command with `bash -c` through `uwsm-app`;
  - `{ "type": "surface", "surface": "<name>", "parameters": {} }` switches to
    another interface: `launcher`, `calculator`, `wallpaper` (with
    `"action": "set"` or `"remove"`), or one of your own (see [Application-wide
    QML](extending-hyprkarl.md#application-wide-qml)). The menu stays as its
    way back;
  - `{ "type": "dismiss" }` just closes the menu, for informational rows.

Keep long commands in a script in `~/.local/bin/` and call it by name.

## Changing shipped entries

Change one field without copying the entry:

```json
{
  "entries": {
    "main.launch": { "label": "Applications" },
    "main.uninstall": { "hidden": true }
  }
}
```

Your file cannot delete shipped keys; hide an entry instead. To add to an
existing menu, add an entry with a new ID and that menu as its `parent`.

## Dynamic menus

A menu with `sourceCommand` runs that command each time it opens. The command
prints one JSON array of rows and exits; each row has an `id`, a `label`,
optionally `icon`, `searchText`, and `disabled`, and an `action` as above.
Array order is row order, and `emptyLabel` shows when the array is empty. Bad
output is shown in the menu and logged. Keep the command fast: if its data
only changes occasionally, generate the JSON then and have `sourceCommand`
print the file.

Python's `json` module is the easiest way to produce the rows:

```python
#!/usr/bin/env python3
import json
import shlex
from pathlib import Path

projects = sorted(p for p in (Path.home() / "Projects").iterdir() if p.is_dir())
print(json.dumps([
    {
        "id": f"project.{p.name}",
        "label": p.name,
        "action": {
            "type": "command",
            "command": f"xdg-terminal-exec --dir={shlex.quote(str(p))}",
        },
    }
    for p in projects
]))
```

Save it as `~/.local/bin/my-project-menu-entries`, make it executable, and
declare the menu:

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

## Opening menus

```bash
hk-shell menu toggle main
hk-shell menu open utilities
hk-shell menu close
```

The shipped menu IDs are in `defaults/menu.json`. Typing searches the current
menu and every submenu below it. Up/Down and Home/End move, Enter chooses,
Right enters a submenu, Left on an empty search goes back, and Escape, Q, or a
click outside closes.

## Appearance

Menus follow the theme's `shell.menu` values; see [Shell
appearance](themes.md#shell-appearance).
