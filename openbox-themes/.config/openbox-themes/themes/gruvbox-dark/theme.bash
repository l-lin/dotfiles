# ------------------------------------------------------------------------------
# Copyright (C) 2020-2022 Aditya Shakya <adi1090x@gmail.com>
#
# Default Theme
# ------------------------------------------------------------------------------

# Colors
# from: https://github.com/eendroroy/alacritty-theme/blob/master/themes/gruvbox_dark.yaml
background='#282828'
foreground='#ebdbb2'
color0='#282828'
color1='#cc241d'
color2='#98971a'
color3='#d79921'
color4='#458588'
color5='#b16286'
color6='#689d6a'
color7='#a89984'
color8='#928374'
color9='#fb4934'
color10='#b8bb26'
color11='#fabd2f'
color12='#83a598'
color13='#d3869b'
color14='#8ec07c'
color15='#ebdbb2'

accent='#fe8019'
light_value='0.05'
dark_value='0.30'

# Wallpaper
wdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
wallpaper="$wdir/wallpaper"

# Polybar
polybar_font='JetBrains Mono:size=10;3'

# Rofi
rofi_font='Iosevka 10'
rofi_icon='Zafiro'

# Terminal
terminal_font_name='JetBrainsMono Nerd Font'
terminal_font_size='16'

# Geany
# from ~/.config/geany/colorschemes
geany_colors='arc.conf'
geany_font='JetBrains Mono 10'

# Appearance
gtk_font='Noto Sans 13'
gtk_theme='Gruvbox'
icon_theme='Zafiro'
cursor_theme='Qogirr'

# Openbox
# from https://github.com/nathanielevan/gruvbox-material-openbox
ob_theme='gruvbox-material-dark-blocks'
ob_layout='DLIMC'
ob_font='JetBrains Mono'
ob_font_size='13'
ob_menu='menu-icons.xml'
ob_margin_t='0'
ob_margin_b='0'
ob_margin_l='0'
ob_margin_r='0'

# Dunst
dunst_width='300'
dunst_height='80'
dunst_offset='10x48'
dunst_origin='top-right'
dunst_font='JetBrains Mono 10'
dunst_border='4'
dunst_separator='2'

# Plank
plank_hmode='intelligent'
plank_offset='0'
plank_position='bottom'
plank_theme='Transparent'
plank_icon_size='32'
plank_zoom_percent='120'

# Picom
picom_backend='glx'
picom_corner='6'
picom_shadow_r='14'
picom_shadow_o='0.30'
picom_shadow_x='-12'
picom_shadow_y='-12'
picom_blur_method='none'
picom_blur_strength='0'
