#
# File manager.
#

{ pkgs, userSettings, ... }: {
  home.packages = with pkgs; [
    # Rust terminal client for Localsend: https://git.kittencollective.com/nebkor/joecalsend
    jocalsend
  ];

  imports = [
    (./. + "/${userSettings.fileManager}")
  ];
}
