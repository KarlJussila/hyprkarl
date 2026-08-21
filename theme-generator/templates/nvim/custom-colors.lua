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
	bg = "{{base.background}}",
	surface = "{{base.surface}}",
	surface_alt = "{{base.surface_alt}}",

	fg = "{{base.foreground}}",
	fg_muted = "{{base.foreground_muted}}",
	fg_dim = "{{base.foreground_dim}}",

	black = "{{ansi.black}}",

	red = "{{ansi.red}}",
	red_bright = "{{bright.red}}",

	green = "{{ansi.green}}",
	green_bright = "{{bright.green}}",

	yellow = "{{ansi.yellow}}",
	yellow_bright = "{{bright.yellow}}",

	blue = "{{ansi.blue}}",
	blue_bright = "{{bright.blue}}",

	magenta = "{{ansi.magenta}}",
	magenta_bright = "{{bright.magenta}}",

	cyan = "{{ansi.cyan}}",
	cyan_bright = "{{bright.cyan}}",

	white = "{{ansi.white}}",
	white_bright = "{{bright.white}}",

	cursor = "{{ui.cursor}}",

	border = "{{accent.primary.base}}",
	border_soft = "{{accent.primary.soft}}",

	highlight = "{{accent.primary.bright}}",

	accent_primary = "{{accent.primary.base}}",
	accent_secondary = "{{accent.secondary.base}}",
	accent_tertiary = "{{accent.tertiary.base}}",
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

hl("Visual", { bg = "{{ui.selection_bg}}", fg = "{{ui.selection_fg}}" })
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

hl("DiagnosticError", { fg = "{{status.error}}" })
hl("DiagnosticWarn", { fg = "{{status.warning}}" })
hl("DiagnosticInfo", { fg = c.accent_secondary })
hl("DiagnosticHint", { fg = "{{status.success}}" })

hl("DiagnosticUnderlineError", { undercurl = true, sp = "{{status.error}}" })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = "{{status.warning}}" })
hl("DiagnosticUnderlineInfo", { undercurl = true, sp = c.accent_secondary })
hl("DiagnosticUnderlineHint", { undercurl = true, sp = "{{status.success}}" })

----------------------------------------------------------------
-- Diff
----------------------------------------------------------------

hl("DiffAdd", { fg = "{{status.success}}" })
hl("DiffChange", { fg = c.accent_secondary })
hl("DiffDelete", { fg = "{{status.error}}" })
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

hl("NeoTreeGitAdded", { fg = "{{status.success}}" })
hl("NeoTreeGitDeleted", { fg = "{{status.error}}" })
hl("NeoTreeGitModified", { fg = "{{status.warning}}" })

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
