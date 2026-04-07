---@return string
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
  for index, line in ipairs(lines) do
    if line:match("^## 🎯 Today's objectives") then
      header_line = index
    elseif header_line and line:match("^## ") then
      next_header = index
      break
    end
  end

  local section_end = next_header and (next_header - 1) or #lines

  local last_nonblank
  for index = section_end, header_line + 1, -1 do
    if lines[index]:match("%S") then
      last_nonblank = index
      break
    end
  end
  if not last_nonblank then
    last_nonblank = header_line
  end

  local insert_index = last_nonblank + 1
  table.insert(lines, insert_index, task)

  local next_header_index
  for index = insert_index + 1, #lines do
    if lines[index]:match("^## ") then
      next_header_index = index
      break
    end
  end
  if next_header_index and next_header_index == insert_index + 1 then
    table.insert(lines, insert_index + 1, "")
  end

  vim.fn.writefile(lines, path)
end

local function setup()
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

  vim.keymap.set("n", "<leader>ji", "<cmd>JiraIssues<cr>", { desc = "Jira current issues" })
  vim.keymap.set("n", "<leader>je", "<cmd>JiraEpic<cr>", { desc = "Jira epics" })
  vim.keymap.set("n", "<leader>j1", "<cmd>JiraEpic P3C-5883<cr>", { desc = "Jira P3C-5883" })
  vim.keymap.set("n", "<leader>j2", "<cmd>JiraEpic P3C-5861<cr>", { desc = "Jira P3C-5861" })
  vim.keymap.set("n", "<leader>j3", "<cmd>JiraEpic P3C-5885<cr>", { desc = "Jira P3C-5885" })

  local has_wk, wk = pcall(require, "which-key")
  if has_wk then
    wk.add({ "<leader>j", group = "jira" })
  end
end

---@type vim.pack.Spec
return
-- Neovim plugin for browsing and managing JIRA issues with a fuzzy-finding interface.
{
  src = "https://codeberg.org/l-lin/jira.nvim",
  data = {
    setup = function()
      vim.schedule(setup)
    end,
  },
}
