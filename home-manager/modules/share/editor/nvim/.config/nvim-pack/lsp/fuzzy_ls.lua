return {
  cmd = {
    vim.fn.expand(vim.fn.stdpath("data") .. "/site/pack/core/opt/fuzzy_ruby_server/bin/fuzzy_darwin-arm64"),
  },
  filetypes = { "ruby" },
  init_options = {
    allocationType = "tempdir",
    indexGems = true,
    reportDiagnostics = true,
  },
  root_markers = { "Gemfile", ".git" },
}
