local function augroup(name)
  return vim.api.nvim_create_augroup("my_" .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
      return
    end
    vim.b[buf].lazyvim_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    -- nvim
    "nvim-pack",
    "nvim-pack-ui",
    "checkhealth",
    "help",
    "lspinfo",
    "qf",
    "notify",
    "lsp-log",
    -- dbui
    "dbout",
    "neotest-output",
    "neotest-output-panel",
    "neotest-summary",
    "startuptime",
    "tsplayground",
    -- git
    "fugitive",
    "fugitiveblame",
    "git",
    "gitsigns-blame",
    "markdown.gh",
    -- dap-ui
    "dap-float",
    "dap-repl",
    "dapui_console",
    -- leetcode
    "leetcode.nvim",
    -- codecompanion / ai
    "codecompanion",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = "Quit buffer",
      })
    end)
  end,
})

-- make it easier to close man-files when opened inline
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("man_unlisted"),
  pattern = { "man" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
  end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown", "codecompanion", "markdown", "text", "markdown.snacks_picker_preview", "markdown.gh" },
  callback = function()
    vim.wo.wrap = true
    vim.wo.spell = true
  end,
})

vim.api.nvim_create_user_command("Codeowner", function()
  vim.notify(require("functions.git").codeowner(), vim.log.levels.INFO)
end, { desc = "Check file code ownership" })

-- Scratch buffer mode, yank all the file content on exit.
if vim.env.NVIM_SCRATCH then
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      vim.cmd("%y+")
    end,
  })
end

-- Auto create dir when saving a file
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  callback = function(event)
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
