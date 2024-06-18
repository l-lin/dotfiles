#
# Set users here.
#

{ userSettings, ... }: {
  # Exhaustive list of options: https://mynixos.com/nixpkgs/options/users.users.%3Cname%3E
  users.users.${userSettings.username} = {
    isNormalUser = true;
    description = userSettings.name;
    extraGroups = [ "audio" "networkmanager" "wheel" "docker" ];
    packages = [];
    uid = 1000;
  };
}
