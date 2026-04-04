---Put the cursor in the middle of the screen, only when navigating with count.
---No need to move the whole screen when moving line by line.
---@param key string either 'j' or 'k'
local function move_to_middle_of_screen(key)
  if vim.v.count > 1 then
    vim.api.nvim_command("norm! " .. vim.v.count .. key .. "zz")
  else
    vim.api.nvim_command("norm! " .. key)
  end
end

---Move cursor to a specific column on the current line.
---@param col number 0-based column position
local function move_to_column(col)
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_is_valid(win) then
    local row = vim.api.nvim_win_get_cursor(win)[1]
    vim.api.nvim_win_set_cursor(win, { row, col })
  end
end


local M = {}
M.move_to_middle_of_screen = move_to_middle_of_screen
M.move_to_column = move_to_column
return M
