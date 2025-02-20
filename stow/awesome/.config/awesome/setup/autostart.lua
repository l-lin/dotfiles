-- Rules of thumb when a shell is needed:
-- - A shell is required when the commands contain &&, ;, ||, & or any other unix shell language syntax
-- - When shell variables are defined as part of the command
-- - When the command is a shell alias
-- src: https://awesomewm.org/apidoc/libraries/awful.spawn.html
local awful = require("awful")

-- Change capslock to ctrl.
awful.spawn("setxkbmap -layout us -option ctrl:nocaps -variant altgr-intl")
-- One single monitor to rule them all.
awful.spawn(os.getenv("HOME") .. "/.config/awesome/scripts/monitor-setup.sh")
awful.spawn.with_shell("pgrep xscreensaver || xscreensaver -nosplash")
awful.spawn.with_shell("pgrep flameshot || flameshot")
awful.spawn.with_shell("pgrep redshift || redshift")
-- Suspend notifications by default.
require("naughty").suspend()
