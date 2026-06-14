-- Workspace and monitor management: switching, moving windows between
-- workspaces, the scratchpad, and moving workspaces across monitors.

-- Workspaces. Keys 1-9 then 0 (workspace 10). Bound by keysym (not code:) so
-- they show up in `hyprctl binds` / hk-menu-keybindings; assumes a us layout.
for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }), { description = ("Switch to workspace %d"):format(i) })
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { description = ("Move window to workspace %d"):format(i) })
    hl.bind("SUPER + SHIFT + ALT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }), { description = ("Move window silently to workspace %d"):format(i) })
    hl.bind("SUPER + CTRL + SHIFT + " .. key, hl.dsp.exec_cmd("hk-workspace-swap " .. i), { description = ("Swap with workspace %d"):format(i) })
end

-- Scratchpad (a special workspace)
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("scratchpad"), { description = "Toggle scratchpad" })
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratchpad" }), { description = "Move window to scratchpad" })
hl.bind("SUPER + SHIFT + ALT + S", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }), { description = "Move window silently to scratchpad" })

-- TAB between workspaces
hl.bind("SUPER + TAB", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind("SUPER + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })

-- Scroll through existing workspaces with SUPER + scroll
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Scroll active workspace forward" })
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Scroll active workspace backward" })

-- Move workspaces to other monitors
hl.bind("SUPER + SHIFT + ALT + LEFT", hl.dsp.workspace.move({ monitor = "l" }), { description = "Move workspace to left monitor" })
hl.bind("SUPER + SHIFT + ALT + RIGHT", hl.dsp.workspace.move({ monitor = "r" }), { description = "Move workspace to right monitor" })
hl.bind("SUPER + SHIFT + ALT + UP", hl.dsp.workspace.move({ monitor = "u" }), { description = "Move workspace to up monitor" })
hl.bind("SUPER + SHIFT + ALT + DOWN", hl.dsp.workspace.move({ monitor = "d" }), { description = "Move workspace to down monitor" })
