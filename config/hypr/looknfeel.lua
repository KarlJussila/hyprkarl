-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/

-- Border colors (the active theme overrides general.col.active_border last)
local activeBorderColor = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 }
local inactiveBorderColor = "rgba(595959aa)"

hl.config({
    -- https://wiki.hypr.land/Configuring/Basics/Variables/#general
    general = {
        gaps_in = 5,
        gaps_out = 0,

        border_size = 3,

        col = {
            active_border = activeBorderColor,
            inactive_border = inactiveBorderColor,
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    -- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
    decoration = {
        rounding = 0,

        shadow = {
            enabled = true,
            range = 2,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },

        -- https://wiki.hypr.land/Configuring/Basics/Variables/#blur
        blur = {
            enabled = true,
            size = 2,
            passes = 2,
            special = true,
            brightness = 0.60,
            contrast = 0.75,
        },
    },

    -- https://wiki.hypr.land/Configuring/Basics/Variables/#group
    group = {
        col = {
            border_active = activeBorderColor,
            border_inactive = inactiveBorderColor,
            border_locked_active = activeBorderColor,
            border_locked_inactive = inactiveBorderColor,
        },

        groupbar = {
            font_size = 12,
            font_family = "monospace",
            font_weight_active = "ultraheavy",
            font_weight_inactive = "normal",

            indicator_height = 0,
            indicator_gap = 5,
            height = 22,
            gaps_in = 5,
            gaps_out = 0,

            text_color = "rgb(ffffff)",
            text_color_inactive = "rgba(ffffff90)",
            col = {
                active = "rgba(00000040)",
                inactive = "rgba(00000020)",
            },

            gradients = true,
            gradient_rounding = 0,
            gradient_round_only_edges = false,
        },
    },

    -- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
    animations = {
        enabled = true,
    },

    -- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
    dwindle = {
        preserve_split = true, -- You probably want this
        force_split = 2,       -- Always split on the right
    },

    -- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
    master = {
        new_status = "master",
    },

    -- https://wiki.hypr.land/Configuring/Basics/Variables/#misc
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        focus_on_activate = true,
        anr_missed_pings = 3,
        on_focus_under_fullscreen = 1,
    },

    -- https://wiki.hypr.land/Configuring/Basics/Variables/#cursor
    cursor = {
        hide_on_key_press = false,
    },
})

