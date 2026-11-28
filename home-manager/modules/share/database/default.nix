#
# Database stuff.
#

{ fileExplorer, ...}: {
  imports = fileExplorer.allSubdirs ./.;

  xdg.configFile."mise/conf.d/sqlfmt.toml".source = ./.config/mise/conf.d/sqlfmt.toml;
}
