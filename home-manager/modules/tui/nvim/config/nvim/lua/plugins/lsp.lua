local function nvim_lspconfig_init()
  -- keymaps for lspconfig must be set in init function: https://www.lazyvim.org/plugins/lsp#%EF%B8%8F-customizing-lsp-keymaps
  local keys = require("lazyvim.plugins.lsp.keymaps").get()

  -- disable code action keymaps (conflict with Diffview merge tool)
  keys[#keys + 1] = { "<leader>ca", false }
  keys[#keys + 1] = { "<leader>cA", false }

  keys[#keys + 1] = {
    "<C-b>",
    function()
      require("telescope.builtin").lsp_definitions({ reuse_win = true })
    end,
    noremap = true,
    silent = true,
    desc = "Goto definition (Ctrl+b)",
  }
  keys[#keys + 1] = {
    "<M-&>",
    function()
      require("telescope.builtin").lsp_references({ show_line = false })
    end,
    noremap = true,
    desc = "LSP references (Ctrl+Shift+7)",
  }
  keys[#keys + 1] = { "<F18>", vim.lsp.buf.rename, noremap = true, desc = "Rename" }
  keys[#keys + 1] = { "<M-CR>", vim.lsp.buf.code_action, noremap = true, desc = "Code action" }
  keys[#keys + 1] = {
    "<M-C-B>",
    function()
      require("telescope.builtin").lsp_implementations({ reuse_win = true, show_line = false })
    end,
    "Goto implementation (Ctrl+Alt+b)",
  }
end

local function nvim_lspconfig_opts()
  return {
    inlay_hints = {
      enabled = true,
    },
  }
end

local function create_mason_config()
  local mason_servers = {
    "gopls",
    "angular-language-server",
    "ansible-language-server",
    "ansible-lint",
    "bash-language-server",
    "codelldb",
    "delve",
    "go-debug-adapter",
    "goimports",
    "goimports-reviser",
    "gofumpt",
    "golangci-lint",
    "gomodifytags",
    "google-java-format",
    "html-lsp",
    "impl",
    "java-debug-adapter",
    "java-test",
    "jdtls",
    "js-debug-adapter",
    "json-lsp",
    "lemminx",
    "lua-language-server",
    "marksman",
    "rust-analyzer",
    "semgrep",
    "shellcheck",
    "shfmt",
    "sonarlint-language-server",
    "sql-formatter",
    "terraform-ls",
    "typescript-language-server",
    "vscode-java-decompiler",
    "xmlformatter",
    "yaml-language-server",
    "yamlfmt",
    "yamllint",
  }

  vim.api.nvim_create_user_command("MasonInstallAll", function()
    vim.cmd("MasonInstall " .. table.concat(mason_servers, " "))
  end, {})

  return {
    -- easily config neovim lsp
    {
      "neovim/nvim-lspconfig",
      init = nvim_lspconfig_init,
      opts = nvim_lspconfig_opts()
    },
    -- easily install/update lsp servers directly from neovim
    {
      "williamboman/mason.nvim",
      -- Mason is unusable on NixOS, disable it.
      cmd = { "MasonInstall", "MasonInstallAll" },
      keys = {
        { "<leader>vm", "<cmd>Mason<cr>", noremap = true, desc = "Open Mason" },
      },
      opts = {
        ensure_installed = mason_servers,
      },
    },

    -- linter
    {
      "sonarlint",
      url = "https://gitlab.com/schrieveslaach/sonarlint.nvim",
      ft = { "go", "js", "java", "xml" },
      opts = function()
        local sonarlint_path = require("mason-registry").get_package("sonarlint-language-server"):get_install_path()
        return {
          server = {
            cmd = {
              "sonarlint-language-server",
              -- Ensure that sonarlint-language-server uses stdio channel
              "-stdio",
              "-analyzers",
              sonarlint_path .. "/extension/analyzers/sonargo.jar",
              sonarlint_path .. "/extension/analyzers/sonarjava.jar",
              sonarlint_path .. "/extension/analyzers/sonarjs.jar",
              sonarlint_path .. "/extension/analyzers/sonarxml.jar",
            },
          },
          filetypes = {
            "go",
            "java",
            "js",
            "xml",
          },
        }
      end,
    },
  }
end

local function create_lazy_lsp()
  return {
    -- Mason is unusable on NixOS, disable it.
    {
      "williamboman/mason.nvim",
      -- Mason is unusable on NixOS, disable it.
      enabled = false,
    },
    {
      "williamboman/mason-lspconfig.nvim",
      enabled = false,
    },
    -- easily config neovim lsp
    {
      "neovim/nvim-lspconfig",
      init = nvim_lspconfig_init,
      opts = nvim_lspconfig_opts()
    },
    -- Neovim plugin to auto install and start LSP servers by wrapping the commands in a nix-shell env.
    {
      "dundalek/lazy-lsp.nvim",
      lazy = false,
      config = function()
        require("lazy-lsp").setup({})
      end,
    },
  }
end

-- TODO: shall I use lazy-lsp.nvim for NixOS?
-- if vim.g.is_nixos then
--   return create_lazy_lsp()
-- end

return create_mason_config()
