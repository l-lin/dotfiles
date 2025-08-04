#
# Best text editor in the world!
# src: https://neovim.io/
#

{ config, pkgs, ... }:
let
  palette = config.lib.stylix.colors.withHashtag;
in {
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
  xdg.configFile."nvim/lua/plugins/colorscheme.lua".text = with palette; ''
-- set background
vim.o.bg = "${config.theme.polarity}"
-- Global variables ftw! Too lazy to have something "smart" but complex...
vim.g.colorscheme_faint = "${base04-hex}"
vim.g.colorscheme_error = "${base08-hex}"
vim.g.dark_colorscheme = "kanagawa"
vim.g.light_colorscheme = "github_light"

return {
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    opts = {
      keywordStyle = { bold = true, italic = false },
    },
  },
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    opts = {
      options = {
        styles = {
          keywords = "bold",
        },
      },
      groups = {
        github_light_high_contrast = {
          NonText = { fg = "palette.gray" },
          SnacksPickerMatch = { link = "Search" },
          TreesitterContext = { bg = "#E6E6E6" },
          RenderMarkdownCodeInline = { bg = "#E6E6E6" },
          SnacksIndent = { fg = "#E6E6E6" },
        },
        github_light = {
          NonText = { fg = "palette.gray" },
          SnacksPickerMatch = { link = "Search" },
          TreesitterContext = { bg = "#E6E6E6" },
          RenderMarkdownCodeInline = { link = TreesitterContext },
          SnacksIndent = { fg = "#E6E6E6" },
          LspReferenceRead = { link = "TreesitterContext" },
          LspReferenceWrite = { link = "TreesitterContext" },
        },
      },
      specs = {
        github_light_high_contrast = {
          bg0 = "${base00-hex}",
          bg1 = "${base00-hex}",
          canvas = {
            default = "#FFFFFF",
            inset = "#FFFFFF",
            overlay = "#FFFFFF",
          },
          syntax = {
            keyword = "black",
          },
        },
        github_light = {
          bg0 = "${base00-hex}",
          bg1 = "${base00-hex}",
          canvas = {
            default = "#FFFFFF",
            inset = "#FFFFFF",
            overlay = "#FFFFFF",
          },
          syntax = {
            keyword = "black",
          },
        },
      },
    },
    config = function(_, opts)
      require("github-theme").setup(opts)
    end,
  },
  -- setup colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "${config.theme.nvimColorScheme}",
    },
  },
}
  '';

  xdg.configFile."mcphub" = {
    source = ./.config/mcphub;
    recursive = true;
  };
}
