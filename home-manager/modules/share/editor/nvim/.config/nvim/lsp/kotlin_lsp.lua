---@type vim.lsp.Config
return {
  cmd = { "kotlin-lsp" },
  filetypes = { "kotlin" },
  root_markers = { "build.gradle", "build.gradle.kts", "pom.xml" },
  settings = {},
}
