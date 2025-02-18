local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local theme = {}

theme.font          = "JetBrainsMono Nerd Font"

-- Setting colors in accordance of the taglist.
theme.warning       = "#FFA066"

theme.bg_normal     = "#1F1F28"
theme.bg_focus      = "#7E9CD8"
theme.bg_urgent     = theme.bg_normal
theme.bg_warning    = theme.bg_normal
theme.bg_minimize   = "#717C7C"
theme.bg_systray    = theme.bg_normal

theme.fg_normal     = "#DCD7BA"
theme.fg_focus      = theme.bg_normal
theme.fg_urgent     = "#C34043"
theme.fg_warning    = "#FFA066"
theme.fg_minimize   = theme.fg_normal

theme.useless_gap   = dpi(0)
theme.border_width  = dpi(1)
theme.border_normal = theme.bg_normal
theme.border_focus  = "#7E9CD8"
theme.border_marked = theme.bg_urgent

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- taglist_[bg|fg]_[focus|urgent|occupied|empty|volatile]
-- tasklist_[bg|fg]_[focus|urgent]
-- titlebar_[bg|fg]_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- mouse_finder_[color|timeout|animate_timeout|radius|factor]
-- prompt_[fg|bg|fg_cursor|bg_cursor|font]
-- hotkeys_[bg|fg|border_width|border_color|shape|opacity|modifiers_fg|label_bg|label_fg|group_margin|font|description_font]
-- Example:
--theme.taglist_bg_focus = "#ff0000"

-- Generate taglist squares:
local taglist_square_size = dpi(4)
theme.taglist_squares_sel = theme_assets.taglist_squares_sel(
    taglist_square_size,
    theme.fg_normal
)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(
    taglist_square_size,
    theme.fg_normal
)

-- Variables set for theming notifications:
-- notification_font
-- notification_[bg|fg]
-- notification_[width|height|margin]
-- notification_[border_color|border_width|shape|opacity]

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_height = dpi(15)
theme.menu_width  = dpi(100)

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.bg_widget = "#cc0000"

theme.wallpaper = os.getenv("HOME") .. "/.wallpaper"

-- Generate Awesome icon:
theme.awesome_icon = theme_assets.awesome_icon(theme.menu_height, theme.bg_focus, theme.fg_focus)

-- Define the icon theme for application icons. If not set then the icons
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
theme.icon_theme = nil

return theme
