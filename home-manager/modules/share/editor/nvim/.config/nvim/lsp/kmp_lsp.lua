---@type vim.lsp.Config
return {
  cmd = { "kmp-lsp" },
  filetypes = { "kotlin", "java" },
  root_markers = { "build.gradle", "build.gradle.kts", "pom.xml" },
  settings = {},
}
