#
# Get up and running with large language models locally
# src: https://github.com/ollama/ollama
#

{ pkgs, ... }: {
  services.ollama = {
    acceleration = "rocm";
    enable = true;
  };
  home.packages = with pkgs; [
    # Go manage your Ollama models: https://github.com/sammcj/gollama
    gollama
  ];
}
