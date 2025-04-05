local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local colors = require("theme.colors")

local theme = {}

theme.font = "JetBrainsMono Nerd Font"

-- Setting colors in accordance of the taglist.
theme.bg_normal = colors.bg_normal
theme.bg_focus = colors.bg_focus
theme.bg_urgent = colors.bg_urgent
theme.bg_warning = colors.bg_warning
theme.bg_minimize = colors.bg_minimize
theme.bg_systray = colors.bg_systray

theme.fg_normal = colors.fg_normal
theme.fg_focus = colors.fg_focus
theme.fg_urgent = colors.fg_urgent
theme.fg_warning = colors.fg_warning
theme.fg_minimize = colors.fg_minimize

theme.taglist_fg_empty = colors.taglist_fg_empty

theme.useless_gap = dpi(0)
theme.border_width = dpi(2)
theme.border_normal = colors.bg_normal
theme.border_focus = colors.border_focus
theme.border_marked = colors.bg_urgent

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_height = dpi(15)
theme.menu_width = dpi(100)

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
