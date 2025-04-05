#
# Monitor resources.
# src: https://github.com/aristocratos/btop
#

{
  # Enabling using `programs` instead of `home.packages` so stylix can parameterized its colorscheme.
  programs.btop = {
    enable = true;
    settings = {
      vim_keys = true;
    };
  };
}
