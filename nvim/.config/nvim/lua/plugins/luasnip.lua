local M = {}

M.setup = function()
  require("luasnip.loaders.from_snipmate").lazy_load()
  require("luasnip.loaders.from_vscode").lazy_load()
end

return M
