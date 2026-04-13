local M = {}

local state_by_picker = setmetatable({}, { __mode = "k" })

---@class dotfiles.snacks_gh_diff_tree.State
---@field cache_key string|nil
---@field diff_items table[]|nil
---@field open_paths table<string, boolean>
local State = {}
State.__index = State

---@return dotfiles.snacks_gh_diff_tree.State
function State.new()
  return setmetatable({
    cache_key = nil,
    diff_items = nil,
    open_paths = {},
  }, State)
end

---@param item table
---@return table
local function shallow_copy(item)
  local copy = {}
  for key, value in pairs(item) do
    copy[key] = value
  end
  return copy
end

---@param path string
---@return string[]
local function split_path(path)
  local segments = {}
  for segment in path:gmatch("[^/]+") do
    table.insert(segments, segment)
  end
  return segments
end

---@param open_paths table<string, boolean>
---@param path string
---@return boolean
local function is_open(open_paths, path)
  local open = open_paths[path]
  if open == nil then
    return true
  end

  return open
end

---@param diff_items table[]
---@return table
local function build_raw_tree(diff_items)
  local root = {
    kind = "dir",
    path = "",
    name = "",
    cwd = diff_items[1] and diff_items[1].cwd or nil,
    children = {},
    directories = {},
  }

  for _, diff_item in ipairs(diff_items) do
    local file_path = diff_item.file
    if file_path and file_path ~= "" then
      local parent_node = root
      local segments = split_path(file_path)

      for index = 1, #segments - 1 do
        local directory_path = table.concat(segments, "/", 1, index)
        local directory_node = parent_node.directories[directory_path]
        if not directory_node then
          directory_node = {
            kind = "dir",
            path = directory_path,
            name = segments[index],
            cwd = diff_item.cwd,
            children = {},
            directories = {},
          }
          parent_node.directories[directory_path] = directory_node
          table.insert(parent_node.children, directory_node)
        end
        parent_node = directory_node
      end

      table.insert(parent_node.children, {
        kind = "file",
        path = file_path,
        name = segments[#segments],
        item = shallow_copy(diff_item),
      })
    end
  end

  return root
end

---@param node table
---@return table|nil
local function get_single_directory_child(node)
  local directory_child = nil

  for _, child in ipairs(node.children) do
    if child.kind == "file" then
      return nil
    end
    if directory_child then
      return nil
    end
    directory_child = child
  end

  return directory_child
end

---@param left table
---@param right table
local function compare_nodes(left, right)
  if left.kind ~= right.kind then
    return left.kind == "dir"
  end

  local left_name = (left.display_name or left.name or left.path):lower()
  local right_name = (right.display_name or right.name or right.path):lower()
  return left_name < right_name
end

---@param nodes table[]
local function sort_nodes(nodes)
  table.sort(nodes, compare_nodes)
end

---@param node table
---@param open_paths table<string, boolean>
---@return table
local function compact_directory(node, open_paths)
  local current = node
  local names = { node.name }
  local next_child = get_single_directory_child(current)

  while next_child do
    table.insert(names, next_child.name)
    current = next_child
    next_child = get_single_directory_child(current)
  end

  local children = {}
  for _, child in ipairs(current.children) do
    if child.kind == "dir" then
      table.insert(children, compact_directory(child, open_paths))
    else
      table.insert(children, child)
    end
  end
  sort_nodes(children)

  return {
    kind = "dir",
    path = current.path,
    name = current.name,
    cwd = current.cwd,
    open = is_open(open_paths, current.path),
    display_name = table.concat(names, "/"),
    children = children,
  }
end

---@param diff_items table[]
---@param open_paths table<string, boolean>|nil
---@return table[]
function M.to_tree_items(diff_items, open_paths)
  open_paths = open_paths or {}

  local root = build_raw_tree(diff_items)
  local nodes = {}
  for _, child in ipairs(root.children) do
    if child.kind == "dir" then
      table.insert(nodes, compact_directory(child, open_paths))
    else
      table.insert(nodes, child)
    end
  end
  sort_nodes(nodes)

  local flattened_items = {}

  ---@param node table
  ---@param parent_item table|nil
  local function flatten(node, parent_item)
    local item
    if node.kind == "dir" then
      item = {
        cwd = node.cwd,
        dir = true,
        display_name = node.display_name,
        file = node.path,
        open = node.open,
        text = node.display_name,
      }
    else
      item = shallow_copy(node.item)
    end

    item.parent = parent_item
    table.insert(flattened_items, item)

    if node.kind == "dir" and node.open then
      for _, child in ipairs(node.children) do
        flatten(child, item)
      end
    end
  end

  ---@param siblings table[]
  ---@param parent_item table|nil
  local function flatten_siblings(siblings, parent_item)
    for _, node in ipairs(siblings) do
      flatten(node, parent_item)
    end
  end

  flatten_siblings(nodes, nil)

  local function mark_last(items, parent_item)
    local siblings = {}
    for _, item in ipairs(items) do
      if item.parent == parent_item then
        table.insert(siblings, item)
      end
    end
    for index, item in ipairs(siblings) do
      item.last = index == #siblings
      if item.dir and item.open then
        mark_last(items, item)
      end
    end
  end

  mark_last(flattened_items, nil)
  return flattened_items
end

---@param picker snacks.Picker
---@return dotfiles.snacks_gh_diff_tree.State
local function get_state(picker)
  if not state_by_picker[picker] then
    state_by_picker[picker] = State.new()
  end

  return state_by_picker[picker]
end

---@param picker snacks.Picker
---@param path string
local function reveal(picker, path)
  for item, index in picker:iter() do
    if item.file == path then
      picker.list:view(index)
      return true
    end
  end

  return false
end

---@param picker snacks.Picker
---@param target string|nil
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

---@param picker snacks.Picker
---@param item snacks.picker.finder.Item|nil
---@param open boolean|nil
---@return boolean
local function update_directory_state(picker, item, open)
  if not item or not item.dir then
    return false
  end

  local state = get_state(picker)
  local next_open = open
  if next_open == nil then
    next_open = not is_open(state.open_paths, item.file)
  end
  state.open_paths[item.file] = next_open
  refresh(picker, item.file)
  return true
end

---@param opts snacks.picker.gh.diff.Config
---@param ctx snacks.picker.finder.ctx
---@return table[]
function State:get_diff_items(opts, ctx)
  local cache_key = table.concat({ tostring(opts.repo or ""), tostring(opts.pr or "") }, ":")
  if self.cache_key == cache_key and self.diff_items then
    return self.diff_items
  end

  local diff_items = {}
  require("snacks.picker.source.gh").diff(opts, ctx)(function(item)
    table.insert(diff_items, item)
  end)

  self.cache_key = cache_key
  self.diff_items = diff_items
  return diff_items
end

---Wrap the built-in GH diff finder with a synthetic compact file tree.
---@param opts snacks.picker.gh.diff.Config
---@param ctx snacks.picker.finder.ctx
---@return snacks.picker.finder
function M.finder(opts, ctx)
  ctx.picker.matcher.opts.keep_parents = true
  local state = get_state(ctx.picker)

  return function(cb)
    local diff_items = state:get_diff_items(opts, ctx)
    for _, item in ipairs(M.to_tree_items(diff_items, state.open_paths)) do
      cb(item)
    end
  end
end

---@param item snacks.picker.finder.Item
---@param picker snacks.Picker
---@return snacks.picker.Highlight[]
function M.format(item, picker)
  if not item.dir then
    return Snacks.picker.format.file(item, picker)
  end

  local ret = {} ---@type snacks.picker.Highlight[]
  if item.parent then
    vim.list_extend(ret, Snacks.picker.format.tree(item, picker))
  end

  if picker.opts.icons.files.enabled ~= false then
    local icon = item.open and picker.opts.icons.files.dir_open or picker.opts.icons.files.dir
    ret[#ret + 1] = {
      Snacks.picker.util.align(icon, picker.opts.formatters.file.icon_width or 2),
      "SnacksPickerDirectory",
      virtual = true,
    }
  end

  ret[#ret + 1] = { item.display_name or item.text or item.file, "SnacksPickerDirectory", field = "file" }
  ret[#ret + 1] = { " " }
  return ret
end

---Preview PR diff items while keeping directory rows empty.
---@param ctx snacks.picker.preview.ctx
function M.preview(ctx)
  if ctx.item.dir then
    ctx.item.preview = { text = "", ft = "diff", loc = false }
    return require("snacks.picker.preview").preview(ctx)
  end

  return require("snacks.picker.source.gh").preview_diff(ctx)
end

---Toggle a directory row in the GH diff tree.
---@param picker snacks.Picker
---@param item snacks.picker.finder.Item|nil
function M.toggle(picker, item)
  update_directory_state(picker, item, nil)
end

---Open a directory row in the GH diff tree, or jump for files.
---@param picker snacks.Picker
---@param item snacks.picker.finder.Item|nil
---@param action snacks.picker.jump.Action|nil
function M.open(picker, item, action)
  if update_directory_state(picker, item, true) then
    return
  end

  return require("snacks.picker.actions").jump(picker, item, action or {})
end

---Close a directory row in the GH diff tree.
---@param picker snacks.Picker
---@param item snacks.picker.finder.Item|nil
function M.close(picker, item)
  if update_directory_state(picker, item, false) then
    return
  end

  if item and item.parent then
    update_directory_state(picker, item.parent, false)
  end
end

---Confirm a GH diff tree item.
---@param picker snacks.Picker
---@param item snacks.picker.finder.Item|nil
---@param action snacks.picker.jump.Action|nil
function M.confirm(picker, item, action)
  if update_directory_state(picker, item, nil) then
    return
  end

  return require("snacks.picker.actions").jump(picker, item, action or {})
end

return M
