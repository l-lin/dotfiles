---@module "obsidian.nvim"

---Convert a title to a date.
---Return current date if the title is not in the expected format.
---@param note obsidian.Note the note to convert
---@return integer current_date date in seconds since epoch
local function id_to_date(note)
  local year, month, day = note.id:match("^(%d+)-(%d+)-(%d+)$")
  if not year or not month or not day then
    return os.time()
  end
  return os.time({ year = year, month = month, day = day })
end

---@param ctx obsidian.TemplateContext
local function today(ctx)
  return os.date("%Y-%m-%d", id_to_date(ctx.partial_note))
end

---@param ctx obsidian.TemplateContext
local function yesterday(ctx)
  return os.date("%Y-%m-%d", id_to_date(ctx.partial_note) - 86400)
end

---@param ctx obsidian.TemplateContext
local function tomorrow(ctx)
  return os.date("%Y-%m-%d", id_to_date(ctx.partial_note) + 86400)
end

---@param ctx obsidian.TemplateContext
local function current_month(ctx)
  return os.date("%Y-%m", id_to_date(ctx.partial_note))
end

---@param ctx obsidian.TemplateContext
local function previous_month(ctx)
  local date = id_to_date(ctx.partial_note)
  local year = tonumber(os.date("%Y", date))
  local month = tonumber(os.date("%m", date))
  month = month - 1
  if month < 1 then
    month = 12
    year = year - 1
  end
  local prev_month_date = os.time({ year = year, month = month, day = 1 })
  return os.date("%Y-%m", prev_month_date)
end

---@param ctx obsidian.TemplateContext
local function next_month(ctx)
  local date = id_to_date(ctx.partial_note)
  local year = tonumber(os.date("%Y", date))
  local month = tonumber(os.date("%m", date))
  month = month + 1
  if month > 12 then
    month = 1
    year = year + 1
  end
  local next_month_date = os.time({ year = year, month = month, day = 1 })
  return os.date("%Y-%m", next_month_date)
end

---@param ctx obsidian.TemplateContext
local function todo(ctx)
  local today_iso = id_to_date(ctx.partial_note)
  local t = {}
  if os.date("%u", today_iso) ~= "6" and os.date("%u", today_iso) ~= "7" then
    table.insert(t, "- [ ] deploy in production")
  end
  if os.date("%u", today_iso) == "3" then
    table.insert(t, "- [ ] [[1o1 - " .. os.date("%Y-%m", today_iso) .. "]]")
  end
  if os.date("%u", today_iso) == "5" then
    table.insert(t, "- [ ] update [[career progress]] with `/project-checkpoint`")
    table.insert(t, "- [ ] [[workday]]: enter your time")
  end
  if os.date("%u", today_iso) == "7" then
    table.insert(t, "- [ ] weekly journal with `/weekly`")
    table.insert(t, "- [ ] update main quests")
  end
  return table.concat(t, "\n")
end

---Search for all pending todos using snacks.picker and ripgrep.
---Finds all lines that match the pattern `- [ ]` (with optional indentation).
local function search_pending_todos()
  require("snacks").picker.grep({
    search = "^\\s*- \\[ \\]",
    glob = "**/*.md",
    exclude = {
      "node_modules",
      ".git",
      "0-meta",
      "4-archives",
      "5-rituals",
      "6-triage",
    },
  })
end

local M = {}
M.today = today
M.yesterday = yesterday
M.tomorrow = tomorrow
M.current_month = current_month
M.previous_month = previous_month
M.next_month = next_month
M.todo = todo
M.search_pending_todos = search_pending_todos
return M
