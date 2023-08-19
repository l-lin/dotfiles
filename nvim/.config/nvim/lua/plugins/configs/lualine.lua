local M = {}

M.setup = function()
  require("lualine").setup({
    options = {
      theme = "kanagawa",
      section_separators = "",
      component_separators = ""
    },
    sections = {
      lualine_x = {
        {
          require("lazy.status").updates,
          cond = require("lazy.status").has_updates,
          color = { fg = "#ff9e64" },
        },
      },
    },
  })
end

return M
