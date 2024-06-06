# See https://nixos.wiki/wiki/Zsh
{ pkgs, ... }: {
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh ];
  # Set the default shell to user accounts.
  # https://mynixos.com/nixpkgs/option/users.defaultUserShell
  users.defaultUserShell = pkgs.zsh;
}
