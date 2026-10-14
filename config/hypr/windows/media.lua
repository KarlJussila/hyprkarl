-- Media windows: never apply transparency to them. They opt out of the
-- default-opacity tag (so the final opacity rule can't dim them when unfocused)
-- and pin their opacity at fully opaque.
local mediaApps = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$"
hl.window_rule({ match = { class = mediaApps }, tag = "-default-opacity" })
hl.window_rule({ match = { class = mediaApps }, opacity = "1 1" })

-- Picture-in-picture overlays: a small, pinned, opaque, top-right tile.
hl.window_rule({ match = { title = "(Picture.?in.?[Pp]icture)" }, tag = "+pip" })

local function pip(rule)
    rule.match = { tag = "pip" }
    hl.window_rule(rule)
end

pip({ tag = "-default-opacity" })
pip({ float = true })
pip({ pin = true })
pip({ size = { 600, 338 } })
pip({ keep_aspect_ratio = true })
pip({ border_size = 0 })
pip({ opacity = "1 1" })
pip({ move = { "monitor_w-window_w-40", "monitor_h*0.04" } })
