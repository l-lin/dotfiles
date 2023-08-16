local M = {}

M.attach_keymaps = function()
  vim.keymap.set("n", "<leader>vm", "<cmd>Mason<CR>", { noremap = true, desc = "Open Mason" })
end

M.change_background_color = function()
  local bg = require("appearance").get_background_color()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "mason",
    callback = function()
      vim.api.nvim_set_hl(0, "MasonNormal", { bg = bg })
      vim.api.nvim_set_hl(0, "FloatBorder", { bg = bg })
    end
  })
end

M.setup = function()
  local config = {
    ui = {
      border = "rounded",
    }
  }
  -- Mason install packages to `stdpath("data")/mason`, i.e. `$HOME/.local/share/nvim/mason/`.
  -- You can get the path to the installed Mason packages using `require("mason-registry").get_package("jdtls"):get_install_path()`
  require("mason").setup(config)

  M.attach_keymaps()
  M.change_background_color()

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
  -- vscode-java-decompiler
  -- xmlformatter
  -- yaml-language-server yamlls
  -- yamlfmt
  -- yamllint
end

return M
