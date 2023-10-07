---Open parent folder from the file/folder under cursor.
local function focus_parent(state)
  local cc = require("neo-tree.sources.common.commands")
  local renderer = require("neo-tree.ui.renderer")
  local node = state.tree:get_node()

  renderer.focus_node(state, node:get_parent_id())
  cc.close_all_subnodes(state)
end

local function focus_child(state)
  local renderer = require("neo-tree.ui.renderer")
  local async = require("plenary.async")
  local task = function()
    local fs = require("neo-tree.sources.filesystem")
    local cc = require("neo-tree.sources.common.commands")
    local node = state.tree:get_node()

    if node.type ~= "directory" then
      -- open file directly
      cc.open(state, fs.toggle_directory)
      vim.schedule(function()
        vim.cmd([[Neotree focus]])
      end)
      return
    end

    local prefetcher = fs.prefetcher

    -- each node are not loaded by default, so we need to prefetch the items of the node
    state.explicitly_opened_directories = state.explicitly_opened_directories or {}
    if prefetcher.should_prefetch(node) then
      local id = node:get_id()
      state.explicitly_opened_directories[id] = true
      prefetcher.prefetch(state, node)
    elseif not node:is_expanded() then
      -- open folder
      node:expand()
      state.explicitly_opened_directories[node:get_id()] = true
    end

    if node:has_children() then
      -- select automatically the first item of the folder
      renderer.focus_node(state, node:get_child_ids()[1])
    end
  end

  async.run(task, function()
    renderer.redraw(state)
  end)
end

local M = {}

M.focus_parent = focus_parent
M.focus_child = focus_child

return M
