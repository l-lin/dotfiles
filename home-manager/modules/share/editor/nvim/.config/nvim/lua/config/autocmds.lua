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

-- Set word wrap and spell check for writing filetypes.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("writing", { clear = true }),
  pattern = { "codecompanion", "gitcommit", "markdown", "text" },
  callback = function()
    vim.wo.wrap = true
    vim.wo.spell = true

    local current_file = vim.fn.expand("%:p")
    local notes_dir = vim.fn.expand(vim.g.notes_dir)
    -- No text width limit for my notes.
    if string.find(current_file, notes_dir, 1, true) == 1 then
      vim.bo.textwidth = 0
    else
      vim.bo.textwidth = 80
    end
  end,
})

-- Scratch buffer mode, yank all the file content on exit.
if vim.env.NVIM_SCRATCH then
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      vim.cmd("%y+")
      vim.fn.system("pbcopy", vim.fn.getreg("+"))
    end,
  })
end

