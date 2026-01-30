#
# Generation of diagrams from text in a similar manner as markdown
# src: https://github.com/mermaid-js/mermaid-cli
#

{
  xdg.configFile = {
    "zsh/functions/mermaidify".source = ./.config/zsh/functions/mermaidify;
    "mise/conf.d/mermaid.toml".source = ./.config/mise/conf.d/mermaid.toml;
  };
}
