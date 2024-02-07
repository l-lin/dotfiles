# Colors
# from: https://github.com/eendroroy/alacritty-theme/blob/master/themes/gruvbox_light.yaml
background='#fbf1c7'
foreground='#3c3836'
color_black='#fbf1c7'
color_red='#cc241d'
color_green='#98971a'
color_yellow='#d79921'
color_blue='#458588'
color_magenta='#b16286'
color_cyan='#689d6a'
color_white='#7c6f64'
color_altblack='#928374'
color_altred='#9d0006'
color_altgreen='#79740e'
color_altyellow='#b57614'
color_altblue='#076678'
color_altmagenta='#8f3f71'
color_altcyan='#427b58'
color_altwhite='#3c3836'

accent="${color_yellow}"
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

# Geany
geany_colors='slime.conf'
geany_font='JetBrains Mono 10'

# Appearance
gtk_font='Noto Sans 13'
gtk_theme='Slime'
icon_theme='Zafiro'
cursor_theme='Qogirr'

# Openbox
ob_theme='Slime'
ob_layout='DLIMC'
ob_font='JetBrains Mono'
ob_font_size='13'
ob_menu='menu-icons.xml'
ob_margin_t='0'
ob_margin_b='0'
ob_margin_l='0'
ob_margin_r='0'

# theme
wallpaper_color="#7B8D59"
nvim_colorscheme="gruvbox"
nvim_background="light"
# theme from cmd `bat --list-themes`
bat_theme="gruvbox-light"
# theme from cmd `delta --list-syntax-themes`
delta_theme="${bat_theme}"

