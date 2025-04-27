#
# 📦 Repomix (formerly Repopack) is a powerful tool that packs your entire repository into a single, AI-friendly file. Perfect for when you need to feed your codebase to Large Language Models (LLMs) or other AI tools like Claude, ChatGPT, DeepSeek, Perplexity, Gemini, Gemma, Llama, Grok, and more. 
# src: https://github.com/yamadashy/repomix
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ repomix ];

  # Symlink ~/.config/repomix/repomix.config.json.
  xdg.configFile."repomix/repomix.config.json".source = ./.config/repomix/repomix.config.json;
}
