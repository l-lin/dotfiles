---Calculate insert column position.
---This extracts the logic from insert_string_at_current_cursor for unit testing
---@param col number the current column position
---@param line_len number the length of the current line
---@param mode string the current mode ('n' for normal, 'i' for insert)
---@return number the calculated insert column position
local function calculate_insert_col(col, line_len, mode)
  local insert_col = col
  if mode == 'n' then
    -- In normal mode, cursor is on a character (or at position 0 on empty line)
    if line_len == 0 then
      -- Empty line: insert at the beginning
      insert_col = 0
    else
      -- Non-empty line: insert after current character, but ensure it's within bounds
      insert_col = math.min(col + 1, line_len)
    end
  else
    -- In insert mode, cursor is between characters, insert at current position
    insert_col = math.min(col, line_len)
  end
  return insert_col
end

---Insert a string at the current cursor position
---@param text string the text to insert
local function insert_at_current_cursor(text)
  local buf = vim.api.nvim_get_current_buf()
  table.unpack = table.unpack or unpack -- 5.1 compatibility
  local row, col = table.unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- Adjust because Lua is 1-indexed but Neovim API expects 0-indexed

  -- Get the current line to check its length
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
  local line_len = #line

  -- Calculate where to insert the text
  local mode = vim.fn.mode()
  local insert_col = calculate_insert_col(col, line_len, mode)

  -- Split text by newlines for nvim_buf_set_text
  local lines = vim.split(text, '\n', { plain = true })
  vim.api.nvim_buf_set_text(buf, row, insert_col, row, insert_col, lines)
  if mode == 'i' then
    vim.cmd('startinsert')
  end
  -- Position cursor at the end of the inserted text
  local end_row = row + #lines - 1
  local end_col = insert_col + #lines[#lines]
  vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
end


local M = {}
M.at_current_cursor = insert_at_current_cursor
return M
