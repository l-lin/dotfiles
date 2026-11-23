if not vim.env.REX_BLOCK then
  return {}
end

-- Rex needs a known socket to select Neovim splits without terminal key translation.
-- See home-manager/modules/share/shell/multiplexer/rex/.config/rex/pane.lua for the integration.
local directory = vim.fn.expand("~/.cache/rex/nvim")
vim.fn.mkdir(directory, "p", "448")
assert(vim.uv.fs_chmod(directory, 448))
vim.fn.serverstart(directory .. "/" .. vim.env.REX_BLOCK:gsub("^block:", "") .. ".sock")

return {}
