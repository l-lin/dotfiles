local M = {}

M.setup = function()
  require("fidget").setup({
    text = {
      spinner = "dots",
    }
  })
end

return M
