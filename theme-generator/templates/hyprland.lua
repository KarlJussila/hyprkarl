-- See https://wiki.hypr.land/Configuring/Basics/Variables/ for color info
hl.config({
    general = {
        col = {
            active_border = "{{hyprrgb(accent.primary.base)}}",
        },
    },
})

-- Cursor theme. Hyprland draws its cursor from HYPRCURSOR_THEME and falls back
-- to XCURSOR_THEME for themes without a Hyprcursor version; X11 apps and
-- clients that draw their own cursor read XCURSOR_THEME. `true` also exports
-- the value to apps started through systemd and D-Bus.
hl.env("HYPRCURSOR_THEME", "{{desktop.cursor_theme}}", true)
hl.env("XCURSOR_THEME", "{{desktop.cursor_theme}}", true)
