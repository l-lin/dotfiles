local M = {}

M.setup = function()
  local config = {
    automatic_installation = true,
    ensure_installed = {
      "angularls",
      "ansiblels",
      "bashls",
      "gopls",
      "jdtls",
      "jsonls",
      "lua_ls",
      "marksman",
      "rust_analyzer",
      "terraformls",
      "tsserver",
      "yamlls",
    }
  }
  require("mason-lspconfig").setup(config)
end

return M
