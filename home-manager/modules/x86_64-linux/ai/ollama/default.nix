#
# Get up and running with large language models locally
# src: https://github.com/ollama/ollama
#

{
  services.ollama = {
    acceleration = "rocm";
  };
}

