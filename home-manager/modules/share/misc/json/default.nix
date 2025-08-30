#
# JSON related tools.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Make JSON greppable: https://github.com/tomnomnom/gron
    gron
    # Terminal JSON viewer & processor: https://fx.wtf/
    fx
    # Interactive jq: https://git.sr.ht/~gpanders/ijq
    ijq
    # Pager for JSON data: https://jless.io/
    jless
    # Create JSON objects: https://github.com/jpmens/jo
    jo
    # Lightweight and flexible JSON processor: https://jqlang.github.io/jq/
    jq
    # YAML/XML/TOML processor: https://github.com/kislyuk/yq
    yq
  ];
}
