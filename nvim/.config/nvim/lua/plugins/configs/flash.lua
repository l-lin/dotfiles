local M = {}

M.setup = function()
  require("flash").setup({
    search = {
      mode = "search",
    },
    label = {
      rainbow = {
        enabled = true,
      }
    }
  })
end

return M
