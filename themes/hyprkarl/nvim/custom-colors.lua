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
  bg             = "#1b1519",
  surface        = "#2f252c",
  surface_alt    = "#43343e",

  fg             = "#d2ccd2",
  fg_muted       = "#b3a9b3",
  fg_dim         = "#8a7b8a",

  black          = "#2e2329",

  red            = "#cc5555",
  red_bright     = "#dd6666",

  green          = "#96708e",
  green_bright   = "#c7a3bf",

  yellow         = "#d7937d",
  yellow_bright  = "#f4b39e",

  blue           = "#6843ae",
  blue_bright    = "#9877dc",

  magenta        = "#63005A",
  magenta_bright = "#8a1a80",

  cyan           = "#a46fd6",
  cyan_bright    = "#dea6f5",

  white          = "#d2ccd2",
  white_bright   = "#e8e8e8",

  cursor         = "#e3a16f",

  border         = "#63005A",
  border_soft    = "#3a0035",

  highlight      = "#8a1a80",
}

----------------------------------------------------------------
-- Terminal colors
----------------------------------------------------------------

vim.g.terminal_color_0  = c.black
vim.g.terminal_color_1  = c.red
vim.g.terminal_color_2  = c.green
vim.g.terminal_color_3  = c.yellow
vim.g.terminal_color_4  = c.blue
vim.g.terminal_color_5  = c.magenta
vim.g.terminal_color_6  = c.cyan
vim.g.terminal_color_7  = c.fg

vim.g.terminal_color_8  = c.surface
vim.g.terminal_color_9  = c.red_bright
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

hl("Visual", { bg = c.cursor, fg = c.bg })
hl("Search", { fg = c.bg, bg = c.magenta_bright })
hl("IncSearch", { fg = c.bg, bg = c.magenta })

hl("MatchParen", { fg = c.cyan_bright, bold = true })

hl("ColorColumn", { bg = c.surface })
hl("Conceal", { fg = c.fg_dim })

----------------------------------------------------------------
-- Windows / borders
----------------------------------------------------------------

hl("WinSeparator", { fg = c.border_soft })
hl("VertSplit", { fg = c.border_soft })

hl("FloatBorder", { fg = c.border })
hl("FloatTitle", { fg = c.cyan })

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
hl("PmenuSel", { fg = c.bg, bg = c.cyan })
hl("PmenuSbar", { bg = c.surface })
hl("PmenuThumb", { bg = c.border })

----------------------------------------------------------------
-- Diagnostics
----------------------------------------------------------------

hl("DiagnosticError", { fg = c.red })
hl("DiagnosticWarn", { fg = c.yellow })
hl("DiagnosticInfo", { fg = c.cyan })
hl("DiagnosticHint", { fg = c.green })

hl("DiagnosticUnderlineError", { undercurl = true, sp = c.red })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.yellow })
hl("DiagnosticUnderlineInfo", { undercurl = true, sp = c.cyan })
hl("DiagnosticUnderlineHint", { undercurl = true, sp = c.green })

----------------------------------------------------------------
-- Diff
----------------------------------------------------------------

hl("DiffAdd", { fg = c.green })
hl("DiffChange", { fg = c.blue })
hl("DiffDelete", { fg = c.red })
hl("DiffText", { fg = c.magenta })

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
hl("TelescopePromptPrefix", { fg = c.magenta_bright })
hl("TelescopeTitle", { fg = c.cyan })

----------------------------------------------------------------
-- NeoTree
----------------------------------------------------------------

hl("NeoTreeDirectoryName", { fg = c.cyan, bold = true })
hl("NeoTreeDirectoryIcon", { fg = c.cyan })

hl("NeoTreeFileName", { fg = c.fg })
hl("NeoTreeFileNameOpened", { fg = c.fg, bold = true })

hl("NeoTreeGitAdded", { fg = c.green })
hl("NeoTreeGitDeleted", { fg = c.red })
hl("NeoTreeGitModified", { fg = c.yellow })

----------------------------------------------------------------
-- WhichKey
----------------------------------------------------------------

hl("WhichKey", { fg = c.magenta_bright })
hl("WhichKeyGroup", { fg = c.cyan })
hl("WhichKeyDesc", { fg = c.fg })
hl("WhichKeyBorder", { link = "FloatBorder" })

----------------------------------------------------------------
-- Indent guides
----------------------------------------------------------------

hl("IndentBlanklineChar", { fg = c.surface_alt })
hl("MiniIndentscopeSymbol", { fg = c.cyan })

----------------------------------------------------------------
-- Markdown
----------------------------------------------------------------

hl("markdownCode", { fg = c.cyan_bright })
hl("markdownHeadingDelimiter", { fg = c.magenta })
hl("markdownUrl", { fg = c.cyan, underline = true })