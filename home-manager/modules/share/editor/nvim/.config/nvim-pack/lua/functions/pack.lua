local M = {}

---@param plugin vim.pack.Spec|string
---@return string|vim.pack.Spec
local function plugin_key(plugin)
  if type(plugin) == "table" then
    return plugin.src or plugin
  end

  return plugin
end

---@param result (vim.pack.Spec|string)[]
---@param seen table<string|vim.pack.Spec, boolean>
---@param plugin vim.pack.Spec|string
local function append_unique(result, seen, plugin)
  local key = plugin_key(plugin)
  if seen[key] then
    return
  end

  seen[key] = true
  table.insert(result, plugin)
end

---@param plugin_entry any
---@param result (vim.pack.Spec|string)[]
---@param seen table<string|vim.pack.Spec, boolean>
local function collect_pack_specs(plugin_entry, result, seen)
  if plugin_entry == nil then
    return
  end

  if type(plugin_entry) ~= "table" then
    append_unique(result, seen, plugin_entry)
    return
  end

  if plugin_entry.spec ~= nil then
    collect_pack_specs(plugin_entry.spec, result, seen)
    return
  end

  if plugin_entry.src ~= nil then
    append_unique(result, seen, plugin_entry)
    return
  end

  for _, nested_plugin_entry in ipairs(plugin_entry) do
    collect_pack_specs(nested_plugin_entry, result, seen)
  end
end

---Convert nested plugin groups into a single pack spec array.
---@param plugin_groups any[]
---@return (vim.pack.Spec|string)[]
local function to_pack_specs(plugin_groups)
  local result = {}
  local seen = {}

  collect_pack_specs(plugin_groups, result, seen)

  return result
end

M.to_pack_specs = to_pack_specs

return M
