local awful = require("awful")

-- Function to check if flameshot daemon is running.
---@return boolean is_running true if it's running, false otherwise
local function is_daemon_running()
	local handle = io.popen("pgrep -x flameshot 2>/dev/null")
  if not handle then
    return false
  end

	local result = handle:read("*a")
	handle:close()

	return result ~= ""
end

local function execute_flameshot()
  if not is_daemon_running() then
    awful.spawn.with_shell("flameshot && sleep 0.5")
  end

  awful.spawn("flameshot gui")
end

local M = {}
M.execute_flameshot = execute_flameshot
return M
