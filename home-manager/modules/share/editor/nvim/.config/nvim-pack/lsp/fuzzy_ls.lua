local cmd = vim.fn.expand(vim.fn.stdpath("data") .. "/site/pack/core/opt/fuzzy_ruby_server/bin/fuzzy_darwin-arm64")

if not vim.fn.executable(cmd) then
  vim.notify(
    "Fuzzy Ruby Server executable not found at " .. cmd .. ". Please ensure it is installed and the path is correct.",
    vim.log.levels.WARN
  )
  return {}
end

return {
  cmd = {
    vim.fn.expand(vim.fn.stdpath("data") .. "/site/pack/core/opt/fuzzy_ruby_server/bin/fuzzy_darwin-arm64"),
  },
  filetypes = { "ruby" },
  init_options = {
    -- possible values:
    -- ram: use RAM (can be very high on big project)
    -- tempdir: use mmap directory to store the indexes (e.g. /tmp/.tmpcCUkiK)
    allocationType = "tempdir",
    indexGems = true,
    reportDiagnostics = true,
  },
  root_markers = { "Gemfile", ".git" },
}
