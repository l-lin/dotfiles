# Colors
# from: https://github.com/projekt0n/github-theme-contrib/blob/main/themes/alacritty/github_light_high_contrast.yml
background='#f2eede'
foreground='#010409'
color_black='#0e1116'
color_red='#a0111f'
color_green='#024c1a'
color_yellow='#d79921'
color_blue='#0349b4'
color_magenta='#622cbc'
color_cyan='#1b7c83'
color_white='#66707b'
color_altblack='#4b535d'
color_altred='#86061d'
color_altgreen='#055d20'
color_altyellow='#4e2c00'
color_altblue='#1168e3'
color_altmagenta='#622cbc'
color_altcyan='#1b7c83'
color_altwhite='#66707b'

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
wallpaper_color="#f2eede"
nvim_colorscheme="github_light_high_contrast"
nvim_background="light"
# theme from cmd `bat --list-themes`
bat_theme="GitHub"
# theme from cmd `delta --list-syntax-themes`
delta_theme="${bat_theme}"

