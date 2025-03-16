#
# Email tools.
#

{
  programs = {
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

