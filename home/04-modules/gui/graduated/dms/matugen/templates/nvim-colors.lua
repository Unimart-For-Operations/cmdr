-- DMS matugen neovim colorscheme — auto-generated, do not edit.
-- Loaded as `:colorscheme dms` by nvim-astro's astroui.lua when this file
-- exists (DMS hosts). Deployed to ~/.local/share/nvim-astro/site/colors/ so it
-- sits on the runtimepath (stdpath("data")/site) without touching the read-only
-- ~/.config/nvim-astro/ symlinks.
--
-- Semantic roles follow the catppuccin-style naming yatline/nvim expect:
--   text  -> colors.on_surface
--   surface0/base -> colors.surface_container / colors.background
--   mauve -> colors.primary
--   blue  -> dank16.color4
--   green -> colors.secondary
--   red   -> colors.error
--   peach/yellow -> dank16.color3
vim.g.colors_name = "dms"

local C = {
  bg = "{{colors.background.default.hex}}",
  mantle = "{{colors.surface_container_lowest.default.hex}}",
  crust = "{{colors.surface_dim.default.hex}}",
  surface0 = "{{colors.surface_container.default.hex}}",
  surface1 = "{{colors.surface_container_high.default.hex}}",
  surface2 = "{{colors.surface_container_high.default.hex}}",
  overlay0 = "{{colors.outline.default.hex}}",
  overlay1 = "{{colors.on_surface_variant.default.hex}}",
  overlay2 = "{{colors.outline.default.hex}}",
  subtext0 = "{{colors.outline.default.hex}}",
  subtext1 = "{{colors.on_surface_variant.default.hex}}",
  text = "{{colors.on_surface.default.hex}}",
  mauve = "{{colors.primary.default.hex}}",
  blue = "{{dank16.color4.default.hex}}",
  sapphire = "{{colors.tertiary.default.hex}}",
  green = "{{colors.secondary.default.hex}}",
  teal = "{{colors.secondary.default.hex}}",
  sky = "{{colors.tertiary.default.hex}}",
  pink = "{{colors.tertiary.default.hex}}",
  red = "{{colors.error.default.hex}}",
  maroon = "{{colors.error.default.hex}}",
  peach = "{{dank16.color3.default.hex}}",
  yellow = "{{dank16.color3.default.hex}}",
  flamingo = "{{colors.tertiary.default.hex}}",
  rosewater = "{{colors.tertiary.default.hex}}",
}

local function hl(name, fg, bg, style)
  local spec = { fg = fg, bg = bg }
  if style then spec.style = style end
  vim.api.nvim_set_hl(0, name, spec)
end

-- Editor chrome
hl("Normal", C.text, C.bg)
hl("NormalFloat", C.text, C.mantle)
hl("FloatBorder", C.surface2, C.mantle)
hl("FloatTitle", C.blue, C.mantle)
hl("EndOfBuffer", C.mantle, C.bg)
hl("CursorLine", C.text, C.surface0)
hl("CursorLineNr", C.blue, C.surface0)
hl("LineNr", C.overlay1, C.bg)
hl("CursorColumn", C.text, C.surface0)
hl("Cursor", C.text, C.bg)
hl("Visual", C.text, C.surface1)
hl("VisualNOS", C.text, C.surface1)
hl("Search", C.bg, C.blue)
hl("IncSearch", C.bg, C.blue)
hl("CurSearch", C.bg, C.blue)
hl("MatchParen", C.text, C.surface2)
hl("Conceal", C.overlay1, C.bg)
hl("ColorColumn", C.text, C.surface0)
hl("SignColumn", C.overlay1, C.bg)
hl("VertSplit", C.surface1, C.surface1)
hl("WinSeparator", C.surface1, C.bg)
hl("FoldColumn", C.overlay1, C.bg)
hl("Folded", C.subtext1, C.surface0)
hl("Pmenu", C.text, C.surface0)
hl("PmenuSel", C.bg, C.blue)
hl("PmenuSbar", C.text, C.surface0)
hl("PmenuThumb", C.text, C.surface2)
hl("StatusLine", C.text, C.surface0)
hl("StatusLineNC", C.subtext1, C.mantle)
hl("TabLine", C.subtext1, C.mantle)
hl("TabLineFill", C.subtext1, C.mantle)
hl("TabLineSel", C.text, C.surface0)
hl("Title", C.blue, C.bg)
hl("Directory", C.blue, C.bg)
hl("Question", C.green, C.bg)
hl("MoreMsg", C.green, C.bg)
hl("WarningMsg", C.yellow, C.bg)
hl("ErrorMsg", C.red, C.bg)
hl("ModeMsg", C.blue, C.bg)
hl("WildMenu", C.bg, C.blue)

-- Syntax
hl("Comment", C.overlay1, C.bg, "italic")
hl("Todo", C.peach, C.bg)
hl("Constant", C.peach, C.bg)
hl("Number", C.peach, C.bg)
hl("Float", C.peach, C.bg)
hl("Boolean", C.peach, C.bg)
hl("Character", C.green, C.bg)
hl("String", C.green, C.bg)
hl("Special", C.peach, C.bg)
hl("SpecialChar", C.peach, C.bg)
hl("Identifier", C.text, C.bg)
hl("Function", C.blue, C.bg)
hl("Keyword", C.mauve, C.bg)
hl("Statement", C.mauve, C.bg)
hl("Conditional", C.mauve, C.bg)
hl("Repeat", C.mauve, C.bg)
hl("Label", C.mauve, C.bg)
hl("Operator", C.sky, C.bg)
hl("Exception", C.mauve, C.bg)
hl("PreProc", C.blue, C.bg)
hl("Include", C.mauve, C.bg)
hl("Define", C.blue, C.bg)
hl("Macro", C.blue, C.bg)
hl("PreCondit", C.blue, C.bg)
hl("Type", C.yellow, C.bg)
hl("StorageClass", C.yellow, C.bg)
hl("Structure", C.yellow, C.bg)
hl("Typedef", C.yellow, C.bg)
hl("Tag", C.text, C.bg)
hl("SpecialKey", C.overlay1, C.bg)
hl("NonText", C.overlay1, C.bg)
hl("Whitespace", C.overlay0, C.bg)
hl("MatchWord", C.text, C.surface2)
hl("MatchParen", C.text, C.surface2)
hl("Underlined", C.blue, C.bg, "underline")

-- Diffs
hl("DiffAdd", C.green, C.bg)
hl("DiffDelete", C.red, C.bg)
hl("DiffChange", C.yellow, C.bg)
hl("DiffText", C.blue, C.bg)

-- Diagnostics (LSP / vim.diagnostic)
hl("DiagnosticError", C.red, C.bg)
hl("DiagnosticWarn", C.yellow, C.bg)
hl("DiagnosticInfo", C.blue, C.bg)
hl("DiagnosticHint", C.teal, C.bg)
hl("DiagnosticOk", C.green, C.bg)
hl("DiagnosticUnderlineError", C.red, C.bg, "underline")
hl("DiagnosticUnderlineWarn", C.yellow, C.bg, "underline")
hl("DiagnosticUnderlineInfo", C.blue, C.bg, "underline")
hl("DiagnosticUnderlineHint", C.teal, C.bg, "underline")

-- LSP references
hl("LspReferenceText", C.text, C.surface1)
hl("LspReferenceRead", C.blue, C.surface1)
hl("LspReferenceWrite", C.green, C.surface1)
hl("LspCodeLens", C.overlay1, C.bg)
hl("LspSignatureActiveParameter", C.peach, C.bg)

-- Treesitter highlights
hl("@comment", C.overlay1, C.bg, "italic")
hl("@error", C.red, C.bg)
hl("@keyword", C.mauve, C.bg)
hl("@keyword.function", C.mauve, C.bg)
hl("@keyword.return", C.mauve, C.bg)
hl("@keyword.operator", C.mauve, C.bg)
hl("@keyword.conditional", C.mauve, C.bg)
hl("@keyword.repeat", C.mauve, C.bg)
hl("@keyword.exception", C.mauve, C.bg)
hl("@keyword.import", C.blue, C.bg)
hl("@function", C.blue, C.bg)
hl("@function.call", C.blue, C.bg)
hl("@function.method", C.blue, C.bg)
hl("@function.method.call", C.blue, C.bg)
hl("@function.builtin", C.blue, C.bg)
hl("@function.macro", C.blue, C.bg)
hl("@constructor", C.peach, C.bg)
hl("@variable", C.text, C.bg)
hl("@variable.builtin", C.sky, C.bg)
hl("@variable.member", C.sky, C.bg)
hl("@variable.parameter", C.text, C.bg)
hl("@property", C.sky, C.bg)
hl("@field", C.sky, C.bg)
hl("@constant", C.peach, C.bg)
hl("@constant.builtin", C.peach, C.bg)
hl("@constant.macro", C.peach, C.bg)
hl("@string", C.green, C.bg)
hl("@string.escape", C.blue, C.bg)
hl("@string.regexp", C.teal, C.bg)
hl("@string.special", C.green, C.bg)
hl("@character", C.green, C.bg)
hl("@number", C.peach, C.bg)
hl("@number.float", C.peach, C.bg)
hl("@boolean", C.peach, C.bg)
hl("@type", C.yellow, C.bg)
hl("@type.builtin", C.yellow, C.bg)
hl("@type.definition", C.yellow, C.bg)
hl("@type.qualifier", C.mauve, C.bg)
hl("@operator", C.sky, C.bg)
hl("@punctuation.delimiter", C.overlay2, C.bg)
hl("@punctuation.bracket", C.overlay2, C.bg)
hl("@punctuation.special", C.text, C.bg)
hl("@label", C.mauve, C.bg)
hl("@tag", C.blue, C.bg)
hl("@tag.attribute", C.teal, C.bg)
hl("@tag.delimiter", C.overlay2, C.bg)
hl("@attribute", C.teal, C.bg)
hl("@include", C.blue, C.bg)
hl("@namespace", C.blue, C.bg)
hl("@exception", C.mauve, C.bg)
hl("@preproc", C.blue, C.bg)
hl("@define", C.blue, C.bg)
hl("@macro", C.blue, C.bg)
hl("@storageclass", C.yellow, C.bg)
hl("@storageclass.lifetime", C.yellow, C.bg)
hl("@special", C.peach, C.bg)
hl("@specialchar", C.peach, C.bg)
