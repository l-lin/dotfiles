#
# Web browser.
#

{ fileExplorer, pkgs, userSettings, ... }:
let
  userJs = pkgs.fetchFromGitHub {
    owner = "yokoffing";
    repo = "Betterfox";
    # NOTE: Do not forget to sync the version with the Firefox version.
    rev = "128.0";
    sha256 = "sha256-Xbe9gHO8Kf9C+QnWhZr21kl42rXUQzqSDIn99thO1kE";
  } + "/user.js";

  profileName = userSettings.username;
in {
  programs.firefox = {
    enable = true;
    # Need to install tridactyl-native in order to use ~/.config/tridactyl/.tridactylrc
    nativeMessagingHosts = with pkgs; [ tridactyl-native ];
    profiles."${profileName}" = {
      name = profileName;
      isDefault = true;
      extraConfig = ''
        ${builtins.readFile userJs}
      '';

      search = {
        force = true;
        default = "DuckDuckGo";
        order = ["DuckDuckGo" "Wikipedia (en)" "NixOS Options" "Nix Packages" "GitHub" "Home Manager"];

        engines = {
          "Bing".metaData.hidden = true;
          "eBay".metaData.hidden = true;
          "Amazon.com".metaData.hidden = true;
          "YouTube".metaData.hidden = true;
          "Google".metaData.hidden = true;
          "Qwant".metaData.hidden = true;

          "Nix Packages" = {
            icon = "https://nixos.org/_astro/flake-blue.Bf2X2kC4_Z1yqDoT.svg";
            definedAliases = ["@np"];
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                  {
                    name = "channel";
                    value = "unstable";
                  }
                ];
              }
            ];
          };

          "NixOS Options" = {
            icon = "https://nixos.org/_astro/flake-blue.Bf2X2kC4_Z1yqDoT.svg";
            definedAliases = ["@no"];
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
          };

          "GitHub" = {
            iconUpdateURL = "https://github.com/favicon.ico";
            updateInterval = 24 * 60 * 60 * 1000;
            definedAliases = ["@gh"];
            urls = [
              {
                template = "https://github.com/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
          };

          "Home Manager" = {
            icon = "https://nixos.org/_astro/flake-blue.Bf2X2kC4_Z1yqDoT.svg";
            definedAliases = ["@hm"];
            url = [
              {
                template = "https://home-manager-options.extranix.com";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
          };
        };
      };
    };
  };
}
