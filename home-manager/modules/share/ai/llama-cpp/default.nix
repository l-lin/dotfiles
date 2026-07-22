#
# LLM inference in C/C++.
# src: https://github.com/ggml-org/llama.cpp
#

{ pkgs, ... }: {
  home.sessionVariables = {
    LLAMA_BASE_URL = "http://127.0.0.1:11435";
  };

  home.packages = with pkgs; [
    # Find what runs on your hardware: https://github.com/AlexsJones/llmfit
    llmfit
  ];
}
