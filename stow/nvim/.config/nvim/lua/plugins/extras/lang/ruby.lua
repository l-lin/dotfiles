return {
  -- I do not use DAP for Ruby projects.
  { "suketa/nvim-dap-ruby", enabled = false },
  -- I do not execute test from nvim.
  { "olimorris/neotest-rspec", enabled = false },

  -- add keymaps to which-key
  {
    "folke/which-key.nvim",
    ft = "ruby",
    opts = {
      spec = {
        { "<leader>e", group = "execute" },
        { "<leader>t", group = "test" },
      },
    },
  },

  -- #######################
  -- add new plugins
  -- #######################

  -- Alternative LSP server to ruby-lsp for navigation (no auto-completion).
  {
    "neovim/nvim-lspconfig",
    dependencies = { "pheen/fuzzy_ruby_server" },
    opts = {
      servers = {
        fuzzy_ls = {
          init_options = {
            allocationType = "tempdir",
            indexGems = false,
            reportDiagnostics = false,
          },
        },
      },
      setup = {
        fuzzy_ls = function(_, opts)
          local lspconfig = require("lspconfig")
          local configs = require("lspconfig.configs")

          if not configs.fuzzy_ls then
            configs.fuzzy_ls = {
              default_config = {
                cmd = {
                  vim.fn.expand(vim.fn.stdpath("data") .. "/lazy/fuzzy_ruby_server/bin/fuzzy_darwin-arm64"),
                },
                filetypes = { "ruby" },
                root_dir = function(fname)
                  return vim.fs.dirname(vim.fs.find(".git", { path = fname, upward = true })[1])
                end,
                settings = {},
                init_options = {
                  -- possible values:
                  -- ram: use RAM (can be very high on big project)
                  -- tempdir: use mmap directory to store the indexes (e.g. /tmp/.tmpcCUkiK)
                  allocationType = "ram",
                  indexGems = true,
                  reportDiagnostics = true,
                },
              },
            }
          end
          lspconfig.fuzzy_ls.setup(opts)
        end,
      },
    },
  },
}
