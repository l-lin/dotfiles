-- Enable telescope theme
vim.g.gruvbox_baby_telescope_theme = 1
vim.g.gruvbox_baby_keyword_style = 'NONE'

-- keeping it here instead of vim_conf.lua because the plugin needs to be configured before the call
vim.cmd [[ colorscheme gruvbox-baby ]]
