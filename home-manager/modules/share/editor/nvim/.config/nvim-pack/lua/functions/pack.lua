local M = {}

---@param plugin vim.pack.Spec
---@return string|vim.pack.Spec
local function plugin_key(plugin)
  return plugin.src or plugin
end

---@param result vim.pack.Spec[]
---@param seen table<string|vim.pack.Spec, boolean>
---@param plugin vim.pack.Spec
local function append_unique(result, seen, plugin)
  local key = plugin_key(plugin)
  if seen[key] then
    return
  end

  seen[key] = true
  table.insert(result, plugin)
end

---Flatten nested plugin groups into a single plugin spec array.
---@param plugin_array (vim.pack.Spec|vim.pack.Spec[])[] An array of plugin specs or nested plugin groups.
---@param result? vim.pack.Spec[]
---@param seen? table<string|vim.pack.Spec, boolean>
---@return vim.pack.Spec[]
local function to_pack_specs(plugin_array, result, seen)
  local flattened_plugins = result or {}
  local seen_plugins = seen or {}

  for _, plugins in ipairs(plugin_array) do
    if type(plugins) == "table" and plugins.src == nil then
      to_pack_specs(plugins, flattened_plugins, seen_plugins)
    else
      append_unique(flattened_plugins, seen_plugins, plugins)
    end
  end

  return flattened_plugins
end

M.to_pack_specs = to_pack_specs

return M
