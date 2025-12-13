--
-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
--

-- Close buffer with `q`.
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
    -- codecompanion / ai
    "codecompanion",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Consider Jenkinsfile as groovy files.
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = "Jenkinsfile",
  callback = function()
    vim.bo.filetype = "groovy"
  end,
})

-- Consider bats test files as shell files.
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = "*.bats",
  callback = function()
    vim.bo.filetype = "sh"
  end,
})

-- Set text width everywhere except in my notes project.
vim.api.nvim_create_autocmd({ "BufNewFile", "BufEnter" }, {
  pattern = "*.md",
  callback = function()
    local current_file = vim.fn.expand("%:p")
    local notes_dir = vim.fn.expand(vim.g.notes_dir)

    if string.find(current_file, notes_dir, 1, true) == 1 then
      vim.bo.textwidth = 0
      vim.wo.wrap = true
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("text_wrap", { clear = true }),
  pattern = { "codecompanion", "gitcommit", "markdown" },
  callback = function()
    vim.wo.wrap = true
    -- vim.bo.textwidth = 80
  end,
})
