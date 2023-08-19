local M = {}

M.setup = function()
  require("nvim-treesitter.configs").setup({
    -- A list of parser names, or "all" (the five listed parsers should always be installed)
    ensure_installed = {
      "c",
      "css",
      "dockerfile",
      "go",
      "gomod",
      "java",
      "javascript",
      "lua",
      "make",
      "markdown",
      "markdown_inline",
      "query",
      "rust",
      "terraform",
      "toml",
      "vim",
      "vimdoc",
    },
    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,
    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don"t have `tree-sitter` CLI installed locally
    auto_install = false,
    highlight = {
      enable = true,
      use_languagetree = true,
    },
    indent = {
      enabled = true
    },
    rainbow = {
      enable = true,
      extended_mode = true,
      max_file_lines = nil
    }
  })
end

return M
