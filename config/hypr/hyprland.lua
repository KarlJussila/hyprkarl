-- Stable Hyprland bootstrap for Hyprkarl's shipped defaults and user overrides.
-- See https://wiki.hypr.land/Configuring/Start/

local hyprkarl_path = assert(
    os.getenv("HYPRKARL_PATH"),
    "HYPRKARL_PATH must point at the Hyprkarl checkout"
)
local defaults_path = hyprkarl_path .. "/defaults/hypr"
local user_path = hyprkarl_path .. "/user/hypr"

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

-- The theme is a shipped/default visual layer. User modules load afterward so
-- explicit personal values win over both behavioral and theme defaults.
local theme_path = hyprkarl_path .. "/config/hyprkarl/current/theme/hyprland.lua"
local theme, theme_error = loadfile(theme_path)
if not theme then
    error(theme_error)
end
theme()

local function load_user_module(module)
    local path = user_path .. "/" .. module .. ".lua"
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

for _, module in ipairs(modules) do
    load_user_module(module)
end
