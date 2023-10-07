return {
	-- easily config neovim lsp
  {
    "neovim/nvim-lspconfig",
    init = function()
      -- keymaps for lspconfig must be set in init function: https://www.lazyvim.org/plugins/lsp#%EF%B8%8F-customizing-lsp-keymaps
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      -- format
      keys[#keys + 1] = { "<M-C-L>", "<cmd>lua vim.lsp.buf.format { async = true }<CR>" }
      -- disable diagnostic (performed by Lspaga)
      keys[#keys + 1] = { "]d", false }
      keys[#keys + 1] = { "[d", false }
      keys[#keys + 1] = { "]e", false }
      keys[#keys + 1] = { "[e", false }
      keys[#keys + 1] = { "]w", false }
      keys[#keys + 1] = { "[w", false }
      -- disable rename (performed by Lspaga)
      keys[#keys + 1] = { "<leader>cr", false }
      -- disable code action keymaps (conflict with Diffview merge tool)
      keys[#keys + 1] = { "<leader>ca", false }
      keys[#keys + 1] = { "<leader>cA", false }
    end,
    opts = {
      autoformat = false,
      inlay_hints = {
        enabled = true,
      },
    },
  },

	-- easily install/update lsp servers directly from neovim
  {
    "williamboman/mason.nvim",
    cmd = { "MasonInstall" },
    keys = {
      { "<leader>cm", false },
      { "<leader>vm", "<cmd>Mason<cr>", noremap = true, desc = "Open Mason" },
    },
    opts = {
      ensure_installed = {
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
      },
    },
  },

  -- ui for LSP features
  {
    "glepnir/lspsaga.nvim",
    keys = {
      {
        "]d",
        "<cmd>Lspsaga diagnostic_jump_next<cr>",
        silent = true,
        desc = "Lspsaga diagnostic go to next (F2)",
      },
      {
        "<F2>",
        "<cmd>Lspsaga diagnostic_jump_next<cr>",
        noremap = true,
        silent = true,
        desc = "Lspsaga diagnostic go to next (F2)",
      },
      {
        "[d",
        "<cmd>Lspsaga diagnostic_jump_prev<cr>",
        silent = true,
        desc = "Lspsaga diagnostic go to previous (Shift+F2)",
      },
      {
        "<F14>",
        "<cmd>Lspsaga diagnostic_jump_prev<cr>",
        noremap = true,
        silent = true,
        desc = "Lspsaga diagnostic go to previous (Shift+F2)",
      },
      {
        "]e",
        function()
          require("lspsaga.diagnostic"):goto_next({ severity = vim.diagnostic.severity.ERROR })
        end,
        silent = true,
        desc = "Lspsaga diagnostic go to next ERROR",
      },
      {
        "[e",
        function()
          require("lspsaga.diagnostic"):goto_prev({ severity = vim.diagnostic.severity.ERROR })
        end,
        silent = true,
        desc = "Lspsaga diagnostic go to previous ERROR",
      },
      {
        "]w",
        function()
          require("lspsaga.diagnostic"):goto_next({ severity = vim.diagnostic.severity.WARN })
        end,
        silent = true,
        desc = "Lspsaga diagnostic go to next ERROR",
      },
      {
        "[w",
        function()
          require("lspsaga.diagnostic"):goto_prev({ severity = vim.diagnostic.severity.WARN })
        end,
        silent = true,
        desc = "Lspsaga diagnostic go to previous ERROR",
      },
      {
        "<leader>ce",
        "<cmd>Lspsaga show_line_diagnostics<cr>",
        noremap = true,
        silent = true,
        desc = "Lspsaga diagnostic show message (Ctrl+F1)",
      },
      {
        "<F25>",
        "<cmd>Lspsaga show_line_diagnostics<cr>",
        noremap = true,
        silent = true,
        desc = "Lspsaga diagnostic show message (Ctrl+F1)",
      },
      {
        "<leader>ch",
        "<cmd>Lspsaga hover_doc<cr>",
        noremap = true,
        silent = true,
        desc = "LSP show hovering help (Shift+k)",
      },
      {
        "<S-k>",
        "<cmd>Lspsaga hover_doc<cr>",
        noremap = true,
        silent = true,
        desc = "LSP show hovering help (Shift+k)",
      },
      {
        "<leader>cc",
        "<cmd>Lspsaga finder<cr>",
        noremap = true,
        silent = true,
        desc = "Lspsaga definition and usage finder (Cltr+Alt+7)",
      },
      {
        "<M-&>",
        "<cmd>Lspsaga finder<cr>",
        noremap = true,
        silent = true,
        desc = "Lspsaga definition and usage finder (Ctrl+Alt+7)",
      },
      -- NOTE: does not work for going into third party dependencies => use the one from Telescope
      -- {
      --   "<leader>cd",
      --   "<cmd>Lspsaga goto_definition<cr>",
      --   noremap = true,
      --   silent = true,
      --   desc = "Lspsaga go to definition (Ctrl+b)",
      -- },
      -- {
      --   "<C-b>",
      --   "<cmd>Lspsaga goto_definition<cr>",
      --   noremap = true,
      --   silent = true,
      --   desc = "Lspsaga go to definition (Ctrl+b)",
      -- },
      {
        "<leader>cD",
        "<cmd>Lspsaga peek_definition<cr>",
        noremap = true,
        silent = true,
        desc = "Lspsaga peek definition",
      },
      {
        "<leader>ct",
        "<cmd>Lspsaga goto_type_definition<cr>",
        noremap = true,
        silent = true,
        desc = "Lspsaga goto type definition",
      },
      {
        "<leader>cT",
        "<cmd>Lspsaga peek_type_definition<cr>",
        noremap = true,
        silent = true,
        desc = "Lspsaga peek type definition",
      },
      {
        "<leader>ci",
        "<cmd>Lspsaga incoming_calls<cr>",
        noremap = true,
        silent = true,
        desc = "Lspsaga incoming calls",
      },
      {
        "<leader>co",
        "<cmd>Lspsaga outgoing_calls<cr>",
        noremap = true,
        silent = true,
        desc = "Lspsaga outgoing calls",
      },
      {
        "<leader>cm",
        "<cmd>Lspsaga outline<cr>",
        noremap = true,
        silent = true,
        desc = "Lspsaga outline minimap (Alt+7)",
      },
      {
        "<M-7>",
        "<cmd>Lspsaga outline<cr>",
        noremap = true,
        silent = true,
        desc = "Lspsaga outline minimap (Alt+7)",
      },
      {
        "<leader>cr",
        "<cmd>Lspsaga rename ++project<cr>",
        noremap = true,
        silent = true,
        desc = "Lspsaga rename in the whole project",
      },
      {
        "<F18>",
        "<cmd>Lspsaga rename<cr>",
        noremap = true,
        silent = true,
        desc = "Lspsaga rename (Shift+F6)",
      },
      {
        "<leader>cE",
        "<cmd>Lspsaga show_buf_diagnostics<cr>",
        noremap = true,
        silent = true,
        desc = "LSP show errors",
      },
      -- {
      --   "<leader>ca",
      --   "<cmd>Lspsaga code_action<cr>",
      --   noremap = true,
      --   silent = true,
      --   desc = "LSP code action (Alt+Enter)",
      -- },
      {
        "<M-CR>",
        "<cmd>Lspsaga code_action<cr>",
        noremap = true,
        silent = true,
        desc = "LSP code action (Alt+Enter)",
      },
      {
        "<leader>cb",
        "<cmd>Lspsaga finder imp<cr>",
        noremap = true,
        silent = true,
        desc = "Goto implementation",
      },
      {
        "<M-C-B>",
        "<cmd>Lspsaga finder imp<cr>",
        noremap = true,
        silent = true,
        desc = "Goto implementation (Ctrl+Alt+b)",
      },
    },
    opts = {
      callhierarchy = {
        layout = "normal",
        keys = {
          toggle_or_req = { "o", "<cr>" },
          vsplit = "<C-v>",
          split = "<C-x>",
        },
      },
      code_action = {
        show_server_name = true,
        extend_gitsigns = true,
      },
      finder = {
        layout = "normal",
        left_width = 0.4,
        keys = {
          toggle_or_open = { "o", "<cr>" },
          vsplit = "<C-v>",
          split = "<C-x>",
        },
      },
      lightbulb = {
        sign = false,
      },
      rename = {
        in_select = false,
        auto_save = true,
        project_max_width = 0.8,
        project_max_height = 0.5,
        mode = "n",
      },
      symbol_in_winbar = {
        enable = false,
      },
    },
    dependencies = {
      "neovim/nvim-lspconfig",
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
