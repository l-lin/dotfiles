local function add_codeblock_keymap()
  vim.keymap.set("i", "<A-c>", function()
    local row = unpack(vim.api.nvim_win_get_cursor(0))
    local lines = {
      "```",
      "```",
    }
    vim.api.nvim_buf_set_lines(0, row, row, false, lines)
    vim.api.nvim_win_set_cursor(0, { row + 1, 3 })
    vim.cmd("startinsert!")
  end, { buffer = true, desc = "Add codeblock" })
end

local M = {}
M.add_codeblock_keymap = add_codeblock_keymap
return M
