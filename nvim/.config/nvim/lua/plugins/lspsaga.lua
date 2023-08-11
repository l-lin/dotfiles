require('lspsaga').setup({})

-- keymaps
vim.keymap.set('n', ']e', '<cmd>Lspsaga diagnostic_jump_next<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga diagnostic go to next' })
vim.keymap.set('n', '<F2>', '<cmd>Lspsaga diagnostic_jump_next<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga diagnostic go to next (F2)' })
vim.keymap.set('n', '[e', '<cmd>Lspsaga diagnostic_jump_prev<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga diagnostic go to previous' })
vim.keymap.set('n', '<F14>', '<cmd>Lspsaga diagnostic_jump_prev<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga diagnostic go to previous (Shift+F2)' })
vim.keymap.set('n', '[E', function()
  require('lspsaga.diagnostic'):goto_prev({ severity = vim.diagnostic.severity.ERROR })
end, { noremap = true, silent = true, desc = 'Lspsaga diagnostic go to previous ERROR' })
vim.keymap.set('n', ']E', function()
  require('lspsaga.diagnostic'):goto_next({ severity = vim.diagnostic.severity.ERROR })
end, { noremap = true, silent = true, desc = 'Lspsaga diagnostic go to next ERROR' })

vim.keymap.set('n', '<leader>cc', '<cmd>Lspsaga finder<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga definition and usage finder' })
vim.keymap.set('n', '<leader>ce', '<cmd>Lspsaga show_line_diagnostics<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga diagnostic show message' })
-- vim.keymap.set('n', '<leader>cd', '<cmd>Lspsaga goto_definition<CR>',
--     { noremap = true, silent = true, desc = 'Lspsaga go to definition' })
vim.keymap.set('n', '<leader>cD', '<cmd>Lspsaga peek_definition<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga peek definition' })
-- vim.keymap.set('n', '<leader>ct', '<cmd>Lspsaga goto_type_definition<CR>',
--     { noremap = true, silent = true, desc = 'Lspsaga goto type definition' })
vim.keymap.set('n', '<leader>cT', '<cmd>Lspsaga peek_type_definition<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga peek type definition' })
vim.keymap.set('n', '<leader>ci', '<cmd>Lspsaga incoming_calls<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga incoming calls' })
vim.keymap.set('n', '<leader>co', '<cmd>Lspsaga outgoing_calls<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga outgoing calls' })
vim.keymap.set('n', '<leader>cm', '<cmd>Lspsaga outline<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga outline minimap' })
vim.keymap.set('n', '<leader>cs', vim.lsp.buf.signature_help,
  { noremap = true, silent = true, desc = 'LSP signature help' })
vim.keymap.set('n', '<leader>cr', '<cmd>Lspsaga rename ++project<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga rename' })
vim.keymap.set('n', '<F18>', '<cmd>Lspsaga rename ++project<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga rename (Shift+F6)' })
vim.keymap.set('n', '<leader>cE', '<cmd>Lspsaga show_buf_diagnostics<CR>',
  { noremap = true, silent = true, desc = 'LSP show errors' })
-- vim.keymap.set('n', '<leader>ca', '<cmd>Lspsaga code_action<CR>',
--   { noremap = true, silent = true, desc = 'LSP code action' })
-- vim.keymap.set('n', '<M-CR>', '<cmd>Lspsaga code_action<CR>',
--   { noremap = true, silent = true, desc = 'LSP code action (Ctrl+Enter)' })
