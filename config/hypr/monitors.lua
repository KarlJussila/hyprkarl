-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and resolutions possible: hyprctl monitors
-- You must relaunch Hyprland after changing any envs (use Super+Esc, then Relaunch)

-- Optimized for retina-class 2x displays, like 13" 2.8K, 27" 5K, 32" 6K.
hl.env("GDK_SCALE", "2")
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Good compromise for 27" or 32" 4K monitors (but fractional!)
-- hl.env("GDK_SCALE", "1.75")
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.666667 })

-- Straight 1x setup for low-resolution displays like 1080p or 1440p
-- hl.env("GDK_SCALE", "1")
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Example for Framework 13 w/ 6K XDR Apple display
-- hl.monitor({ output = "DP-5",  mode = "6016x3384@60",  position = "auto", scale = 2 })
-- hl.monitor({ output = "eDP-1", mode = "2880x1920@120", position = "auto", scale = 2 })

-- Render XWayland apps at scale 1 and let the compositor upscale, so they stay
-- crisp on the HiDPI scaling above instead of rendering blurry.
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})
