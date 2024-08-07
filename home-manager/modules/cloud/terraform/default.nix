#
# Tool for building, changing, and versioning infrastructure.
# src: https://www.terraform.io/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ terraform ];
}
