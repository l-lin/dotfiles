#
# Code related stuff.
#

{ pkgs, ...}: {
  imports = [
    ./direnv
    ./docker
    ./go
    ./java
    ./psql
    ./python
  ];

  home.packages = with pkgs; [
    # GNU Compiler Collection.
    gcc
  ];
}
