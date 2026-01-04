---Insert codeblock at the current cursor position.
local function insert_codeblock()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line = cursor_pos[1]

  local codeblock = {
    "```",
    "```",
  }

  vim.api.nvim_buf_set_lines(bufnr, line - 1, line, false, codeblock)
  vim.api.nvim_win_set_cursor(0, { line, 3 })
end

---Convert the current line into a task or toggle task status.
local function convert_or_toggle_task()
  -- Get the current line/row/column
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row, _ = cursor_pos[1], cursor_pos[2]
  local line = vim.api.nvim_get_current_line()

  -- 1) If line is empty => replace it with "- [ ] " and set cursor after the brackets
  if line:match("^%s*$") then
    local final_line = "- [ ] "
    vim.api.nvim_set_current_line(final_line)
    -- "- [ ] " is 6 characters, so cursor col = 6 places you *after* that space
    vim.api.nvim_win_set_cursor(0, { row, 6 })
    return
  end

  -- 2) If there's already "- [ ] ", then convert to "- [x] "
  if line:match("^%s*[-*]%s+%[ %]%s+") then
    local final_line = line:gsub("%[ %]", "[x]", 1)
    vim.api.nvim_set_current_line(final_line)
    return
  end

  -- 3) If there's already "- [x] " (or anything inside the checkbox), then convert to "- [ ] "
  if line:match("^%s*[-*]%s+%[.-%]%s+") then
    local final_line = line:gsub("%[.-%]", "[ ]", 1)
    vim.api.nvim_set_current_line(final_line)
    return
  end

  -- 4) Check if line already has a bullet with possible indentation: e.g. "  - Something"
  --    We'll capture "  -" (including trailing spaces) as `bullet` plus the rest as `text`.
  local bullet, text = line:match("^([%s]*[-*]%s+)(.*)$")
  if bullet then
    -- Convert bullet => bullet .. "[ ] " .. text
    local final_line = bullet .. "[ ] " .. text
    vim.api.nvim_set_current_line(final_line)
    -- Place the cursor right after "[ ] "
    -- bullet length + "[ ] " is bullet_len + 4 characters,
    -- but bullet has trailing spaces, so #bullet includes those.
    local bullet_len = #bullet
    -- We want to land after the brackets (four characters: `[ ] `),
    -- so col = bullet_len + 4 (0-based).
    vim.api.nvim_win_set_cursor(0, { row, bullet_len + 4 })
    return
  end

  -- 5) If there's text, but no bullet => prepend "- [ ] " and place cursor after the brackets
  local final_line = "- [ ] " .. line
  vim.api.nvim_set_current_line(final_line)
  -- "- [ ] " is 6 characters
  vim.api.nvim_win_set_cursor(0, { row, 6 })
end

---Add indent if first non-blank character is a dash
local function smart_indent()
  local line = vim.api.nvim_get_current_line()
  local first_non_blank = line:match("^%s*(.)")

  if first_non_blank == "-" then
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor_pos[1], cursor_pos[2]
    vim.cmd("normal! >>")
    -- Move cursor to maintain relative position after indentation
    vim.api.nvim_win_set_cursor(0, { row, col + vim.bo.shiftwidth })
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
  end
end

---De-indent if first non-blank character is a dash
local function smart_dedent()
  local line = vim.api.nvim_get_current_line()
  local first_non_blank = line:match("^%s*(.)")

  if first_non_blank == "-" then
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor_pos[1], cursor_pos[2]
    vim.cmd("normal! <<")
    -- Move cursor to maintain relative position after de-indentation
    local new_col = math.max(0, col - vim.bo.shiftwidth)
    vim.api.nvim_win_set_cursor(0, { row, new_col })
  end
end

---Make the selected text bold by wrapping it with **.
---Requires mini-surround to work.
local function bold_selected_text()
  vim.cmd("normal 2gsa*")
end

---Single word/line bold
---In normal mode, bold the current word under the cursor
---If already bold, it will unbold the word under the cursor
---Requires mini-surround to work.
local function bold_word_under_cursor()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local col = cursor_pos[2]
  local line = vim.api.nvim_get_current_line()
  -- Check if the cursor is on an asterisk
  if line:sub(col + 1, col + 1):match("%*") then
    vim.notify("Cursor is on an asterisk, run inside the bold text", vim.log.levels.WARN)
    return
  end
  -- Check if the cursor is inside surrounded text
  local before = line:sub(1, col)
  local after = line:sub(col + 1)
  local inside_surround = before:match("%*%*[^%*]*$") and after:match("^[^%*]*%*%*")
  if inside_surround then
    vim.cmd("normal gsd*.")
  else
    vim.cmd("normal viw")
    vim.cmd("normal 2gsa*")
  end
end

local M = {}
M.insert_codeblock = insert_codeblock
M.convert_or_toggle_task = convert_or_toggle_task
M.smart_indent = smart_indent
M.smart_dedent = smart_dedent
M.bold_selected_text = bold_selected_text
M.bold_word_under_cursor = bold_word_under_cursor
return M
