--
-- Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters.
--

require("mason").setup({
  -- Fetch Java related libraries from another registry (main mason registry does not have the java-test, lombok and spring-boot-tools).
  -- To install a specific version of a package installed by Mason:
  -- 1. edit .local/share/nvim/mason/registries/github/mason-org/mason-registry/registry.json
  -- 2. uninstall the LSP/DAP/Whatever from Mason UI
  -- 3. search for your LSP/DAP/Whatever and put your version
  -- 4. re-open Neovim
  -- src: https://github.com/rochakgupta/dotfiles/blob/e68d52d5b33b9d93e13ca8db8c63c04745cdd995/.config/nvim/lua/rochakgupta/plugins/nvim-lspconfig/servers.lua#L5-L20
  registries = {
    "github:nvim-java/mason-registry",
    "github:mason-org/mason-registry",
  },
  ui = { border = "rounded" }
})
require("mason-tool-installer").setup({
  ensure_installed = {
    "bash-language-server",
    "eslint-lsp",
    "java-debug-adapter",
    "java-test",
    "jdtls",
    "js-debug-adapter",
    "html-lsp",
    "json-lsp",
    "lemminx",
    "lombok-nightly",
    "lua-language-server",
    "nil",
    "prettier",
    "rubocop",
    "ruby-lsp",
    "shellcheck",
    "shfmt",
    "selene",
    "stylua",
    "taplo",
    "vtsls",
    "yaml-language-server",
    "yamllint",
  },
  auto_update = false,
  run_on_start = true,
})

--
-- Keymaps
--

vim.keymap.set("n", "<leader>cm", "<cmd>Mason<cr>", { desc = "Mason" })
