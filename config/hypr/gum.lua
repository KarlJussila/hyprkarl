-- Style gum to match terminal theme (ANSI color codes 0-8)
local vars = {
    GUM_CONFIRM_PROMPT_FOREGROUND           = "6",  -- Cyan
    GUM_CONFIRM_SELECTED_FOREGROUND         = "0",  -- Black
    GUM_CONFIRM_SELECTED_BACKGROUND         = "2",  -- Green
    GUM_CONFIRM_UNSELECTED_FOREGROUND       = "6",  -- Cyan
    GUM_CONFIRM_UNSELECTED_BACKGROUND       = "8",  -- Dark gray
    GUM_SPIN_SPINNER_FOREGROUND             = "2",  -- Green
    GUM_CHOOSE_CURSOR_FOREGROUND            = "6",  -- Cyan
    GUM_CHOOSE_HEADER_FOREGROUND            = "2",  -- Green
    GUM_CHOOSE_SELECTED_FOREGROUND          = "6",  -- Cyan
    GUM_FILTER_INDICATOR_FOREGROUND         = "6",  -- Cyan
    GUM_FILTER_SELECTED_PREFIX_FOREGROUND   = "6",  -- Cyan
    GUM_FILTER_UNSELECTED_PREFIX_FOREGROUND = "7",  -- White
    GUM_FILTER_HEADER_FOREGROUND            = "2",  -- Green
    GUM_FILTER_MATCH_FOREGROUND             = "6",  -- Cyan
    GUM_FILTER_PROMPT_FOREGROUND            = "6",  -- Cyan
    GUM_FILTER_PLACEHOLDER_FOREGROUND       = "8",  -- Dark gray
    GUM_FILE_CURSOR_FOREGROUND              = "6",  -- Cyan
    GUM_FILE_SYMLINK_FOREGROUND             = "4",  -- Blue
    GUM_FILE_DIRECTORY_FOREGROUND           = "2",  -- Green
    GUM_FILE_PERMISSIONS_FOREGROUND         = "8",  -- Dark gray
    GUM_FILE_SELECTED_FOREGROUND            = "6",  -- Cyan
    GUM_FILE_FILE_SIZE_FOREGROUND           = "3",  -- Yellow
    GUM_FILE_HEADER_FOREGROUND              = "2",  -- Green
}
for k, v in pairs(vars) do hl.env(k, v) end
