#
# cloudflare
#

{
  xdg.configFile."mise/conf.d/cloudflare.toml".source = ./.config/mise/conf.d/cloudflare.toml;

  home.sessionVariables = {
    # src: https://github.com/cloudflare/workers-sdk/blob/main/packages/create-cloudflare/telemetry.md#how-can-i-configure-create-cloudflare-telemetry
    CREATE_CLOUDFLARE_TELEMETRY_DISABLED = "1";
  };
}
