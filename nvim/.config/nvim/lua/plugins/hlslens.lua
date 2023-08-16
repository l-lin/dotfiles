local M = {}

M.attach_keymaps = function()
  local map = vim.keymap.set
  local kopts = { noremap = true, silent = true }

  map('n', 'n', [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], kopts)
  map('n', 'N', [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], kopts)
  map('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
  map('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
end

M.setup = function()
  require('hlslens').setup()
  M.attach_keymaps()
end

return M
