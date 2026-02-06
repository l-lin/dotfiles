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

-- :Translate command - translate words using `trans` CLI
-- Usage: :Translate <word(s)> [target_language]
-- Example: :Translate hello fr
-- Example: :Translate hello world fr  (multi-word: last 2-letter arg is target lang)
vim.api.nvim_create_user_command("Translate", function(opts)
  local args = opts.fargs
  if #args < 1 then
    vim.notify("Usage: :Translate <word(s)> [target_language]", vim.log.levels.ERROR)
    return
  end

  local target_lang = "en"
  local word_args = args

  -- If last arg looks like a language code (2-3 letters), treat it as target
  local last = args[#args]
  if #args > 1 and #last >= 2 and #last <= 3 and last:match("^%a+$") then
    target_lang = last
    word_args = { unpack(args, 1, #args - 1) }
  end

  local word = table.concat(word_args, " ")

  require("helpers.translate").translate(word, target_lang, {
    on_result = function(formatted, main_translation)
      if #formatted > 0 then
        local _, winnr = vim.lsp.util.open_floating_preview(formatted, "markdown", {
          border = "rounded",
          title = string.format(" %s → %s ", word, target_lang),
          title_pos = "center",
          focus = true,
          focusable = true,
        })
        vim.api.nvim_set_current_win(winnr)
        vim.api.nvim_win_set_cursor(winnr, { 3, 0 })

        if main_translation then
          vim.fn.setreg("+", main_translation)
        end
      else
        vim.notify("No translation found for: " .. word, vim.log.levels.WARN)
      end
    end,
    on_error = function(msg)
      vim.notify(msg, vim.log.levels.ERROR)
    end,
  })
end, {
  nargs = "+",
  desc = "Translate word using trans CLI",
})
