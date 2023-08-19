local M = {}

local function change_breakpoint_icon()
  vim.api.nvim_set_hl(0, "blue", { fg = "#3d59a1" })
  vim.api.nvim_set_hl(0, "red", { fg = "#ea6962" })
  vim.api.nvim_set_hl(0, "green", { fg = "#9ece6a" })
  vim.api.nvim_set_hl(0, "yellow", { fg = "#FFFF00" })
  vim.api.nvim_set_hl(0, "orange", { fg = "#f09000" })

  vim.fn.sign_define('DapBreakpoint', { text = ' ', texthl = 'red', })
  vim.fn.sign_define('DapBreakpointCondition', { text = 'ﳁ ', texthl = 'blue', })
  vim.fn.sign_define('DapBreakpointRejected', { text = ' ', texthl = 'orange', })
  vim.fn.sign_define('DapStopped', { text = ' ', texthl = 'green', })
  vim.fn.sign_define('DapLogPoint', { text = ' ', texthl = 'yellow', })
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

  change_breakpoint_icon()
end

return M
