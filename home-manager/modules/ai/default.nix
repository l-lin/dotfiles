#
# AI related stuff.
#

{ pkgs, ... }: {
  services.ollama = {
    acceleration = "rocm";
    enable = true;
  };
  home.packages = with pkgs; [
    #  Go manage your Ollama models: https://github.com/sammcj/gollama
    gollama
  ];
}
