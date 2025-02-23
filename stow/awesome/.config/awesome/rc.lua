-- Should be among the first to be called, so that notifications are displayed
-- when there are errors.
require("setup.errors")
require("setup.theme")

require("lib/git").clone_if_not_exists("https://github.com/lcpz/lain")

require("keybindings.global")

require("setup.layout")
require("setup.screen")
require("setup.signals")
require("setup.mouse")
require("setup.rules")
require("setup.autostart")
