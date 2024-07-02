#
# Screen lock.
# src: https://github.com/swaywm/swaylock
#

{
  # Need to add this line to make swaylock works.
  # src: https://github.com/NixOS/nixpkgs/issues/158025#issuecomment-1344766809
  security.pam.services.swaylock = {};
}
