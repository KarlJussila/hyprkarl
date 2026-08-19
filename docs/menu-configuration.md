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

`root` names the menu opened by `hk-menu` and the bar button. Each object in
`menus` supplies a title. Each object in `entries` has a stable dotted ID and:

- `parent`: the menu containing the entry
- `order`: numeric display order; IDs break ties deterministically
- `label`: displayed text
- `icon`: optional displayed glyph
- `enabled`: optional boolean; `false` removes the entry from rendering
- `checkedCommand`: optional command evaluated when the menu opens; exit zero
  replaces the icon with a check mark
- `action`: either a `menu` destination or a shell `command`

Commands run through `bash -lc` after the menu closes. Keep interaction-heavy
work in a dedicated `hk-*` command and reference it from the data; the menu
definition owns navigation, not application logic. The shipped definition
still uses focused Rofi or terminal interfaces for dynamic and search-heavy
selectors such as apps, themes, Docker services, wallpaper thumbnails,
enrolled fingers, and packages. Static wallpaper management, fingerprint
management, power profiles, and default-app choices remain in Quickshell.

Use `checkedCommand` only for a cheap external state probe whose status belongs
in the menu. Checks run when the menu opens; they are not long-running monitors
and do not replace shell-native service state in feature panels.

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

The object owns `scrim`, `fontSize`, `width`, `outerRadius`, `innerRadius`,
`entryRadius`, `outerBorderWidth`, `outerPadding`, `innerBorderWidth`,
`headerPadding`, `entryMargin`, `entryPadding`, `selectionBorderWidth`,
`headerAccentOpacity`, and `selectionAccentOpacity`. It may also override the
inherited `background`, `foreground`, `accent`, `border`, `font`, and
`fontWeight` tokens when a theme needs a menu-specific treatment. Omitted
semantic tokens fall back to the corresponding top-level shell theme values,
so a new theme normally needs only the menu-specific metrics and modifiers.
`innerBorderWidth` sets both the nested frame thickness and the divider that
supports the title band; the band's lower corners stay square against it.

## Opening Menus Directly

The public command boundary is:

```bash
hk-shell menu toggle main
hk-shell menu open utilities
hk-shell menu close
```

The established `hk-menu`, `hk-menu-config`, `hk-menu-defaults`,
`hk-menu-install`, `hk-menu-uninstall`, `hk-menu-utils`, `hk-menu-update`, and
`hk-menu-power` commands remain as compatibility-friendly entry points. The
wallpaper, fingerprint, power-profile, terminal, editor, and shell menu
commands also open their corresponding Quickshell surfaces rather than owning
separate Rofi navigation scripts.

Keyboard navigation supports Up/Down (or J/K), Home/End, Enter/Space/Right (or
L) to choose, and Escape/Left/Backspace to go back. Going back from the root
closes the menu. Clicking outside goes back from a submenu and closes the root.
