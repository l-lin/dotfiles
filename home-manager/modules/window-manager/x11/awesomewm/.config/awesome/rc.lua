-- Should be among the first to be called, so that notifications are displayed
-- when there are errors.
require("setup.errors")

require("lib/git").clone_if_not_exists("https://github.com/lcpz/lain")

require("colorscheme")
require("setup.layout")
-- Set the terminal for applications that require it
require("menubar").utils.terminal = require("config").terminal
require("setup.screen")
require("setup.signals")
require("setup.mouse")
require("setup.rules")
require("keybindings.global")

-- Rules of thumb when a shell is needed:
-- - A shell is required when the commands contain &&, ;, ||, & or any other unix shell language syntax
-- - When shell variables are defined as part of the command
-- - When the command is a shell alias
-- src: https://awesomewm.org/apidoc/libraries/awful.spawn.html
local awful = require("awful")
awful.spawn("setxkbmap -layout us -option ctrl:nocaps -variant altgr-intl")
awful.spawn(os.getenv("HOME") .. "/.config/awesome/scripts/monitor-setup.sh")
