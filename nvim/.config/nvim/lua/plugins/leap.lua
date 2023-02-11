vim.keymap.set('n', '<leader>nl', function()
  local current_window = vim.fn.win_getid()
  require('leap').leap { target_windows = { current_window } }
end, { noremap = true, silent = true, desc = 'Leap to' })
