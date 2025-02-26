local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local theme = {}

theme.font          = "JetBrainsMono Nerd Font"

-- Setting colors in accordance of the taglist.
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
theme.fg_minimize   = "#717C7C"

theme.taglist_fg_empty = "#717C7C"

theme.useless_gap   = dpi(0)
theme.border_width  = dpi(2)
theme.border_normal = theme.bg_normal
theme.border_focus  = "#7E9CD8"
theme.border_marked = theme.bg_urgent

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_height = dpi(15)
theme.menu_width  = dpi(100)

theme.awesome_icon = theme_assets.awesome_icon(theme.menu_height, theme.bg_focus, theme.fg_focus)

-- Define the icon theme for application icons. If not set then the icons
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
theme.icon_theme = nil

theme.systray_icon_spacing = dpi(8)
theme.systray_icon_base_size = dpi(16)
theme.systray_margin_top = dpi(6)

theme.taglist_margin_top = dpi(6)
theme.taglist_margin_bottom = dpi(4)
theme.taglist_margin_left = dpi(8)
theme.taglist_margin_right = dpi(4)

theme.big_space_width = dpi(12)

return theme
