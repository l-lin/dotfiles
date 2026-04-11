local tools = {
  "bash-language-server",
  "eslint-lsp",
  "html-lsp",
  "java-debug-adapter",
  "java-test",
  "jdtls",
  "json-lsp",
  "js-debug-adapter",
  "lemminx",
  "lombok-nightly",
  "lua-language-server",
  "nil",
  "prettier",
  "rubocop",
  "ruby-lsp",
  "selene",
  "shellcheck",
  "shfmt",
  -- "sonarlint-language-server",
  "stylua",
  "taplo",
  "vtsls",
  "xmlformatter",
  "yaml-language-server",
  "yamllint",
}

---@type vim.pack.Spec
return
-- Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters.
{
  src = "https://github.com/mason-org/mason.nvim",
  data = {
    setup = function()
      require("mason").setup({
        registries = {
          "github:mason-org/mason-registry",
          "github:nvim-java/mason-registry",
        },
        ui = {
          border = "rounded",
        },
      })

      local mason_registry = require("mason-registry")
      mason_registry.refresh(function()
        for _, tool in ipairs(tools) do
          local ok, package = pcall(mason_registry.get_package, tool)
          if ok and not package:is_installed() then
            package:install()
          end
        end
      end)

      vim.keymap.set("n", "<leader>cm", "<cmd>Mason<cr>", { desc = "Mason" })
    end,
  },
}

