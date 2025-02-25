--
-- Config laptop touchpad so that it has natural scrolling & tap to click.
--
-- To get the list of get the physical-to logical mappings of buttons and keys:
--
--   xinput list
--
-- You can use `xinput --disable <device_id>` to check the right id and `xinput --enable <device_id>`.
-- Check the list of properties of the device:
--
--   xinput list-props <device_id>
--
-- To get the description of all properties:
--
--   man 4 libinput
--
-- src:
-- - https://askubuntu.com/questions/403113/how-do-you-enable-tap-to-click-via-command-line
-- - https://wiki.ubuntu.com/X/Config/Input#Dynamic_Input_Configuration_with_xinput
-- - https://www.reddit.com/r/awesomewm/comments/hu2ac0/natural_scrolling/
--

local awful = require("awful")

---Get the touchpad device id
---@return boolean ok true if the xinput command was executed correctly
---@return number? device_id the touchpad device id, -1 if not found
local function find_touchpad_device_id()
  local result = tonumber(-1)

	local devices = io.popen("xinput list")
  if not devices then
    return false, result
  end


	while true do
		local device = devices:read("*line")
		if not device then
			break
		end
		if string.find(device, "Touchpad") then
      local id = device:match("id=(%d+)")
      -- Convert string to number and return
      result = tonumber(id)
		end
	end
  devices:close()

  if result > 0 then
    return true, result
  end
  return false, result
end

local ok, device_id = find_touchpad_device_id()
if not ok then
  return
end

-- Natural scrolling (scroll toward bottom will go up, toward top will go down).
awful.spawn("xinput set-prop " .. device_id .. " 'libinput Natural Scrolling Enabled' 1")
-- Tap to click.
awful.spawn("xinput set-prop " .. device_id .. " 'libinput Tapping Enabled' 1")
