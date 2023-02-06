require("luasnip.loaders.from_snipmate").lazy_load()
require("luasnip.loaders.from_vscode").lazy_load()
vim.api.nvim_set_keymap('i', '<silent><expr> <Tab>',
    'luasnip#expand_or_jumpable() ? \'<Plug>luasnip-expand-or-jump\' : \'<Tab>\' ', {})
vim.api.nvim_set_keymap('i', '<silent> <S-Tab>', '<cmd>lua require\'luasnip\'.jump(-1)<Cr>', { noremap = true })
vim.api.nvim_set_keymap('s', '<silent> <Tab>', '<cmd>lua require(\'luasnip\').jump(1)<Cr>', { noremap = true })
vim.api.nvim_set_keymap('s', '<silent> <S-Tab>', '<cmd>lua require\'luasnip\'.jump(-1)<Cr>', { noremap = true })
vim.api.nvim_set_keymap('i', '<silent><expr> <C-E>',
    'luasnip#choice_active() ? \'<Plug>luasnip-next-choice\' : \'<C-E>\'', {})
vim.api.nvim_set_keymap('i', '<silent><expr> <C-E>',
    'luasnip#choice_active() ? \'<Plug>luasnip-next-choice\' : \'<C-E>\'', {})
