local M = {}
M.setup = function()
  local config = {
    text = {
      spinner = "dots",
    }
  }
  require("fidget").setup(config)
end
return M
