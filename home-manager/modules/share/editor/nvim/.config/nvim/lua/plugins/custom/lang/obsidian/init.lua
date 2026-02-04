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
local function next_week(ctx)
  return os.date("%Y-%m-%d", id_to_date(ctx.partial_note) + 86400 * 7)
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
    search = "^\\s*- \\[ \\] ",
    glob = "**/*.md",
    exclude = {
      "node_modules",
      ".git",
      "0-meta",
      "3-resources/technical-notes",
      "5-rituals",
      "6-triage",
    },
  })
end

---Open the current month's ritual note.
local function open_current_monthly_note()
  local year = os.date("%Y")
  local month = os.date("%Y-%m")
  local monthly_note_path = string.format("5-rituals/monthly/%s/%s.md", year, month)
  vim.cmd("edit " .. vim.fn.expand(vim.g.notes_dir) .. "/" .. monthly_note_path)
end

local function sanitize_yanked_text()
  vim.cmd('normal! "+y')
  local yanked_text = vim.fn.getreg("+")
  -- Convert wiki links [[target|display]] and [[text]] to plain text
  yanked_text = yanked_text:gsub("%[%[([^%]|]+)|([^%]]+)%]%]", "%2")
  yanked_text = yanked_text:gsub("%[%[([^%]]+)%]%]", "%1")
  return yanked_text
end

---Sanitize selected text without the wiki links and yank to + register.
local function sanitize_and_yank()
  vim.fn.setreg("+", sanitize_yanked_text())
end

---Convert Markdown text to HTML.
---@param text string markdown text
---@return string html
local function markdown_to_html(text)
  -- Convert markdown links [text](url) BEFORE escaping HTML entities
  text = text:gsub("%[([^%]]+)%]%(([^%)]+)%)", '<a href="%2">%1</a>')

  -- Escape HTML entities (but not in the <a> tags we just created)
  -- This is a simplification - proper solution would use a placeholder
  text = text:gsub("&", "&amp;")

  -- Convert code blocks first (before inline code), removing language identifier
  text = text:gsub("```%w*\n?(.-)```", "<pre>%1</pre>")

  -- Remove multiple consecutive newlines
  text = text:gsub("\n\n+", "\n")

  -- Convert inline code
  text = text:gsub("`([^`]+)`", "<code>%1</code>")

  -- Convert bold: **text** or __text__
  text = text:gsub("%*%*(.-)%*%*", "<b>%1</b>")
  text = text:gsub("__(.-)__", "<b>%1</b>")

  -- Convert bullet points - flatten nested lists with visual indentation (4 spaces per level)
  local lines = {}
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local indent, content = line:match("^(%s*)%- (.+)$")
    if content then
      -- Calculate indent level (2 or 4 spaces = 1 level typically)
      local level = math.floor(#indent / 2)
      -- Use non-breaking spaces for indentation + bullet
      local visual_indent = string.rep("\u{00A0}", 4 * level)
      table.insert(lines, visual_indent .. "• " .. content)
    else
      table.insert(lines, line)
    end
  end

  return table.concat(lines, "<br>")
end

---Yank HTML to clipboard for rich text paste.
---Supports macOS (AppKit) and Linux (xclip).
---@param html string
---@param plain string
local function yank_html_to_clipboard(html, plain)
  local uname = vim.loop.os_uname().sysname

  if uname == "Darwin" then
    -- macOS: use AppleScript with AppKit
    local escaped_html = html:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n")
    local escaped_plain = plain:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n")

    local script = string.format(
      [[
      use framework "AppKit"
      set pb to current application's NSPasteboard's generalPasteboard()
      pb's clearContents()
      pb's setString:"%s" forType:(current application's NSPasteboardTypeHTML)
      pb's setString:"%s" forType:(current application's NSPasteboardTypeString)
    ]],
      escaped_html,
      escaped_plain
    )
    vim.fn.system({ "osascript", "-e", script })
  elseif uname == "Linux" then
    -- Linux: use xclip (must be installed)
    local html_cmd = vim.fn.jobstart({ "xclip", "-selection", "clipboard", "-t", "text/html" }, { stdin = "pipe" })
    vim.fn.chansend(html_cmd, html)
    vim.fn.chanclose(html_cmd, "stdin")
  else
    vim.notify("Unsupported OS for HTML clipboard: " .. uname, vim.log.levels.WARN)
    vim.fn.setreg("+", plain)
  end
end

---Convert Markdown to HTML and copy to clipboard.
local function to_html_and_yank()
  local sanitized_text = sanitize_yanked_text()
  yank_html_to_clipboard(markdown_to_html(sanitized_text), sanitized_text)
end

---@param ctx obsidian.TemplateContext
local function time_tracker(ctx)
  local today_iso = id_to_date(ctx.partial_note)
  if os.date("%u", today_iso) ~= "6" and os.date("%u", today_iso) ~= "7" then
    return [[

---
## 🕐 Time tracker

- administration: 
- maintenance: ]]
  end
  return ""
end

---Get unfinished tasks from a specific section in yesterday's journal.
---@param ctx obsidian.TemplateContext
---@param section_header string the section header to look for (e.g., "🎯 Today's objectives")
---@return string tasks formatted as markdown list items, or empty string if none
local function get_unfinished_tasks_from_section(ctx, section_header)
  local yesterday_date = os.date("%Y-%m-%d", id_to_date(ctx.partial_note) - 86400)
  local notes_dir = vim.fn.expand(vim.g.notes_dir)
  local yesterday_path = string.format("%s/5-rituals/daily/%s.md", notes_dir, yesterday_date)

  -- Read file, return empty if doesn't exist
  local file = io.open(yesterday_path, "r")
  if not file then
    return ""
  end
  local content = file:read("*a")
  file:close()

  -- Find the section
  local section_pattern = "## " .. section_header:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
  local section_start = content:find(section_pattern)
  if not section_start then
    return ""
  end

  -- Extract content from section start to next section or horizontal rule
  local section_content = content:sub(section_start)
  local section_end = section_content:find("\n## ") or section_content:find("\n%-%-%-")
  if section_end then
    section_content = section_content:sub(1, section_end - 1)
  end

  -- Extract unfinished tasks (- [ ] or - [>])
  local tasks = {}
  for line in section_content:gmatch("[^\n]+") do
    if line:match("^%s*%- %[ %]") or line:match("^%s*%- %[>%]") then
      -- Normalize [>] to [ ]
      local normalized = line:gsub("%[>%]", "[ ]")
      table.insert(tasks, normalized)
    end
  end

  return table.concat(tasks, "\n")
end

---@param ctx obsidian.TemplateContext
local function unfinished_yesterday_objective_tasks(ctx)
  return get_unfinished_tasks_from_section(ctx, "🎯 Today's objectives")
end

---@param ctx obsidian.TemplateContext
local function unfinished_yesterday_other_tasks(ctx)
  return get_unfinished_tasks_from_section(ctx, "🚧 Others")
end

local M = {}
M.today = today
M.yesterday = yesterday
M.tomorrow = tomorrow
M.next_week = next_week
M.current_month = current_month
M.previous_month = previous_month
M.next_month = next_month
M.todo = todo
M.search_pending_todos = search_pending_todos
M.open_current_monthly_note = open_current_monthly_note
M.sanitize_and_yank = sanitize_and_yank
M.to_html_and_yank = to_html_and_yank
M.time_tracker = time_tracker
M.unfinished_yesterday_objective_tasks = unfinished_yesterday_objective_tasks
M.unfinished_yesterday_other_tasks = unfinished_yesterday_other_tasks
return M
