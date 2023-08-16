local M = {}

M.setup = function()
  local config = {
    library = {
      plugins = {
        "nvim-dap-ui",
      },
      types = true,
    },
  }

  require("neodev").setup(config)
end

return M
