#
# HTTP clients.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # HTTP client: https://curl.se/
    curl
    # Like cURL, but for gRPC: https://github.com/fullstorydev/grpcurl
    grpcurl
    # HTTP load generator, ApacheBench (ab) replacement: https://github.com/rakyll/hey
    hey
    # HTTP load generator inspired by rakyll/hey with tui animation: https://github.com/hatoo/oha
    oha
    # WebSockets client: https://github.com/vi/websocat
    websocat
    # CLI for retrieving files using HTTP, HTTPS and FTP.
    wget
    # Friendly and fast tool for sending HTTP requests: https://github.com/ducaale/xh
    xh
  ];
}
