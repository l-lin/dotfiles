#
# Best text editor in the world!
# src: https://neovim.io/
#

{ config, pkgs, ... }: {
  # https://mynixos.com/nixpkgs/options/programs.neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    # Symlink vi and vim to nvim binary.
    viAlias = true;
    vimAlias = true;

    withRuby = true;
    withNodeJs = true;
    withPython3 = true;

    # Add imagemagick to support rendering images with NeoVim: https://github.com/3rd/image.nvim
    extraLuaPackages = ps: [ ps.magick ];
    extraPackages = with pkgs; [ imagemagick ];

    plugins = [
      # All other plugins are managed by lazy-nvim
      pkgs.vimPlugins.lazy-nvim
    ];
  };

  # Symlink ~/.config/nvim
  xdg.configFile."nvim/lua/plugins/colorscheme.lua".text = ''
-- set background
vim.o.bg = "${config.theme.polarity}"

return {
  ${config.theme.nvimColorSchemePluginLua},
  -- setup colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "${config.theme.nvimColorScheme}",
    },
  },
}
  '';
}
