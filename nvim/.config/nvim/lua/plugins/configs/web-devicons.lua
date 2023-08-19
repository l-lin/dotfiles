local M = {}

M.setup = function()
  local config = {
    default = true
  }
  require("nvim-web-devicons").setup(config)
end

return M
