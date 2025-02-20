-- Single monitor for everything, so I'm focus on a single monitor and not be
-- distracted with the laptop monitor.

-- Mappings between the monitor IDs in /sys/class/drm/card1-* and the one used by xrandr.
-- Hardcoding because `xrandr` command is slow (~500ms).
--
-- Keys are the IDs from the drm you can fetch with: ls -1 -d /sys/class/drm/card1-*
-- Values are the IDs used by xrandr you can fetch with: xrandr | grep " connected " | awk '{ print$1 }'.
local monitor_mappings = {
	["DP-1"] = "DP-1",
	["DP-2"] = "DP-2",
	["DP-3"] = "DP-3",
	["DP-4"] = "DP-4",
	["HDMI-A-1"] = "HDMI-1",
	["eDP-1"] = "eDP-1",
	["eDP-2"] = "eDP-2",
}
local card = "card1"
local drm_directory = "/sys/class/drm/"
local laptop_monitor_xrandr_id = "eDP-1"

---@param monitor_directory string the path to the monitor directory
---@return boolean is_connected true if the monitor is connected, false otherwise
local function is_connected(monitor_directory)
	local status = io.open(monitor_directory .. '/status', 'r')
  if not status then
    return false
  end
	local value = status:read('*all')

	return 'connected\n' == value
end

---Get the connected monitors from xrandr command.
---@return boolean ok true if the xrandr command was executed correctly
---@return table connected_monitors the list of connected_monitors
local function get_connected_monitors()
	local result = {}
	local monitor_directories = io.popen("ls -1 -d " .. drm_directory .. card .. "-*")
  if not monitor_directories then
    return false, result
  end

	while true do
		local monitor_directory = monitor_directories:read("*line")
		if not monitor_directory then
			break
		end
		if is_connected(monitor_directory) then
      -- Using % so that `-` is treated as a literal hyphen.
      local drm_id = string.gsub(monitor_directory, drm_directory .. card .. "%-", "")
			result[drm_id] = monitor_mappings[drm_id]
		end
	end
  monitor_directories:close()

	return true, result
end

---Get the first external monitor, if there is one connected.
---@param connected_monitors table the connected monitors
---@return boolean get_external_monitor true if there is an external monitor, false otherwise
---@return string drm_id the id for drm of the external monitor
---@return string xrandr_id the id for xrandr of the external monitor
local function get_external_monitor(connected_monitors)
  for drm_id, xrandr_id in pairs(connected_monitors) do
    if xrandr_id ~= laptop_monitor_xrandr_id then
      return true, drm_id, xrandr_id
    end
  end
  return false, "", ""
end

---Check if the monitor is being displayed or not.
---@param drm_id string the monitor drm id
---@return boolean is_displayed true if it is displayed, false otherwise
local function is_displayed(drm_id)
	local status = io.open(drm_directory .. card .. '-' .. drm_id .. '/dpms', 'r')
  if not status then
    return false
  end
	local value = status:read('*all')

	return 'On\n' == value
end

---Setup monitors to have a single monitor.
---@param connected_monitors table the list of connected monitors
local function setup_monitors(connected_monitors)
  local has_external_monitor, drm_id, xrandr_id = get_external_monitor(connected_monitors)
	if has_external_monitor then
		-- If the external monitor is not displayed, then we should display it before
		-- disabling the laptop monitor.
		if not is_displayed(drm_id) then
			os.execute("xrandr --output " .. xrandr_id .. " --auto")
		end

		-- Disable Laptop monitor, so that I can focus on a single monitor.
		os.execute("xrandr --output " .. laptop_monitor_xrandr_id .. " --off")
	else
		-- Re-enable Laptop monitor.
		os.execute("xrandr --output " .. laptop_monitor_xrandr_id .. " --auto")
	end
end

-- ----------------------------------------------------------------------------

local ok, connected_monitors = get_connected_monitors()
if not ok then
	local naughty = require("naughty")
	naughty.notify({
		preset = naughty.config.presets.critical,
		title = "Failed to setup monitors",
		text = "Could not execute xrandr",
	})
	return
end

setup_monitors(connected_monitors)
