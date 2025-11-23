---@return string daily_note_filepath containing today daily note filepath
local function daily_note_filepath()
  return os.getenv("HOME") .. "/perso/notes/5-rituals/daily/" .. tostring(os.date("%Y-%m-%d")) .. ".md"
end

---@type jira.StartWorkDoneCallback?
local function append_task_to_daily_notes(ctx)
  local item = ctx.item or {}
  local key = item.key
  if not key or key == "" then
    return
  end

  local summary = (item.summary or ""):gsub("\n", " "):gsub("%s+$", "")
  local task = string.format("- [ ] %s: %s", key, summary)

  local path = daily_note_filepath()
  if vim.fn.filereadable(path) == 0 then
    vim.notify("filepath " .. path .. " not readable", vim.log.levels.ERROR)
    return
  end

  local lines = vim.fn.readfile(path)

  -- avoid duplicate task (any checkbox line starting with this key)
  local key_pattern = vim.pesc(key)
  for _, line in ipairs(lines) do
    if line:match("^%- %[[ xX]?%] %s*" .. key_pattern) then
      vim.notify("Task " .. key .. " already registered", vim.log.levels.INFO)
      return
    end
  end

  local header_line, next_header
  -- find end of section (before next `## ` or EOF)
  local end_line = #lines
  for i, line in ipairs(lines) do
    if line:match("^## 🎯 Today's objectives") then
      header_line = i
    elseif header_line and line:match("^## ") then
      next_header = i
      break
    end
  end

  local section_end = next_header and (next_header - 1) or #lines

  -- find last non-blank line in the section
  local last_nonblank
  for i = section_end, header_line + 1, -1 do
    if lines[i]:match("%S") then
      last_nonblank = i
      break
    end
  end
  if not last_nonblank then
    last_nonblank = header_line
  end

  -- insert task immediately after last non-blank line
  local insert_idx = last_nonblank + 1
  table.insert(lines, insert_idx, task)

  -- ensure a blank line between the new task and the next section header
  local header_idx
  for i = insert_idx + 1, #lines do
    if lines[i]:match("^## ") then
      header_idx = i
      break
    end
  end
  if header_idx and header_idx == insert_idx + 1 then
    table.insert(lines, insert_idx + 1, "")
  end

  vim.fn.writefile(lines, path)
end

return {
  {
    "l-lin/jira.nvim",
    cmd = { "JiraIssues", "JiraEpic", "JiraStartWorkingOn" },
    keys = {
      { "<leader>ji", "<cmd>JiraIssues<cr>" },
      { "<leader>je", "<cmd>JiraEpic<cr>" },
      { "<leader>j1", "<cmd>JiraEpic P3C-5771<cr>" },
      { "<leader>j2", "<cmd>JiraEpic P3C-6006<cr>" },
      { "<leader>j3", "<cmd>JiraEpic P3C-5857<cr>" },
    },
    opts = {
      cli = {
        issues = {
          prefill_search = "Louis",
        },
      },
      action = {
        start_work = {
          on_done = append_task_to_daily_notes,
        },
      },
    },
  },
}
