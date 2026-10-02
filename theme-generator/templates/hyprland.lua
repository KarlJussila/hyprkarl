-- See https://wiki.hypr.land/Configuring/Basics/Variables/ for color info
hl.config({
    general = {
        col = {
            active_border = "{{hyprrgb(accent.primary.base)}}",
        },
    },
})

-- Hyprland starts with any installed Hyprcursor theme when this cursor has no
-- Hyprcursor version, so set it explicitly once Hyprland is up.
hl.on("hyprland.start", function()
    hl.exec_cmd('hyprctl setcursor "{{desktop.cursor_theme}}" "$XCURSOR_SIZE"')
end)
