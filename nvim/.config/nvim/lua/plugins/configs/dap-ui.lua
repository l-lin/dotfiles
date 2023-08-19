local M = {}

M.attach_keymaps = function()
  vim.keymap.set("n", "<M-5>", "<cmd>lua require('dapui').toggle({ reset = true })<cr>",
    { noremap = true, desc = "Open DAP UI (Alt+5)" })
  vim.keymap.set("n", "<leader>du", "<cmd>lua require('dapui').toggle({ reset = true })<cr>",
    { noremap = true, desc = "Open DAP UI (Alt+5)" })
  vim.keymap.set("n", "<leader>da", "<cmd>lua require('dapui').eval()<cr>",
    { noremap = true, silent = true, desc = "Evaluate" })
  vim.keymap.set("n", "<leader>df", "<cmd>lua require('dapui').float_element()<cr>",
    { noremap = true, silent = true, desc = "Float element" })
end

M.setup = function()
  local config = {
    force_buffers = false,
    element_mappings = {
      scopes = {
        edit = "l",
      },
    },
    render = {
      max_value_lines = 3,
    },
    floating = { max_width = 0.9, max_height = 0.5, border = vim.g.border_chars },
  }

  require("dapui").setup(config)

  M.attach_keymaps()
end

return M
