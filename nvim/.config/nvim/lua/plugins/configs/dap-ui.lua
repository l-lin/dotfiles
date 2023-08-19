local M = {}

M.setup = function()
  require("dapui").setup({
    force_buffers = false,
    element_mappings = {
      scopes = {
        edit = "l",
      },
    },
    render = {
      max_value_lines = 3,
    },
    floating = {
      max_width = 0.9,
      max_height = 0.5,
      border = vim.g.border_chars,
    },
  })
end

return M
