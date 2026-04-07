return {
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = { "html" },
  init_options = {
    provideFormatter = true,
    embeddedLanguages = { css = true, javascript = true },
    configurationSection = { "html", "css", "javascript" },
  },
  root_markers = { "package.json", ".git" },
  settings = {},
}
