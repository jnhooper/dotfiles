local M = {}
local ascii = require 'ascii'

M.base46 = {
  theme = 'nightowl', -- default theme
  hl_add = {},
  hl_override = {},
  integrations = {},
  changed_themes = {},
  transparency = false,
  theme_toggle = { 'onedark', 'nightowl' },
}
M.ui = {
  tabufline = {
    enabled = true,
    lazyload = true,
    order = { 'treeOffset', 'buffers', 'tabs', 'btns' },
    modules = nil,
  },
}

M.colorify = {
  enabled = true,
  mode = 'virtual', -- fg, bg, virtual
  virt_text = '󱓻 ',
  highlight = { hex = true, lspvars = true },
}

return M
