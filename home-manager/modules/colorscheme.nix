#
# Colorscheme management in home-manager.
# src: https://github.com/Misterio77/nix-colors
#

{ inputs, nix-colors, userSettings, ... }: {
  imports = [ nix-colors.homeManagerModules.default ];

  # Set the colorscheme
  colorScheme = inputs.nix-colors.colorSchemes."${userSettings.colorscheme}";

  # TODO: create variable with more semantic field names

  # palette matching
  #
  # background = base00
  # foreground = base05
  #
  # [colors.normal]
  # black   =
  # red     = base08
  # green   = base0B
  # yellow  = base0A
  # blue    = base0D
  # magenta = base0E
  # cyan    = base0C
  # white   = base06
  #
  # [colors.bright]
  # black   = base04
  # red     =
  # green   =
  # yellow  =
  # blue    =
  # magenta =
  # cyan    =
  # white   = base05
  #
  # [colors.selection]
  # background =
  # foreground = base06
}
