-- set border style
vim.g.border_style="rounded"
-- flag to indicate we are in NixOS
vim.g.is_nixos=true
-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
