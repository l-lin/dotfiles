#
# Best text editor in the world!
# src: https://neovim.io/
#

{ config, lib, pkgs, symlinkRoot, ... }:
let
  palette = config.lib.stylix.colors.withHashtag;
  colorschemeContent = with palette; ''
-- set background
vim.o.bg = "${config.theme.polarity}"
-- Global variables ftw! Too lazy to have something "smart" but complex...
vim.g.colorscheme_faint = "${base04-hex}"
vim.g.colorscheme_error = "${base08-hex}"
vim.g.colorscheme = "${config.theme.nvimColorScheme}"

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
  colorschemeFile = "${symlinkRoot}/home-manager/modules/share/editor/nvim/.config/nvim/lua/plugins/colorscheme.lua";
  # Magick Lua package for image.nvim support.
  # Can't use extraLuaPackages because it generates an init.lua that conflicts
  # with our xdg.configFile."nvim" symlink (recursive = true).
  magickPkg = pkgs.luajitPackages.magick;
in {
  # https://mynixos.com/nixpkgs/options/programs.neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    # Symlink vi and vim to nvim binary.
    viAlias = true;
    vimAlias = true;

    withRuby = false;
    withNodeJs = true;
    withPython3 = true;

    # Add imagemagick to support rendering images with NeoVim: https://github.com/3rd/image.nvim
    # NOTE: extraLuaPackages is NOT used here because it generates an init.lua
    # that conflicts with our xdg.configFile."nvim" symlink (recursive = true).
    # The magick package paths are set via LUA_PATH/LUA_CPATH env vars instead.
    #extraLuaPackages = ps: [ ps.magick ];
    extraPackages = with pkgs; [ imagemagick ];

    plugins = [
      # All other plugins are managed by lazy-nvim
      pkgs.vimPlugins.lazy-nvim
    ];
  };
  home.sessionVariables = {
    # Use nvim to read man pages.
    #MANPAGER = "nvim +Man!";
    # Magick Lua paths for image.nvim (can't use extraLuaPackages, see above).
    LUA_PATH = "${magickPkg}/share/lua/5.1/?.lua;${magickPkg}/share/lua/5.1/?/init.lua;";
    LUA_CPATH = "${magickPkg}/lib/lua/5.1/?.so;";
  };

  # mkOutOfStoreSymlink creates a mutable symlink (writable at runtime).
  # nvim config needs to be writable because I'm tweaking it everyday.
  xdg.configFile."nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "${symlinkRoot}/home-manager/modules/share/editor/nvim/.config/nvim";
    recursive = true;
  };

  # Write colorscheme.lua to the repo directory during activation.
  # This file uses Nix variables (stylix colors) so it must be generated.
  home.activation.nvimColorscheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p "$(dirname "${colorschemeFile}")"
    $DRY_RUN_CMD cat > "${colorschemeFile}" << 'EOF'
${colorschemeContent}
EOF
  '';
}
