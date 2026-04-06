local pack = require("functions.pack")

local notification_title = "nvim-pack"

---@return string
local function installed_directory()
  return vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt")
end

---@return fun(names: string[], opts?: table)|nil
local function pack_delete()
  return vim.pack.delete or vim.pack.del
end

---@param message string
---@param level integer
local function notify(message, level)
  vim.notify(message, level, { title = notification_title })
end

---@return vim.pack.Info[]?
local function managed_plugin_infos()
  local ok, actual = pcall(vim.pack.get, nil, { info = false })
  if not ok then
    notify("Unable to inspect managed plugins: " .. actual, vim.log.levels.ERROR)
    return nil
  end

  return actual
end

---@param lines string[]
local function open_scratch_buffer(lines)
  vim.cmd("botright new")

  local buffer = vim.api.nvim_get_current_buf()

  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].buflisted = false
  vim.bo[buffer].swapfile = false
  vim.bo[buffer].modifiable = true
  vim.bo[buffer].readonly = false
  vim.bo[buffer].filetype = "nvim-pack"

  pcall(vim.api.nvim_buf_set_name, buffer, "nvim-pack://plugins")
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)

  vim.bo[buffer].modifiable = false
  vim.bo[buffer].readonly = true
  vim.bo[buffer].modified = false

  vim.wo[0].number = false
  vim.wo[0].relativenumber = false
  vim.wo[0].wrap = false
end

local function list_plugins()
  local plugin_infos = managed_plugin_infos()
  if plugin_infos == nil then
    return
  end

  local lines = pack.plugin_report_lines(plugin_infos, installed_directory())
  open_scratch_buffer(lines)
end

local function update_plugins()
  vim.pack.update()
end

local function clean_inactive_plugins()
  local plugin_infos = managed_plugin_infos()
  if plugin_infos == nil then
    return
  end

  local grouped_plugin_names = pack.group_plugin_names(plugin_infos)
  if #grouped_plugin_names.inactive == 0 then
    notify("No inactive plugins to clean.", vim.log.levels.INFO)
    return
  end

  local delete = pack_delete()
  if delete == nil then
    notify("vim.pack.delete/del is not available.", vim.log.levels.ERROR)
    return
  end

  for _, plugin_name in ipairs(grouped_plugin_names.inactive) do
    local ok, err = pcall(delete, { plugin_name })
    if not ok then
      notify("Failed to uninstall " .. plugin_name .. ": " .. err, vim.log.levels.ERROR)
    end
  end
end

local M = {}
M.list_plugins = list_plugins
M.update_plugins = update_plugins
M.clean_inactive_plugins = clean_inactive_plugins

return M
