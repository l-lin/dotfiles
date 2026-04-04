---@return string daily_note_filepath containing today daily note filepath
local function daily_note_filepath()
  return vim.g.notes_dir .. "/5-rituals/daily/" .. tostring(os.date("%Y-%m-%d")) .. ".md"
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

  local key_pattern = vim.pesc(key)
  for _, line in ipairs(lines) do
    if line:match("^%- %[[ xX]?%] %s*" .. key_pattern) then
      vim.notify("Task " .. key .. " already registered", vim.log.levels.INFO)
      return
    end
  end

  local header_line, next_header
  for i, line in ipairs(lines) do
    if line:match("^## 🎯 Today's objectives") then
      header_line = i
    elseif header_line and line:match("^## ") then
      next_header = i
      break
    end
  end

  local section_end = next_header and (next_header - 1) or #lines

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

  local insert_idx = last_nonblank + 1
  table.insert(lines, insert_idx, task)

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

-- ----------------------------------------------------------------------------

-- Neovim plugin for browsing and managing JIRA issues with a fuzzy-finding interface
vim.pack.add({ "https://codeberg.org/l-lin/jira.nvim" })

--
-- Setup
--
require("jira").setup({
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
})

--
-- Keymaps
--
local map = vim.keymap.set
map("n", "<leader>ji", "<cmd>JiraIssues<cr>", { desc = "Jira current issues" })
map("n", "<leader>je", "<cmd>JiraEpic<cr>", { desc = "Jira epics" })
map("n", "<leader>j1", "<cmd>JiraEpic P3C-5883<cr>", { desc = "Jira P3C-5883" })
map("n", "<leader>j2", "<cmd>JiraEpic P3C-5861<cr>", { desc = "Jira P3C-5861" })
map("n", "<leader>j3", "<cmd>JiraEpic P3C-5885<cr>", { desc = "Jira P3C-5885" })
