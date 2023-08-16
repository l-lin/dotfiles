local M = {}

M.setup = function()
  local config = {
    options = {
      theme = "gruvbox-material",
      section_separators = "",
      component_separators = ""
    }
  }
  require("lualine").setup(config)
end

return M
