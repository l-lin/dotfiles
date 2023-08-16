local M = {}

M.change_breakpoint_icon = function()
  vim.api.nvim_set_hl(0, "blue", { fg = "#3d59a1" })
  vim.api.nvim_set_hl(0, "red", { fg = "#ea6962" })
  vim.api.nvim_set_hl(0, "green", { fg = "#9ece6a" })
  vim.api.nvim_set_hl(0, "yellow", { fg = "#FFFF00" })
  vim.api.nvim_set_hl(0, "orange", { fg = "#f09000" })

  vim.fn.sign_define('DapBreakpoint', { text = ' ', texthl = 'red', })
  vim.fn.sign_define('DapBreakpointCondition', { text = ' ﳁ', texthl = 'blue', })
  vim.fn.sign_define('DapBreakpointRejected', { text = ' ', texthl = 'orange', })
  vim.fn.sign_define('DapStopped', { text = ' ', texthl = 'green', })
  vim.fn.sign_define('DapLogPoint', { text = ' ', texthl = 'yellow', })
end

M.attach_keymaps = function()
  local map = require("mapper").map
  local bufopts = { noremap = true, silent = true }

  map("n", "<F9>", "<Cmd>lua require('dap').continue()<CR>", bufopts, "Begin debug session (F9)")
  map("n", "<leader>db", "<Cmd>lua require('dap').continue()<CR>", bufopts, "Begin debug session (F9)")

  map("n", "<F4>", "<Cmd>lua require('dap').close()<CR>", bufopts, "End debug session (F4)")
  map("n", "<leader>de", "<Cmd>lua require('dap').close()<CR>", bufopts, "End debug session (F4)")

  map("n", "<F32>", "<Cmd>lua require('dap').toggle_breakpoint()<CR>", bufopts, "Toggle breakpoint (Ctrl+F8)")
  map("n", "<leader>dt", "<Cmd>lua require('dap').toggle_breakpoint()<CR>", bufopts, "Toggle breakpoint (Ctrl+F8)")

  map("n", "<F8>", "<Cmd>lua require('dap').step_over()<CR>", bufopts, "Step over (F8)")
  map("n", "<leader>dv", "<Cmd>lua require('dap').step_over()<CR>", bufopts, "Step over (F8)")

  map("n", "<F7>", "<Cmd>lua require('dap').step_into()<CR>", bufopts, "Step into (F7)")
  map("n", "<leader>di", "<Cmd>lua require('dap').step_into()<CR>", bufopts, "Step into (F7)")

  map("n", "<F20>", "<Cmd>lua require('dap').step_out()<CR>", bufopts, "Step out (Shift+F8)")
  map("n", "<leader>do", "<Cmd>lua require('dap').step_out()<CR>", bufopts, "Step out (Shift+F8)")
end

M.setup = function()
  local dap = require('dap')

  -- GOLANG
  dap.adapters.go = {
    type = "executable",
    name = "go",
    command = vim.fn.stdpath("data") .. "/mason/packages/go-debug-adapter/go-debug-adapter",
  }
  dap.configurations.go = {
    {
      type = "go",
      name = "Debug",
      request = "launch",
      showLog = false,
      program = "${file}",
      dlvToolPath = vim.fn.exepath("dlv") -- Adjust to where delve is installed
    },
  }

  M.change_breakpoint_icon()
  M.attach_keymaps()
end

return M
