#
# A highly customizable and functional PDF viewer.
# src: https://git.pwmt.org/pwmt/zathura/
#

{
  programs = {
    zathura = {
      # Enabling using `programs` instead of `home.packages` so stylix can parameterized its colorscheme.
      enable = true;
    };
  };

  xdg.configFile."zathura/zathurarc".source = ./.config/zathura/zathurarc;
}
