-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("close_with_q", { clear = true }),
  pattern = {
    -- git
    "fugitive",
    "fugitiveblame",
    "git",
    -- diffview
    "DiffviewFiles",
    "DiffviewFileHistory",
    -- dap-ui
    "dap-float",
    "dap-repl",
    "dapui_console",
    -- dbui
    "dbout",
    -- leetcode
    "leetcode.nvim",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Consider Jenkinsfile as groovy files
vim.api.nvim_exec([[
  autocmd BufNewFile,BufRead Jenkinsfile setfiletype groovy
]], false)

-- Consider bats test files as shell files
vim.api.nvim_exec([[
  autocmd BufNewFile,BufRead *.bats setfiletype sh
]], false)

