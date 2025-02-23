local naughty = require("naughty")
local widgets = require("lib.widgets")

local function suspend()
  naughty.suspend()
  widgets.notification_status.update()
end

local function toggle()
  naughty.toggle()
  widgets.notification_status.update()
end

local function destroy_all_notifications()
  naughty.destroy_all_notifications()
end

local M = {}
M.suspend = suspend
M.toggle = toggle
M.destroy_all_notifications = destroy_all_notifications
return M
