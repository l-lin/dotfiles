-- NVIM keymaps
-- tips: for non-conventional keys, e.g. CTR+F1, you can use the the following:
-- in Insert mode, press CTRL+K, then press the desired key combination to get
-- the associated mapping.
-- Source: https://www.reddit.com/r/vim/comments/9jy0pt/how_to_remap_cf1/

-- n  Normal mode map. Defined using '<cmd>nmap' or '<cmd>nnoremap'.
-- i  Insert mode map. Defined using '<cmd>imap' or '<cmd>inoremap'.
-- v  Visual and select mode map. Defined using '<cmd>vmap' or '<cmd>vnoremap'.
-- x  Visual mode map. Defined using '<cmd>xmap' or '<cmd>xnoremap'.
-- s  Select mode map. Defined using '<cmd>smap' or '<cmd>snoremap'.
-- c  Command-line mode map. Defined using '<cmd>cmap' or '<cmd>cnoremap'.
-- o  Operator pending mode map. Defined using '<cmd>omap' or '<cmd>onoremap'.
local map = vim.keymap.set

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
map('n', '<leader>lc', '<cmd>setlocal spell!<CR>', { noremap = true, desc = 'Toggle spell checking' })
map('n', '<leader>le', '<cmd>setlocal spell spelllang=en<CR>', { noremap = true, desc = 'Set spelling english' })
map('n', '<leader>lf', '<cmd>setlocal spell spelllang=fr<CR>', { noremap = true, desc = 'Set spelling french' })

-- save, quit
map('n', '<C-s>', '<cmd>w!<CR>', { noremap = true, desc = 'Fast saving' })
map('n', '<F28>', '<cmd>bd<CR>', { noremap = true, silent = true, desc = 'Close current buffer' })

-- navigation
map('n', '<C-k>', '<cmd>wincmd k<CR>', { noremap = true, desc = 'Move to upper window' })
map('n', '<C-j>', '<cmd>wincmd j<CR>', { noremap = true, desc = 'Move to below window' })
map('n', '<C-h>', '<cmd>wincmd h<CR>', { noremap = true, desc = 'Move to left window' })
map('n', '<C-l>', '<cmd>wincmd l<CR>', { noremap = true, desc = 'Move to right window' })
map('n', '<F12>', '<cmd>bn<CR>', { noremap = true, silent = true, desc = 'Next buffer' })
map('n', '<F24>', '<cmd>bp<CR>', { noremap = true, silent = true, desc = 'Previous buffer (Shift+F12)' })

-- editing
map('n', '<C-y>', 'dd', { noremap = true, desc = 'Delete line' })
-- use different buffer for delete and paste
map('n', 'd', '"_d', { noremap = true })
map('v', 'd', '"_d', { noremap = true })
map('v', 'p', '"_dP', { noremap = true })
--map('n', '<A-k>', '<cmd>m-2<CR>==', { noremap = true, desc = 'Move line up' })
--map('n', '<A-j>', '<cmd>m+<CR>==', { noremap = true, desc = 'Move line down' })
-- do not include white space characters when using $ in visual mode, see https://vi.stackexchange.com/q/12607/15292
map('x', '$', 'g_')
-- go to first character in line (need to stretch my left hand to type ^)
map('x', '0', '^')
map('n', '0', '^')
-- continuous visual shifting (does not exit Visual mode), `gv` means
-- to reselect previous visual area, see https://superuser.com/q/310417/736190
map('x', '<', '<gv')
map('x', '>', '>gv')
-- always use very magic mode for searching (type `:help magic` for more information)
-- map('n', '/', [[/\v]])

-- misc
map('n', ',', '<cmd>set hlsearch! hlsearch?<CR>', { noremap = true, silent = true, desc = 'Toggle search highlight' })
map('n', '<F2>', '<cmd>set invpaste paste?<CR>', { noremap = true, silent = true, desc = 'Toggle auto-indenting for code paste'})
map('n', '<leader>vl', '<cmd>Lazy<cr>', { noremap = true, desc = 'Open Lazy' })

