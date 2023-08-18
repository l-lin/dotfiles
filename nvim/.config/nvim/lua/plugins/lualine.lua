local M = {}

M.setup = function()
  local config = {
    options = {
      theme = "kanagawa",
      section_separators = "",
      component_separators = ""
    }
  }
  require("lualine").setup(config)
end

return M
