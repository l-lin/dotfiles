-- Rules of thumb when a shell is needed:
-- - A shell is required when the commands contain &&, ;, ||, & or any other unix shell language syntax
-- - When shell variables are defined as part of the command
-- - When the command is a shell alias
-- src: https://awesomewm.org/apidoc/libraries/awful.spawn.html
local awful = require("awful")

-- Change capslock to ctrl.
awful.spawn("setxkbmap -layout us -option ctrl:nocaps -variant altgr-intl")
-- Set screen locker.
awful.spawn.with_shell("pgrep xscreensaver || xscreensaver -nosplash")
-- Screenshot tool must be started in background in order to be used.
awful.spawn.with_shell("pgrep flameshot || flameshot")
-- Night screen light.
awful.spawn.with_shell("pgrep redshift || redshift")
-- Suspend notifications by default.
require("naughty").suspend()
-- Start applications if not started
awful.spawn.with_shell("pgrep tmux || " .. require("config").terminal .. " -e tmux -2 -u")
awful.spawn.with_shell("pgrep zen || zen")
awful.spawn.with_shell("pgrep slack || slack")
awful.spawn.with_shell("pgrep -f indicator-cpufreq || indicator-cpufreq")
