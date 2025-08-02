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

  -- 3) If there's already "- [x] ", then convert to "- [ ] "
  if line:match("^%s*[-*]%s+%[x%]%s+") then
    local final_line = line:gsub("%[x%]", "[ ]", 1)
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

---Paste URL as markdown link
local function paste_url()
  local input = vim.fn.getreg('+')
  local title = input
  local link = require("plugins.custom.lang.markdown.link")
  if link.is_url(input) then
    title = link.create_markdown_link(input)
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { title })
end


local M = {}
M.add_codeblock_keymap = add_codeblock_keymap
M.convert_or_toggle_task = convert_or_toggle_task
M.paste_url = paste_url
return M
