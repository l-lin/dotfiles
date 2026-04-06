local M = {}

---@param names string[]
---@return string[]
local function sorted_copy(names)
  local result = {}

  for _, name in ipairs(names) do
    table.insert(result, name)
  end

  table.sort(result)
  return result
end

local active_plugin_icon = ""
local inactive_plugin_icon = ""

---@param plugin { name: string, src?: string, active: boolean }
---@return string
local function format_plugin_line(plugin)
  local icon = plugin.active and active_plugin_icon or inactive_plugin_icon

  if plugin.src ~= nil and plugin.src ~= "" then
    return ("- %s [%s](%s)"):format(icon, plugin.name, plugin.src)
  end

  return ("- %s %s"):format(icon, plugin.name)
end

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

---@param plugin_infos { active?: boolean, spec?: { name?: string, src?: string } }[]
---@return { name: string, src?: string, active: boolean }[]
local function collect_plugins(plugin_infos)
  local plugins_by_name = {}

  for _, plugin_info in ipairs(plugin_infos or {}) do
    local plugin_spec = plugin_info.spec or {}
    local plugin_name = plugin_spec.name

    if plugin_name ~= nil and plugin_name ~= "" then
      local plugin = plugins_by_name[plugin_name] or {
        active = false,
        name = plugin_name,
        src = plugin_spec.src,
      }
      plugin.active = plugin.active or plugin_info.active or false
      plugin.src = plugin.src or plugin_spec.src
      plugins_by_name[plugin_name] = plugin
    end
  end

  local plugins = {}

  for plugin_name in pairs(plugins_by_name) do
    table.insert(plugins, plugins_by_name[plugin_name])
  end

  table.sort(plugins, function(left, right)
    return left.name < right.name
  end)

  return plugins
end

---Group managed plugins by install and activation state.
---@param plugin_infos { active?: boolean, spec?: { name?: string } }[]
---@return { installed: string[], active: string[], inactive: string[] }
function M.group_plugin_names(plugin_infos)
  local installed_names = {}
  local active_names = {}
  local inactive_names = {}

  for _, plugin in ipairs(collect_plugins(plugin_infos)) do
    table.insert(installed_names, plugin.name)

    if plugin.active then
      table.insert(active_names, plugin.name)
    else
      table.insert(inactive_names, plugin.name)
    end
  end

  return {
    installed = sorted_copy(installed_names),
    active = sorted_copy(active_names),
    inactive = sorted_copy(inactive_names),
  }
end

---Format managed plugin state for a scratch buffer listing.
---@param plugin_infos { active?: boolean, spec?: { name?: string, src?: string } }[]
---@param installed_directory string
---@return string[]
function M.plugin_report_lines(plugin_infos, installed_directory)
  local plugins = collect_plugins(plugin_infos)
  local active_count = 0

  for _, plugin in ipairs(plugins) do
    if plugin.active then
      active_count = active_count + 1
    end
  end

  local lines = {
    "# nvim-pack plugins",
    "",
    ("- Installed directory: `%s`"):format(installed_directory),
    ("- Installed: %d"):format(#plugins),
    ("- Active: %d"):format(active_count),
    ("- Inactive: %d"):format(#plugins - active_count),
    "",
    ("## Plugins (%d)"):format(#plugins),
  }

  if #plugins == 0 then
    table.insert(lines, "- none")
    return lines
  end

  for _, plugin in ipairs(plugins) do
    table.insert(lines, format_plugin_line(plugin))
  end

  return lines
end

return M
