-- Mason install packages to `stdpath("data")/mason`, i.e. `$HOME/.local/share/nvim/mason/`.
require("mason").setup {}

-- -------------------------------
-- KEYMAPS
-- -------------------------------
vim.keymap.set("n", "<leader>vm", "<cmd>Mason<CR>", { noremap = true, desc = "Open Mason" })

-- package to install:
--
-- google-java-format
-- angular-language-server angularls
-- ansible-language-server ansiblels
-- ansible-lint
-- bash-language-server bashls
-- go-debug-adapter
-- goimports
-- golangci-lint
-- gopls
-- java-debug-adapter
-- jdtls
-- js-debug-adapter
-- json-lsp jsonls
-- lua-language-server lua_ls
-- marksman
-- rust-analyzer rust_analyzer
-- rustfmt
-- semgrep
-- shellcheck
-- shfmt
-- sql-formatter
-- terraform-ls terraformls
-- typescript-language-server tsserver
-- xmlformatter
-- yaml-language-server yamlls
-- yamlfmt
-- yamllint
