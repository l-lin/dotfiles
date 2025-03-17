#
# Email tools.
#

{
  programs = {
    # Add https://addons.thunderbird.net/en-US/thunderbird/addon/tbkeys-lite/
    # add-on for keybindings.
    thunderbird = {
      enable = true;
      profiles.default = {
        isDefault = true;
        search = {
          default = "DuckDuckGo";
          privateDefault = "DuckDuckGo";
          force = true;
        };
      };
      settings = {
        "general.useragent.override" = "";
        "privacy.donottrackheader.enabled" = true;
      };
    };
  };
}

