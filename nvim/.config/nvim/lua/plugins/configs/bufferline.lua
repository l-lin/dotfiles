local M = {}
M.setup = function()
  local config = {
    options = {
      show_close_icon = false,
      show_buffer_close_icons = false,
      color_icons = true,
      diagnostics = "nvim_lsp",
      indicator = {
        style = "none"
      }
    },
  }
  require("bufferline").setup(config)
end

return M
