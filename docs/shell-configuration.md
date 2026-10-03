# Shell Configuration

The shell's behavior comes from `defaults/shell.json` with your
`~/.config/quickshell/settings/shell.json` merged over it. Its appearance comes
from the theme; see [Themes](themes.md#shell-appearance). For your own widgets,
interfaces, and replacements, see [Extending
Hyprkarl](extending-hyprkarl.md#extend-quickshell).

## Your settings file

Put only what you change in your file. Objects merge key by key over the
shipped file; arrays and every other value replace it. Anything you leave out
keeps following the shipped default, so updates still reach it. This complete
file moves the bar to the bottom:

```json
{
  "bar": {
    "edge": "bottom"
  }
}
```

Changes apply live, except `modules` and personal QML sources, which need
`hk-shell restart`. A file that does not parse leaves the shipped settings
running and logs the error to `hk-shell logs`. Values are not validated; a
wrong one shows up there as an error from the code that reads it.

## Modules

`modules` switches the built-in parts of the shell on or off. All are on by
default, so name only the ones to turn off:

```json
{
  "modules": {
    "notifications": false
  }
}
```

| Key | What it runs |
|---|---|
| `bar` | The bar on every monitor, and its system monitor and command widgets |
| `panels` | The popup panels that bar widgets open; the widgets themselves stay |
| `notifications` | The notification server and its popups |
| `osd` | Volume, brightness, and media popups |
| `polkit` | The authentication prompt |
| `menu` | The command menus |
| `applications` | The launcher and open-with chooser |
| `calculator` | The calculator |
| `wallpaper` | The wallpaper picker |

A switched-off module runs nothing. Keybindings and menu entries that open it
are left alone: hide them, or [replace the
module](extending-hyprkarl.md#replace-a-built-in) with your own.

## Bar

`bar.edge` is `top` or `bottom`. `bar.exclusive` reserves the bar's space so
windows do not cover it.

`bar.layout` places widgets in three islands: `start`, `center`, and `end`.
`center` has a widget fixed at the screen's midpoint, `anchor` (set it to
`null` for none), with `before` and `after` growing away from it. `start`,
`end`, `before`, and `after` are arrays, so changing one means copying that
section from `defaults/shell.json` into your file; the other sections keep
following updates. Every widget needs a unique `id`.

This drops the GPU readout by owning `start`:

```json
{
  "bar": {
    "layout": {
      "start": [
        { "id": "menu", "kind": "command", "icon": "", "tooltip": "Main menu",
          "primaryCommand": "hk-shell menu toggle main" },
        { "id": "workspaces", "kind": "workspaces", "alwaysShow": [1],
          "includeFocused": true, "includeOccupied": true },
        { "id": "cpu", "kind": "cpu", "format": "{temp}°",
          "alternateFormat": "{temp}° | {usage}%" },
        { "id": "ram", "kind": "ram", "icon": "", "format": "{usedPercent}%",
          "alternateFormat": "{used}/{total} | {swapUsed}/{swapTotal}" },
        { "id": "tray", "kind": "tray", "direction": "end" }
      ]
    }
  }
}
```

### Built-in widgets

Clickable widgets follow one rule: `primaryCommand`, `secondaryCommand`, and
`tertiaryCommand` run on left, right, and middle click. Readouts show `format`
and switch to `alternateFormat` on right click. Commands run through
`bash -c` with `HYPRKARL_OUTPUT` set to the clicked bar's monitor.

| `kind` | Settings |
|---|---|
| `command` | See [Command widgets](#command-widgets) |
| `qml` | `source`, `settings`; see [QML widgets](extending-hyprkarl.md#qml-widgets) |
| `workspaces` | `alwaysShow` (workspace IDs), `includeFocused`, `includeOccupied` |
| `cpu` | `format`, `alternateFormat`; placeholders `{usage}`, `{temp}` |
| `gpu` | `format`, `alternateFormat`; placeholders `{usage}`, `{vramUsed}`, `{vramTotal}` |
| `ram` | `icon`, `format`, `alternateFormat`; placeholders `{usedPercent}`, `{used}`, `{total}`, `{swapUsed}`, `{swapTotal}` |
| `clock` | `format`, `alternateFormat` as [Qt date formats](https://doc.qt.io/qt-6/qml-qtqml-qt.html#formatDateTime-method) |
| `tray` | `direction` (`start` or `end`) |
| `recording` | `icon`, `primaryCommand` |
| `toggle` | `onCommand`, `offCommand`, `syncCommand`, `onIcon`, `offIcon`, `tooltip`, `switch` |
| `display` | None |
| `audio` | `showPercentage`, `secondaryCommand` |
| `bluetooth`, `network` | `secondaryCommand` |
| `battery` | `showPercentage`, `lowThreshold` (0 to 1), `secondaryCommand` |

On audio, Bluetooth, network, and battery, left click opens the widget's panel
and `secondaryCommand` launches the full settings application, which the panel
also offers.

A `toggle` runs `syncCommand` every five seconds to learn its state (exit 0
means on) and
`onCommand` or `offCommand` when clicked. Its look comes from the theme's
`shell.switch`; a sparse `switch` object on the widget changes it for that one
toggle, for example `{ "variant": "mark" }` for a stationary checkbox instead
of a sliding switch.

### Command widgets

A `command` widget shows the output of a command, or is a plain button.

Without a `command`, it is a button: give it `icon` or `text` and a click
command. The shipped menu button is one.

With a `command`, the widget polls it every `interval` milliseconds and shows
its trimmed output:

```json
{
  "id": "load-average",
  "kind": "command",
  "command": "cut -d' ' -f1 /proc/loadavg",
  "interval": 5000,
  "icon": "󰓅",
  "tooltip": "One-minute load average"
}
```

Each poll starts a process, so pick the slowest interval that is still useful.
For frequent or event-driven values, set `"mode": "stream"` and omit
`interval`: the shell starts the command once and shows each line it prints.
The command must flush every line and is not restarted if it exits.

Set `"output": "json"` to let the command change more than the text. Each
result is one JSON object with any of `text`, `icon`, `tooltip`, `visible`
(boolean), and `state` (`normal`, `muted`, `accent`, `warning`, or `urgent`,
which pick theme colors). Omitted fields keep the widget's own values.

A command runs once per widget, however many monitors show the bar, and never
twice at once. A failure or invalid JSON is logged and the last good result
stays; the widget stays hidden until its first good result.

## Notifications

| Key | Meaning |
|---|---|
| `edge` | `bar` to sit against the bar, or `top`/`bottom` for that screen edge |
| `side` | `left` or `right` |
| `gap` | Space between the stack and the bar or screen edge |
| `sideMargin` | Space between the stack and the screen side |
| `defaultTimeout` | Milliseconds a notification stays when its sender sets no timeout |
| `statusTimeout` | Milliseconds for the shell's own status messages |
| `maxVisible` | Most notifications shown at once per monitor |
| `ignoredApplications` | Application names whose notifications are dropped |
| `compactApplications` | Application names shown in the narrower compact popup |
| `iconOverrides` | Icons by application or icon name; see below |
| `fallbackIcon`, `criticalIcon` | Icon when a notification brings none |

Critical notifications, and those whose sender sets a timeout of zero, stay
until dismissed. Hovering pauses a notification's timer. Application names are
lowercase. The two lists are arrays, so your file replaces them whole;
`iconOverrides` is an object and merges.

An icon is one of:

```json
{
  "notifications": {
    "iconOverrides": {
      "discord": { "kind": "icon", "value": "discord" },
      "backup job": { "kind": "glyph", "value": "󰁯" },
      "my monitor": { "kind": "component", "source": "user/RingIcon.qml" },
      "noisy utility": { "kind": "none" }
    }
  }
}
```

`icon` takes an icon-theme name or a file path, and `glyph` a character in the
theme font. `component` draws the icon with QML: `builtin/<file>.qml` comes from
the shell's own notification icons, `user/<file>.qml` from
`~/.config/quickshell/custom/icons/`, or an absolute path; see [Notification
icons](extending-hyprkarl.md#notification-icons). `none` removes the icon. An
image the notification itself carries always wins.

## OSD

`osd.edge` is `top` or `bottom`, and `osd.margin` its distance from that edge.
`osd.timeout` is how long volume, brightness, and microphone popups stay, and
`osd.mediaTimeout` the same for track changes, both in milliseconds.

## Launcher

`applications.hidden` lists desktop entry IDs (file names without `.desktop`)
that the launcher leaves out. It is an array, so your list replaces the
shipped one: copy it from `defaults/shell.json` and edit it.

## Personal QML root

`userRoot.source` names a QML file under `~/.config/quickshell/custom/` that
the shell loads once, and `userRoot.settings` is data passed to it. See
[Extending Hyprkarl](extending-hyprkarl.md#application-wide-qml).
