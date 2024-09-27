return {
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
                cmd = { vim.fn.expand("~/.local/share/nvim/lazy/fuzzy_ruby_server/bin/fuzzy_x86_64-unknown-linux-gnu") },
                filetypes = { "ruby" },
                root_dir = function(fname)
                  return lspconfig.util.find_git_ancestor(fname)
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

  -- Neotest adapter for Minitest
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "zidhuss/neotest-minitest",
    },
    opts = {
      adapters = {
        ["neotest-minitest"] = {
          test_cmd = function()
            return vim
              .iter({
                "bundle",
                "exec",
                "rails",
                "test",
              })
              :flatten()
              :totable()
          end,
        },
      },
    },
  },
}
