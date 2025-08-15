#
# Define the theme options.
# To add a new theme, you have to:
#
# - create home-manager/share/style/themes/<theme>/default.nix
# - create home-manager/share/style/themes/<theme>/colorscheme.yaml
#   - you can fetch the colors from https://github.com/tinted-theming/schemes/tree/spec-0.11/base16
#
# Using base16 colors:
#
# | Name    | Typical Role / Usage                                              | Dark background | Light background |
# |---------|-------------------------------------------------------------------|-----------------|------------------|
# | base00  | Default Background                                                | Black/Dark      | White/Ligh       |
# | base01  | Lighter Background (status bars, line number, etc.)               | Very dark gray  | Very light gray  |
# | base02  | Selection Background                                              | Dark gray       | Light gray       |
# | base03  | Comments, Invisibles, Line Highlighting                           | Gray            | Gray             |
# | base04  | Dark Foreground (status bars)                                     | Light gray      | Dark gray        |
# | base05  | Default Foreground, Caret, Delimiters, Operators                  | White/Light     | Black/Dark       |
# | base06  | Light Foreground (not often used)                                 | Very light gray | Very dark gray   |
# | base07  | Light Background (not often used)                                 | White           | Black            |
# | base08  | Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted | Red             | Red              |
# | base09  | Integers, Boolean, Constants, XML Attributes, Markup Link Url     | Orange          | Orange           |
# | base0A  | Classes, Markup Bold, Search Text Background                      | Yellow          | Yellow           |
# | base0B  | Strings, Inherited Class, Markup Code, Diff Inserted              | Green           | Green            |
# | base0C  | Support, Regular Expressions, Escape Characters, Markup Quotes    | Cyan            | Cyan             |
# | base0D  | Functions, Methods, Attribute IDs, Headings                       | Blue            | Blue             |
# | base0E  | Keywords, Storage, Selector, Markup Italic, Diff Changed          | Magenta         | Magenta          |
# | base0F  | Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?> | Brown           | Brown            |
#

{ lib, userSettings, ... }: {
  options.theme = with lib; {
    nvimColorScheme = mkOption {
      type = types.str;
      description = "NeoVim color scheme.";
    };
    nvimColorSchemePluginLua = mkOption {
      type = types.str;
      description = "NeoVim color scheme plugin in Lua.";
    };
    polarity = mkOption {
      type = types.str;
      description = "Polarity of the theme (dark or light).";
    };
  };

  imports = [
    (./. + "/${userSettings.theme}")
  ];
}
