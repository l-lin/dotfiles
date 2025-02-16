local naughty = require("naughty")

---Check if a file or directory exists in this path
---src: https://stackoverflow.com/a/40195356/3612053
---
---@param file string the file or directory to check
---@return boolean ok if the file or directory exists
---@return string? err error if there are any issue
local function exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return err == nil and ok
end

local function extract_project_name(project_url)
    return project_url:match("([^/]+)$")
end

local function clone_if_not_exists(plugin_url)
  local plugins_home = os.getenv("HOME") .. "/.config/awesome"
  local plugin_name = extract_project_name(plugin_url)

  if not exists(plugins_home) then
    naughty.notify({ title = "Init " .. plugin_name, text = "Creating directory " .. plugins_home })
    os.execute("mkdir " .. plugins_home)
  end

  local plugin_path = plugins_home .. "/" .. plugin_name
  if not exists(plugin_path) then
    naughty.notify({ title = "Init " .. plugin_name, text = "Cloning project " .. plugins_home .. " to " .. plugin_path })
    local success, exitcode = os.execute("git clone " .. plugin_url .. " " .. plugin_path)
    if not success then
      naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Error while cloning plugin " .. plugin_name,
        text = "Got exit status " .. exitcode,
      })
    end
  end

  package.path = package.path .. ";" .. plugin_path
end

local M = {}
M.clone_if_not_exists = clone_if_not_exists
return M
