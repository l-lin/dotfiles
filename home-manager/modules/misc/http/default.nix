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
    # User-friendly command line HTTP client: https://httpie.io/
    httpie
    # WebSockets client: https://github.com/vi/websocat
    websocat
    # CLI for retrieving files using HTTP, HTTPS and FTP.
    wget
  ];
}
