-- Browser-specific window rules.

-- Browser families (tagged so the rules below can target them generically)
hl.window_rule({ match = { class = "((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)" }, tag = "+chromium-based-browser" })
hl.window_rule({ match = { class = "([fF]irefox|zen|librewolf)" }, tag = "+firefox-based-browser" })

-- Force chromium-based browsers into a tile to deal with --app bug
hl.window_rule({ match = { tag = "chromium-based-browser" }, tile = true })

-- Video sites should never be dimmed. Match the LIVE title (it updates as you
-- browse — initial_title is just "<browser>") and opt out of the default-opacity
-- tag so the final opacity rule can't dim them when unfocused. YouTube's own page
-- title is "<video> - YouTube"; the zoom web client shows app.zoom.us/wc.
local videoTitle = [[(.* - YouTube.*|.*youtube\.com.*|.*app\.zoom\.us/wc.*)]]
hl.window_rule({ match = { title = videoTitle }, tag = "-default-opacity" })
hl.window_rule({ match = { title = videoTitle }, opacity = "1.0 1.0" })

-- Fix for Edge tooltips trying to tile
hl.window_rule({
    match = { class = "^()$", title = "^()$", initial_class = "^()$", initial_title = "^()$" },
    float = true,
    no_focus = true,
    pin = true,
    keep_aspect_ratio = true,
    border_size = 0,
    center = false,
    move = { "min(cursor_x,monitor_w-window_w)", "min(cursor_y+20,monitor_h-window_h)" },
})
