local data = require("plugins.first.snacks.gh_pr_story.data")
local util = require("plugins.first.snacks.gh_pr_story.util")

local state_by_picker = setmetatable({}, { __mode = "k" })

local function info_level()
  return vim.log and vim.log.levels and vim.log.levels.INFO or nil
end

local function cache_key(opts)
  return table.concat({ tostring(opts.repo or ""), tostring(opts.pr or "") }, ":")
end

local function get_state(picker)
  local state = state_by_picker[picker]
  if state then
    return state
  end

  state = {
    cache_key = nil,
    review_data = nil,
    open_chapters = {},
  }
  state_by_picker[picker] = state
  return state
end

local function get_review_data(state, opts, ctx)
  local key = cache_key(opts)
  if state.cache_key ~= key or not state.review_data then
    state.cache_key = key
    state.review_data = data.get_review_data(opts, ctx)
  end

  return state.review_data
end

local function build_chapter_preview(item)
  local lines = {}
  if item.story_summary and item.story_summary ~= "" then
    table.insert(lines, "# Pull Request Story")
    table.insert(lines, "")
    table.insert(lines, item.story_summary)
    table.insert(lines, "")
  end

  table.insert(lines, ("## Chapter %d — %s"):format(item.chapter_index, item.chapter.title))
  table.insert(lines, "")
  if item.chapter.narrative ~= "" then
    table.insert(lines, item.chapter.narrative)
    table.insert(lines, "")
  end

  table.insert(lines, "### Files")
  for _, file in ipairs(item.chapter.files or {}) do
    table.insert(lines, "- " .. file)
  end

  return table.concat(lines, "\n")
end

local function is_open(state, chapter_id)
  local open = state.open_chapters[chapter_id]
  if open == nil then
    return true
  end

  return open
end

local function reveal(picker, path)
  for item, index in picker:iter() do
    if item.file == path then
      picker.list:view(index)
      return true
    end
  end

  return false
end

local function refresh(picker, target)
  picker.list:set_target()
  picker:find({
    refresh = true,
    on_done = function()
      if target then
        reveal(picker, target)
      end
    end,
  })
end

local function set_chapter_open(picker, item, open, target)
  if not item or not item.dir then
    return false
  end

  local state = get_state(picker)
  if open == nil then
    open = not is_open(state, item.chapter_id)
  end
  state.open_chapters[item.chapter_id] = open
  refresh(picker, target or item.file)
  return true
end

local function chapter_item(story, chapter, chapter_index, open)
  return {
    chapter = chapter,
    chapter_id = chapter.id,
    chapter_index = chapter_index,
    dir = true,
    display_name = chapter.title,
    file = "chapter://" .. chapter.id,
    file_count = #chapter.files,
    first_child_path = chapter.files[1],
    last = chapter_index == #(story.chapters or {}),
    open = open,
    story_summary = story.summary,
    text = table.concat({ chapter.title, chapter.narrative }, "\n"),
  }
end

local M = {}

function M.to_tree_items(diff_items, story, open_chapters)
  open_chapters = open_chapters or {}

  local diff_by_file = {}
  for _, diff_item in ipairs(diff_items) do
    if diff_item.file and not diff_by_file[diff_item.file] then
      diff_by_file[diff_item.file] = diff_item
    end
  end

  local items = {}
  for chapter_index, chapter in ipairs(story.chapters or {}) do
    local open = open_chapters[chapter.id]
    if open == nil then
      open = true
    end

    local parent = chapter_item(story, chapter, chapter_index, open)
    table.insert(items, parent)

    if open then
      for file_index, file in ipairs(chapter.files) do
        local diff_item = diff_by_file[file]
        if diff_item then
          local file_item = util.shallow_copy(diff_item)
          file_item.parent = parent
          file_item.last = file_index == #chapter.files
          table.insert(items, file_item)
        end
      end
    end
  end

  return items
end

function M.finder(opts, ctx)
  ctx.picker.matcher.opts.keep_parents = true
  local state = get_state(ctx.picker)

  return function(cb)
    local review_data = get_review_data(state, opts, ctx)
    for _, item in ipairs(M.to_tree_items(review_data.diff_items, review_data.story, state.open_chapters)) do
      cb(item)
    end
  end
end

function M.format(item, picker)
  if not item.dir then
    return Snacks.picker.format.file(item, picker)
  end

  local align = Snacks.picker.util.align
  local icon_width = picker.opts.formatters.file.icon_width or 2

  return {
    {
      align(item.open and "󰐕" or "󰐖", icon_width),
      "SnacksPickerDirectory",
      virtual = true,
    },
    {
      ("Chapter %d — %s"):format(item.chapter_index, item.display_name or item.text or item.file),
      "SnacksPickerDirectory",
      field = "file",
    },
    { " " },
    {
      ("(%d files)"):format(item.file_count or 0),
      "SnacksPickerComment",
    },
    { " " },
  }
end

function M.preview(ctx)
  if not ctx.item.dir then
    return require("snacks.picker.source.gh").preview_diff(ctx)
  end

  vim.b[ctx.buf].snacks_gh = nil
  ctx.item.preview = {
    ft = "markdown",
    loc = false,
    text = build_chapter_preview(ctx.item),
  }
  return require("snacks.picker.preview").preview(ctx)
end

function M.toggle(picker, item)
  set_chapter_open(picker, item, nil)
end

function M.open(picker, item, action)
  if item and item.dir then
    set_chapter_open(picker, item, true, item.first_child_path or item.file)
    return
  end

  picker:focus("preview", { show = true })
end

function M.close(picker, item)
  if item and item.dir then
    set_chapter_open(picker, item, false, item.file)
    return
  end

  if item and item.parent then
    set_chapter_open(picker, item.parent, false, item.parent.file)
  end
end

function M.confirm(picker, item, action)
  if set_chapter_open(picker, item, nil) then
    return
  end

  return require("snacks.picker.actions").jump(picker, item, action or {})
end

local function delegate_gh_action(action_name, picker, item, action)
  if not item or item.dir then
    util.schedule_notify("Select a file inside a chapter first", info_level())
    return
  end

  local gh_action = require("snacks.picker.source.gh").actions[action_name]
  if gh_action and gh_action.action then
    return gh_action.action(picker, item, action)
  end
end

function M.gh_comment(picker, item, action)
  return delegate_gh_action("gh_comment", picker, item, action)
end

function M.gh_actions(picker, item, action)
  return delegate_gh_action("gh_actions", picker, item, action)
end

return M
