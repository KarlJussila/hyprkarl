-- Hyprland configuration (Lua, hyprland 0.55+).
-- See https://wiki.hypr.land/Configuring/Start/
--
-- Each module is loaded with require() so Hyprland's per-file error isolation
-- applies: a mistake in one file won't abort the others. Order matches the old
-- hyprland.conf source order; the active theme is loaded last so it overrides.

require("envs")
require("autostart")
require("monitors")
require("permissions")
require("looknfeel")
require("animations")
require("gum")
require("windows")
require("input")
require("bindings")

-- The active theme lives outside this directory (symlinked via hk-theme), so it
-- can't be reached with require()'s relative resolution. Load it by absolute path.
local theme = os.getenv("HOME") .. "/.config/hyprkarl/current/theme/hyprland.lua"
local chunk = loadfile(theme)
if chunk then chunk() end
