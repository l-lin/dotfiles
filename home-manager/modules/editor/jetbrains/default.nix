#
# Tools for software developers.
# src: https://www.jetbrains.com/
#

{
  # HACK: DISABLED because RubyMine does not seem to find rbenv...
  # home.packages = with pkgs; [ jetbrains-toolbox ];

  # Symlink to ~/.ideavimrc
  home.file.".ideavimrc".source = ./.ideavimrc;
}
