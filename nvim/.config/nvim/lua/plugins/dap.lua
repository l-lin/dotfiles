local map = vim.api.nvim_set_keymap

map('n', '<F9>', '<Cmd>lua require("dap").continue()<CR>', { noremap = true })
map('n', '<F4>', '<Cmd>lua require("dap").close()<CR>', { noremap = true })
map('n', '<F32>', '<Cmd>lua require("dap").toggle_breakpoint()<CR>', { noremap = true })
--map('n', '<F5>', '<Cmd>lua require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))<CR>', { noremap = true })
--map('n', '<F6>', '<Cmd>lua require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))<CR>', { noremap = true })
map('n', '<F8>', '<Cmd>lua require("dap").step_over()<CR>', { noremap = true })
map('n', '<F7>', '<Cmd>lua require("dap").step_into()<CR>', { noremap = true })
map('n', '<F20>', '<Cmd>lua require("dap").step_out()<CR>', { noremap = true })

local dap = require('dap')
dap.adapters.go = {
  type = 'executable';
  name = 'go';
  command = vim.fn.stdpath("data") .. '/mason/packages/go-debug-adapter/go-debug-adapter';
}
dap.configurations.go = {
  {
    type = 'go';
    name = 'Debug';
    request = 'launch';
    showLog = false;
    program = "${file}";
    dlvToolPath = vim.fn.exepath('dlv')  -- Adjust to where delve is installed
  },
}
