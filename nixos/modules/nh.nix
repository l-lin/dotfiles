#
# NH reimplements some basic nix commands. Adding functionality on top of the existing solutions, like nixos-rebuild, home-manager cli or nix itself.
#
# As the main features:
#
# - Tree of builds with nix-output-monitor
# - Visualization of the upgrade diff with nvd
# - Asking for confirmation before performing activation
# src: https://github.com/viperML/nh
#

{
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 3";
    };
  };
}
