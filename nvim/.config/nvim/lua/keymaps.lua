-- NVIM keymaps
-- tips: for non-conventional keys, e.g. CTR+F1, you can use the the following:
-- in Insert mode, press CTRL+K, then press the desired key combination to get
-- the associated mapping.
-- Source: https://www.reddit.com/r/vim/comments/9jy0pt/how_to_remap_cf1/

-- n  Normal mode map. Defined using ':nmap' or ':nnoremap'.
-- i  Insert mode map. Defined using ':imap' or ':inoremap'.
-- v  Visual and select mode map. Defined using ':vmap' or ':vnoremap'.
-- x  Visual mode map. Defined using ':xmap' or ':xnoremap'.
-- s  Select mode map. Defined using ':smap' or ':snoremap'.
-- c  Command-line mode map. Defined using ':cmap' or ':cnoremap'.
-- o  Operator pending mode map. Defined using ':omap' or ':onoremap'.
local map = vim.api.nvim_set_keymap

-- mapleader
vim.g.mapleader = ' '

-- documentation
vim.cmd [[ command CheatSheet split $HOME/.config/nvim/doc/cheat_sheet.txt]]

-- abbreviations for common typos
vim.cmd [[
    cnoreabbrev   Q    q
    cnoreabbrev   W    w
    cnoreabbrev   Wq   wq
    cnoreabbrev   wQ   wq
    cnoreabbrev   WQ   wq
    cnoreabbrev   Qa   qa
]]

-- spell checking
map('n', '<leader>lc', ':setlocal spell!<CR>', { noremap = true, desc = 'Toggle spell checking' })
map('n', '<leader>le', ':setlocal spell spelllang=en<CR>', { noremap = true, desc = 'Set spelling english' })
map('n', '<leader>lf', ':setlocal spell spelllang=fr<CR>', { noremap = true, desc = 'Set spelling french' })

-- save, quit
map('n', '<C-s>', ':w!<CR>', { noremap = true, desc = 'Fast saving' })
map('n', '<F28>', ':bd<CR>', { noremap = true, silent = true, desc = 'Close current buffer' })

-- navigation
map('n', '<C-k>', ':wincmd k<CR>', { noremap = true, desc = 'Move to upper window' })
map('n', '<C-j>', ':wincmd j<CR>', { noremap = true, desc = 'Move to below window' })
map('n', '<C-h>', ':wincmd h<CR>', { noremap = true, desc = 'Move to left window' })
map('n', '<C-l>', ':wincmd l<CR>', { noremap = true, desc = 'Move to right window' })
map('n', '<Tab>', '<C-^>', { noremap = true, silent = true, desc = 'Switch back and forth from buffer' })
map('n', '<F12>', ':bn<CR>', { noremap = true, silent = true, desc = 'Next buffer' })
map('n', '<F24>', ':bp<CR>', { noremap = true, silent = true, desc = 'Previous buffer (Shift+F12)' })

-- editing
map('n', '<C-y>', 'dd', { noremap = true, desc = 'Delete line' })
-- use different buffer for delete and paste
map('n', 'd', '"_d', { noremap = true })
map('v', 'd', '"_d', { noremap = true })
map('v', 'p', '"_dP', { noremap = true })
--map('n', '<A-k>', ':m-2<CR>==', { noremap = true, desc = 'Move line up' })
--map('n', '<A-j>', ':m+<CR>==', { noremap = true, desc = 'Move line down' })

-- misc
map('n', ',', ':set hlsearch! hlsearch?<CR>', { noremap = true, silent = true, desc = 'Toggle search highlight' })
map('n', '<F2>', ':set invpaste paste?<CR>', { noremap = true, silent = true, desc = 'Toggle auto-indenting for code paste'})
map('n', '<leader>pu', '<cmd>PackerSync<cr>', { noremap = true, desc = 'Packer synchronize plugins' })
