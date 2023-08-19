local M = {}

M.setup = function()
  local config = {
    colors = {
      theme = {
        all = {
          ui = {
            bg_gutter = "none"
          }
        }
      }
    },
  }

  require("kanagawa").setup(config)

  vim.cmd [[ colorscheme kanagawa ]]
end

return M
