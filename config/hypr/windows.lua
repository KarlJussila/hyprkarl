-- Window and layer rules. See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--
-- All rules are anonymous (no name=) so they evaluate strictly in source order.
-- This file is the orchestrator: it defines the global/base rules and reusable
-- tag behaviors, then requires the per-category modules in windows/, which assign
-- those tags to apps.
--
-- The default-opacity contract: every window is tagged +default-opacity here, and
-- the LAST window rule in this file applies `opacity 1.0 0.8` to anything still
-- carrying that tag. A module can opt a window out by adding `tag = "-default-
-- opacity"` (see windows/media.lua, windows/browsers.lua). Keep the final
-- application last, and keep every opt-out before it.

-- Base rules -----------------------------------------------------------------

-- Don't let apps maximize themselves
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- Tag all windows for default opacity (modules opt out with -default-opacity)
hl.window_rule({ match = { class = ".*" }, tag = "+default-opacity" })

-- Fix some dragging issues with XWayland
hl.window_rule({
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Reusable tag behaviors -----------------------------------------------------
-- What each tag does; modules below decide which windows get tagged.

-- floating-window: float, centered, at a comfortable default size
hl.window_rule({ match = { tag = "floating-window" }, float = true })
hl.window_rule({ match = { tag = "floating-window" }, center = true })
hl.window_rule({ match = { tag = "floating-window" }, size = { 875, 600 } })

-- dialog: float and center (hyprkarl-dialog windows advertise themselves here)
hl.window_rule({ match = { class = "hyprkarl-dialog" }, tag = "+dialog" })
hl.window_rule({ match = { tag = "dialog" }, float = true })
hl.window_rule({ match = { tag = "dialog" }, center = true })

-- pop: rounded corners
hl.window_rule({ match = { tag = "pop" }, rounding = 8 })

-- noidle: inhibit idle while open
hl.window_rule({ match = { tag = "noidle" }, idle_inhibit = "always" })

-- Per-category rules ---------------------------------------------------------
-- Order is flexible (disjoint window classes); the only constraint is that any
-- -default-opacity opt-out must precede the final application below.
require("windows/browsers")
require("windows/floating")
require("windows/media")
require("windows/terminals")
require("windows/screenshots")

-- Final default-opacity application (must stay the last opacity rule) ---------
hl.window_rule({ match = { tag = "default-opacity" }, opacity = "1.0 0.8" })

-- Layer rules ----------------------------------------------------------------

-- Dim around rofi
hl.layer_rule({ match = { namespace = "rofi" }, dim_around = true })

-- Blur AGS bar
hl.layer_rule({ match = { namespace = "ags" }, blur = true })
