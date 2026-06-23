-- Apps that should float, center, or get a fixed size. Disjoint window classes,
-- grouped here so "what floats?" has a single home. The `floating-window` tag's
-- behavior (float + center + 875x600) is defined in windows.lua; apps that need a
-- different size set float/center/size explicitly instead.

-- Hyprkarl dialogs, previewers, and small media viewers
hl.window_rule({ match = { class = [[(org\.hyprkarl\..*|org.gnome.NautilusPreviewer|org.gnome.Evince|com.gabm.satty|hyprkarl|About|imv|mpv)]] }, tag = "+floating-window" })

-- hyprkarl-spawned windows (TUI apps, portal terminals) open from background daemons
-- with no workspace context; force them onto the active workspace.
hl.window_rule({ match = { class = [[org\.hyprkarl\..*]] }, workspace = "current" })

-- File chooser / save dialogs from apps that don't advertise a dialog hint
hl.window_rule({
    match = {
        class = "(xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus)",
        title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)",
    },
    tag = "+floating-window",
})

-- Calculator
hl.window_rule({ match = { class = "org.gnome.Calculator" }, float = true })

-- Steam Friends List (needs a tall, narrow size)
hl.window_rule({ match = { class = "steam", title = "Friends List" }, float = true })
hl.window_rule({ match = { class = "steam", title = "Friends List" }, center = true })
hl.window_rule({ match = { class = "steam", title = "Friends List" }, size = { 460, 800 } })

-- LocalSend
hl.window_rule({ match = { class = "(Share|localsend)" }, float = true })
hl.window_rule({ match = { class = "(Share|localsend)" }, center = true })
