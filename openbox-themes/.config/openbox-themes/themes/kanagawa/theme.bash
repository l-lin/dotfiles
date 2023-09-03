# Colors
# from: https://github.com/rebelot/kanagawa.nvim/blob/master/extras/alacritty_kanagawa.yml
background='#1f1f28'
foreground='#dcd7ba'
altbackground='#363646'
altforeground='#c8c093'
color_black='#090618'
color_red='#c34043'
color_green='#76946a'
color_yellow='#c0a36e'
color_blue='#7e9cd8'
color_magenta='#957fb8'
color_cyan='#6a9589'
color_white='#c8c093'
color_altblack='#727169'
color_altred='#e82424'
color_altgreen='#98bb6c'
color_altyellow='#e6c384'
color_altblue='#7fb4ca'
color_altmagenta='#938aa9'
color_altcyan='#7aa89f'
color_altwhite='#dcd7ba'

accent="${color_blue}"
light_value='0.05'
dark_value='0.30'

# Wallpaper
wdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
wallpaper="$wdir/wallpaper"

# Polybar
polybar_font='JetBrains Mono:size=11;3'

# Rofi
rofi_font='Iosevka 10'
rofi_icon='Zafiro'

# Terminal
terminal_font_name='JetBrainsMono Nerd Font'
terminal_font_size='14'

# Geany
# from ~/.config/geany/colorschemes
geany_colors='arc.conf'
geany_font='JetBrains Mono 10'

# Appearance
gtk_font='Noto Sans 13'
gtk_theme='Windows-10-Dark'
icon_theme='Zafiro'
cursor_theme='Qogirr'

# Openbox
ob_theme='Windows-10-Dark'
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

# theme
wallpaper_color="#000000"
nvim_colorscheme="kanagawa"
nvim_background="dark"
# theme from cmd `bat --list-themes`
bat_theme="Catppuccin-mocha"
# theme from cmd `delta --list-syntax-themes`
delta_theme="${bat_theme}"

