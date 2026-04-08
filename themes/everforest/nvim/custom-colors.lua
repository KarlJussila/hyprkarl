-- Name: hyprkarl

local function hl(name, opts)
	vim.api.nvim_set_hl(0, name, opts)
end

vim.cmd("highlight clear")
vim.g.colors_name = "hyprkarl"
vim.opt.background = "dark"

----------------------------------------------------------------
-- Palette
----------------------------------------------------------------

local c = {
	bg = "#2d353b",
	surface = "#3D484D",
	surface_alt = "#4F585E",

	fg = "#d3c6aa",
	fg_muted = "#9DA9A0",
	fg_dim = "#7A8478",

	black = "#343f44",

	red = "#e67e80",
	red_bright = "#e67e80",

	green = "#a7c080",
	green_bright = "#a7c080",

	yellow = "#dbbc7f",
	yellow_bright = "#dbbc7f",

	blue = "#7fbbb3",
	blue_bright = "#7fbbb3",

	magenta = "#d699b6",
	magenta_bright = "#d699b6",

	cyan = "#83c092",
	cyan_bright = "#83c092",

	white = "#859289",
	white_bright = "#9da9a0",

	cursor = "#d3c6aa",

	border = "#a7c080",
	border_soft = "#678140",

	highlight = "#a7c080",

	accent_primary = "#a7c080",
	accent_secondary = "#7fbbb3",
	accent_tertiary = "#dbbc7f",
}

----------------------------------------------------------------
-- Terminal colors
----------------------------------------------------------------

vim.g.terminal_color_0 = c.black
vim.g.terminal_color_1 = c.red
vim.g.terminal_color_2 = c.green
vim.g.terminal_color_3 = c.yellow
vim.g.terminal_color_4 = c.blue
vim.g.terminal_color_5 = c.magenta
vim.g.terminal_color_6 = c.cyan
vim.g.terminal_color_7 = c.fg

vim.g.terminal_color_8 = c.surface
vim.g.terminal_color_9 = c.red_bright
vim.g.terminal_color_10 = c.green_bright
vim.g.terminal_color_11 = c.yellow_bright
vim.g.terminal_color_12 = c.blue_bright
vim.g.terminal_color_13 = c.magenta_bright
vim.g.terminal_color_14 = c.cyan_bright
vim.g.terminal_color_15 = c.white_bright

----------------------------------------------------------------
-- Core UI
----------------------------------------------------------------

hl("Normal", { fg = c.fg, bg = c.bg })
hl("NormalNC", { fg = c.fg, bg = c.surface })

hl("Cursor", { fg = c.bg, bg = c.cursor })
hl("CursorLine", { bg = c.surface })
hl("CursorLineNr", { fg = c.fg, bg = c.surface })

hl("LineNr", { fg = c.fg_dim })
hl("SignColumn", { bg = c.bg })

hl("Visual", { bg = "#505A60", fg = "#9da9a0" })
hl("Search", { fg = c.bg, bg = c.accent_primary })
hl("IncSearch", { fg = c.bg, bg = c.accent_primary })

hl("MatchParen", { fg = c.cyan_bright, bold = true })

hl("ColorColumn", { bg = c.surface })
hl("Conceal", { fg = c.fg_dim })

----------------------------------------------------------------
-- Windows / borders
----------------------------------------------------------------

hl("WinSeparator", { fg = c.border_soft })
hl("VertSplit", { fg = c.border_soft })

hl("FloatBorder", { fg = c.border })
hl("FloatTitle", { fg = c.accent_secondary })

hl("NormalFloat", { bg = c.surface })

----------------------------------------------------------------
-- Statusline
----------------------------------------------------------------

hl("StatusLine", { fg = c.fg, bg = c.surface_alt })
hl("StatusLineNC", { fg = c.fg_dim, bg = c.surface })

----------------------------------------------------------------
-- Popup menu
----------------------------------------------------------------

hl("Pmenu", { fg = c.fg_muted, bg = c.surface })
hl("PmenuSel", { fg = c.bg, bg = c.accent_secondary })
hl("PmenuSbar", { bg = c.surface })
hl("PmenuThumb", { bg = c.border })

----------------------------------------------------------------
-- Diagnostics
----------------------------------------------------------------

hl("DiagnosticError", { fg = "#e67e80" })
hl("DiagnosticWarn", { fg = "#dbbc7f" })
hl("DiagnosticInfo", { fg = c.accent_secondary })
hl("DiagnosticHint", { fg = "#a7c080" })

hl("DiagnosticUnderlineError", { undercurl = true, sp = "#e67e80" })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = "#dbbc7f" })
hl("DiagnosticUnderlineInfo", { undercurl = true, sp = c.accent_secondary })
hl("DiagnosticUnderlineHint", { undercurl = true, sp = "#a7c080" })

----------------------------------------------------------------
-- Diff
----------------------------------------------------------------

hl("DiffAdd", { fg = "#a7c080" })
hl("DiffChange", { fg = c.accent_secondary })
hl("DiffDelete", { fg = "#e67e80" })
hl("DiffText", { fg = c.accent_primary })

----------------------------------------------------------------
-- Syntax
----------------------------------------------------------------

hl("Comment", { fg = c.fg_dim, italic = true })

hl("Identifier", { fg = c.fg_muted })
hl("Function", { fg = c.magenta_bright })

hl("Statement", { fg = c.blue_bright })
hl("Keyword", { fg = c.cyan, bold = true })

hl("Conditional", { fg = c.cyan })
hl("Repeat", { fg = c.cyan })

hl("Operator", { fg = c.blue })

hl("Constant", { fg = c.cyan })
hl("Number", { fg = c.red })
hl("Boolean", { fg = c.blue_bright })

hl("String", { fg = c.green_bright })

hl("Type", { fg = c.green })
hl("Structure", { fg = c.cyan })

hl("PreProc", { fg = c.blue_bright })

hl("Special", { fg = c.fg })

----------------------------------------------------------------
-- Treesitter
----------------------------------------------------------------

hl("@variable", { link = "Identifier" })
hl("@parameter", { fg = c.cyan_bright })
hl("@field", { fg = c.cyan })

hl("@function", { link = "Function" })
hl("@function.builtin", { fg = c.blue })

hl("@keyword", { link = "Keyword" })
hl("@operator", { link = "Operator" })

hl("@string", { link = "String" })
hl("@number", { link = "Number" })

----------------------------------------------------------------
-- Telescope
----------------------------------------------------------------

hl("TelescopeBorder", { fg = c.border })
hl("TelescopeSelection", { bg = c.surface_alt })
hl("TelescopePromptPrefix", { fg = c.accent_primary })
hl("TelescopeTitle", { fg = c.accent_secondary })

----------------------------------------------------------------
-- NeoTree
----------------------------------------------------------------

hl("NeoTreeDirectoryName", { fg = c.accent_secondary, bold = true })
hl("NeoTreeDirectoryIcon", { fg = c.accent_secondary })

hl("NeoTreeFileName", { fg = c.fg })
hl("NeoTreeFileNameOpened", { fg = c.fg, bold = true })

hl("NeoTreeGitAdded", { fg = "#a7c080" })
hl("NeoTreeGitDeleted", { fg = "#e67e80" })
hl("NeoTreeGitModified", { fg = "#dbbc7f" })

----------------------------------------------------------------
-- WhichKey
----------------------------------------------------------------

hl("WhichKey", { fg = c.accent_primary })
hl("WhichKeyGroup", { fg = c.accent_secondary })
hl("WhichKeyDesc", { fg = c.fg })
hl("WhichKeyBorder", { link = "FloatBorder" })

----------------------------------------------------------------
-- Indent guides
----------------------------------------------------------------

hl("IndentBlanklineChar", { fg = c.surface_alt })
hl("MiniIndentscopeSymbol", { fg = c.accent_secondary })

----------------------------------------------------------------
-- Markdown
----------------------------------------------------------------

hl("markdownCode", { fg = c.cyan_bright })
hl("markdownHeadingDelimiter", { fg = c.accent_primary })
hl("markdownUrl", { fg = c.accent_secondary, underline = true })

