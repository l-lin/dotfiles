{ userSettings, ... }: {
  users.users.${userSettings.username} = {
    isNormalUser = true;
    description = userSettings.name;
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = [];
    uid = 1000;
  };
}
