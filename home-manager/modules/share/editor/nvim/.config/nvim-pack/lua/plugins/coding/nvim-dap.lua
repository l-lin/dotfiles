local function setup()
  require("nvim-dap-virtual-text").setup({})

  vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
  vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError" })
  vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticWarn" })
  vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DiagnosticError" })
  vim.fn.sign_define("DapLogPoint", { text = ".>", texthl = "DiagnosticInfo" })
  vim.fn.sign_define("DapStopped", { text = "󰁕", texthl = "DiagnosticInfo", linehl = "DapStoppedLine" })

  local typescript = require("functions.lang.typescript")
  if typescript.setup_dap then
    typescript.setup_dap()
  end

  local map = vim.keymap.set
  map("n", "<F9>", function()
    require("dap").continue()
  end, { desc = "Begin debug session (F9)", noremap = true, silent = true })
  map("n", "<F32>", function()
    require("dap").toggle_breakpoint()
  end, { desc = "Toggle breakpoint (Ctrl+F8)", noremap = true, silent = true })
  map("n", "<F8>", function()
    require("dap").step_over()
  end, { desc = "Step over (F8)", noremap = true, silent = true })
  map("n", "<F7>", function()
    require("dap").step_into()
  end, { desc = "Step into (F7)", noremap = true, silent = true })
  map("n", "<F20>", function()
    require("dap").step_out()
  end, { desc = "Step out (Shift+F8)", noremap = true, silent = true })
  map("n", "<F26>", function()
    require("dap").terminate()
  end, { desc = "Terminate DAP (Ctrl+F2)" })
end

---@type vim.pack.Spec[]
return {
  -- Debug Adapter Protocol client implementation for Neovim.
  {
    src = "https://github.com/mfussenegger/nvim-dap",
  },
  -- Add virtual text.
  {
    src = "https://github.com/theHamsta/nvim-dap-virtual-text",
    data = {
      setup = function()
        vim.schedule(setup)
      end,
    },
  },
}
