local function add_codeblock_keymap()
  vim.keymap.set("i", "<M-c>", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line = cursor_pos[1]

    local codeblock = {
      "```",
      "```",
    }

    vim.api.nvim_buf_set_lines(bufnr, line - 1, line, false, codeblock)
    vim.api.nvim_win_set_cursor(0, { line, 3 })
  end, { buffer = true, desc = "Add codeblock" })
end

local M = {}
M.add_codeblock_keymap = add_codeblock_keymap
return M
