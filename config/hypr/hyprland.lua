-- Hyprkarl's Hyprland bootstrap: shipped modules, the active theme, the
-- display layout, then your ~/.config/hypr/hyprland.local.lua.
-- See https://wiki.hypr.land/Configuring/Start/

local hyprkarl_path = assert(
    os.getenv("HYPRKARL_PATH"),
    "HYPRKARL_PATH must point at the Hyprkarl checkout"
)
local defaults_path = hyprkarl_path .. "/defaults/hypr"
local home = assert(os.getenv("HOME"))
local config_home = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local user_path = config_home .. "/hypr"
local state_home = os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")

package.path = table.concat({
    defaults_path .. "/?.lua",
    defaults_path .. "/?/init.lua",
    user_path .. "/?.lua",
    user_path .. "/?/init.lua",
    package.path,
}, ";")

-- Shipped modules retain their established order. Each is a separate Lua
-- module so Hyprland can report its source precisely when configuration fails.
local modules = {
    "envs",
    "autostart",
    "monitors",
    "permissions",
    "looknfeel",
    "animations",
    "gum",
    "windows",
    "input",
    "bindings",
}

for _, module in ipairs(modules) do
    require(module)
end

-- The theme loads after the shipped modules; your file loads last, so your
-- values win over both.
local theme_path = state_home .. "/hyprkarl/current/theme/hyprland.lua"
local theme, theme_error = loadfile(theme_path)
if not theme then
    error(theme_error)
end
theme()

local function load_optional_file(path)
    local file, open_error, error_code = io.open(path, "r")

    if not file then
        if error_code == 2 then
            return
        end
        error(open_error)
    end

    file:close()

    local chunk, load_error = loadfile(path)
    if not chunk then
        error(load_error)
    end
    chunk()
end

-- Display-panel changes are generated machine state. They override the
-- shipped catch-all rule, while your monitor rules still have the final say.
load_optional_file(state_home .. "/hyprkarl/display/monitors.lua")
load_optional_file(user_path .. "/hyprland.local.lua")
