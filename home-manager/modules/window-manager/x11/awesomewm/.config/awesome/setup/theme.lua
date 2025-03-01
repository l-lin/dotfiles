require("beautiful").init(os.getenv("HOME") .. "/.config/awesome/theme/init.lua")
require("gears").wallpaper.maximized(os.getenv("HOME") .. "/Pictures/" .. require("config").polarity .. ".jpg")
