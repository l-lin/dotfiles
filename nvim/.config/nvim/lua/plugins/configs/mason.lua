local M = {}

local function attach_keymaps(ensure_installed)
  vim.api.nvim_create_user_command("MasonInstallAll", function()
    vim.cmd("MasonInstall " .. table.concat(ensure_installed, " "))
  end, {})
end

local function change_background_color()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "mason",
    callback = function()
      vim.api.nvim_set_hl(0, "MasonNormal", { bg = "none" })
      vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
    end
  })
end

M.setup = function()
  -- Mason install packages to `stdpath("data")/mason`, i.e. `$HOME/.local/share/nvim/mason/`.
  -- You can get the path to the installed Mason packages using `require("mason-registry").get_package("jdtls"):get_install_path()`
  require("mason").setup({
    ui = {
      border = "rounded",
      icons = {
        package_pending = " ",
        package_installed = "󰄳 ",
        package_uninstalled = " 󰚌",
      },
    }
  })
  local ensure_installed = {   -- not an option from mason.nvim
    "gopls",
    "angular-language-server",
    "ansible-language-server",
    "ansible-lint",
    "bash-language-server",
    "codelldb",
    "go-debug-adapter",
    "goimports",
    "golangci-lint",
    "google-java-format",
    "html-lsp",
    "java-debug-adapter",
    "java-test",
    "jdtls",
    "js-debug-adapter",
    "json-lsp",
    "lua-language-server",
    "marksman",
    "rust-analyzer",
    "semgrep",
    "shellcheck",
    "shfmt",
    "sql-formatter",
    "terraform-ls",
    "typescript-language-server",
    "vscode-java-decompiler",
    "xmlformatter",
    "yaml-language-server",
    "yamlfmt",
    "yamllint",
  }
  -- set to global variable, so it can be used for bootstrap.post_install
  vim.g.mason_binaries_list = ensure_installed

  attach_keymaps(ensure_installed)
  change_background_color()
end

return M
