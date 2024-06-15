#
# Screen color temperature manager.
# src: http://jonls.dk/redshift
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ redshift ];

  # Symlink to ~/.config/.config/redshift/redshift.conf
  xdg.configFile."redshift/redshift.conf".source = ./config/redshift.conf;
}
