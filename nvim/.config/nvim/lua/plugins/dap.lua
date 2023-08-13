local dap = require('dap')

-- GOLANG
dap.adapters.go = {
  type = "executable";
  name = "go";
  command = vim.fn.stdpath("data") .. "/mason/packages/go-debug-adapter/go-debug-adapter";
}
dap.configurations.go = {
  {
    type = "go";
    name = "Debug";
    request = "launch";
    showLog = false;
    program = "${file}";
    dlvToolPath = vim.fn.exepath("dlv")  -- Adjust to where delve is installed
  },
}

-- -------------------------------
-- KEYMAPS
-- -------------------------------
local map = vim.keymap.set

map("n", "<F9>", "<Cmd>lua require('dap').continue()<CR>", { noremap = true, desc = "Begin debug session (Shift+F9)"  })
map("n", "<F21>", "<Cmd>lua require('dap').continue()<CR>", { noremap = true, desc = "Begin debug session (Shift+F9)"  })
map("n", "<leader>db", "<Cmd>lua require('dap').continue()<CR>", { noremap = true, desc = "Begin debug session (Shift+F9)" })

map("n", "<F4>", "<Cmd>lua require('dap').close()<CR>", { noremap = true, desc = "End debug session (F4)"  })
map("n", "<leader>de", "<Cmd>lua require('dap').close()<CR>", { noremap = true, desc = "End debug session (F4)" })

map("n", "<F32>", "<Cmd>lua require('dap').toggle_breakpoint()<CR>", { noremap = true, desc = "Toggle breakpoint (Ctrl+F8)" })
map("n", "<leader>dd", "<Cmd>lua require('dap').toggle_breakpoint()<CR>", { noremap = true, desc = "Toggle breakpoint (Ctrl+F8)" })

--map("n", "<F5>", "<Cmd>lua require('dap').set_breakpoint(vim.fn.input("Breakpoint condition: "))<CR>", { noremap = true })
--map("n", "<F6>", "<Cmd>lua require('dap').set_breakpoint(nil, nil, vim.fn.input("Log point message: "))<CR>", { noremap = true })
map("n", "<F8>", "<Cmd>lua require('dap').step_over()<CR>", { noremap = true, desc = "Step over (F8)" })
map("n", "<leader>dv", "<Cmd>lua require('dap').step_over()<CR>", { noremap = true, desc = "Step over (F8)" })
map("n", "<F7>", "<Cmd>lua require('dap').step_into()<CR>", { noremap = true, desc = "Step into (F7)" })
map("n", "<leader>di", "<Cmd>lua require('dap').step_into()<CR>", { noremap = true, desc = "Step into (F7)" })
map("n", "<F20>", "<Cmd>lua require('dap').step_out()<CR>", { noremap = true, desc = "Step out (Shift+F8)" })
map("n", "<leader>do", "<Cmd>lua require('dap').step_out()<CR>", { noremap = true, desc = "Step out (Shift+F8)" })

