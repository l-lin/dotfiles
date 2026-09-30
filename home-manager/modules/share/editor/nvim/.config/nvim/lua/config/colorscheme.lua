-- To use local neovim plugin, uncomment the following:
-- local plugin_path = vim.fn.expand("~/perso/github/nvim-grey")
-- vim.opt.rtp:prepend(plugin_path)
vim.pack.add({ "https://github.com/l-lin/nvim-grey" }, { load = true, confirm = false })
vim.o.bg = "light"
vim.g.colorscheme = "grey"
vim.cmd.colorscheme("grey")
