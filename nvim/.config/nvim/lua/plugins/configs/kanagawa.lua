local M = {}

M.setup = function()
  require("kanagawa").setup({
    colors = {
      theme = {
        all = {
          ui = {
            bg_gutter = "none"
          }
        }
      }
    },
  })

  vim.cmd [[ colorscheme kanagawa ]]
end

return M
