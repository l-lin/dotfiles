require("mason-lspconfig").setup({
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
})
