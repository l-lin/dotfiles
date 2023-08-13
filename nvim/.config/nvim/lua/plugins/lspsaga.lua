require('lspsaga').setup({})

local map = vim.keymap.set

-- keymaps
map('n', ']e', '<cmd>Lspsaga diagnostic_jump_next<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga diagnostic go to next' })
map('n', '<F2>', '<cmd>Lspsaga diagnostic_jump_next<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga diagnostic go to next (F2)' })
map('n', '[e', '<cmd>Lspsaga diagnostic_jump_prev<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga diagnostic go to previous' })
map('n', '<F14>', '<cmd>Lspsaga diagnostic_jump_prev<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga diagnostic go to previous (Shift+F2)' })
map('n', '[E', function()
  require('lspsaga.diagnostic'):goto_prev({ severity = vim.diagnostic.severity.ERROR })
end, { noremap = true, silent = true, desc = 'Lspsaga diagnostic go to previous ERROR' })
map('n', ']E', function()
  require('lspsaga.diagnostic'):goto_next({ severity = vim.diagnostic.severity.ERROR })
end, { noremap = true, silent = true, desc = 'Lspsaga diagnostic go to next ERROR' })

map('n', '<leader>cc', '<cmd>Lspsaga finder<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga definition and usage finder' })
map('n', '<leader>ce', '<cmd>Lspsaga show_line_diagnostics<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga diagnostic show message' })
-- map('n', '<leader>cd', '<cmd>Lspsaga goto_definition<CR>',
--     { noremap = true, silent = true, desc = 'Lspsaga go to definition' })
map('n', '<leader>cD', '<cmd>Lspsaga peek_definition<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga peek definition' })
-- map('n', '<leader>ct', '<cmd>Lspsaga goto_type_definition<CR>',
--     { noremap = true, silent = true, desc = 'Lspsaga goto type definition' })
map('n', '<leader>cT', '<cmd>Lspsaga peek_type_definition<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga peek type definition' })
map('n', '<leader>ci', '<cmd>Lspsaga incoming_calls<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga incoming calls' })
map('n', '<leader>co', '<cmd>Lspsaga outgoing_calls<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga outgoing calls' })
map('n', '<leader>cm', '<cmd>Lspsaga outline<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga outline minimap' })
map('n', '<leader>cs', vim.lsp.buf.signature_help,
  { noremap = true, silent = true, desc = 'LSP signature help' })
map('n', '<leader>cr', '<cmd>Lspsaga rename ++project<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga rename' })
map('n', '<F18>', '<cmd>Lspsaga rename ++project<CR>',
  { noremap = true, silent = true, desc = 'Lspsaga rename (Shift+F6)' })
map('n', '<leader>cE', '<cmd>Lspsaga show_buf_diagnostics<CR>',
  { noremap = true, silent = true, desc = 'LSP show errors' })
-- map('n', '<leader>ca', '<cmd>Lspsaga code_action<CR>',
--   { noremap = true, silent = true, desc = 'LSP code action' })
-- map('n', '<M-CR>', '<cmd>Lspsaga code_action<CR>',
--   { noremap = true, silent = true, desc = 'LSP code action (Ctrl+Enter)' })
