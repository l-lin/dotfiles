local M = {}

M.setup = function()
  require("neodev").setup({
    library = {
      plugins = {
        "nvim-dap-ui",
      },
      types = true,
    },
  })
end

return M
