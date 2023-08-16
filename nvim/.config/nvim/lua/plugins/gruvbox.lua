local M = {}

M.get_background_color = function()
  return "#282828"
end

M.setup = function()
  vim.g.gruvbox_material_background = "medium" -- hard, soft, medium
  vim.g.gruvbox_material_foreground = "material" -- original, mix, material
  vim.g.gruvbox_material_enable_italic = 1
  vim.g.gruvbox_material_sign_column_background = 'none'

  vim.cmd [[ colorscheme gruvbox-material ]]
end

return M
