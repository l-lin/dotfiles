return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = "ruby",
      root = "Gemfile",
    })
  end,
  -- add keymaps to which-key
  {
    "folke/which-key.nvim",
    ft = "ruby",
    opts = {
      spec = {
        { "<leader>m", group = "execute" },
        { "<leader>t", group = "test" },
      },
    },
  },
  {
    "https://codeberg.org/l-lin/private-ruby.nvim",
    ft = 'ruby',
    opts = {},
  },

  -- add syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "ruby" } },
  },

  -- use LSP servers
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruby_lsp = {
          enabled = true,
          cmd = { "ruby-lsp" },
        },
        -- INFO: rubocop is using some cache, so you might have to clear cache with the following
        -- command if some config file are not found:
        --   rm -rf $XDG_CACHE_HOME/501/rubocop_cache/
        -- You can check which config files are used by executing the following command:
        --   bundle exec rubocop --debug
        rubocop = {
          enabled = true,
          cmd = { "rubocop", "--lsp" },
        },
      },
    },
  },

  -- Alternative LSP server to ruby-lsp for navigation (no auto-completion).
  {
    "neovim/nvim-lspconfig",
    dependencies = { "pheen/fuzzy_ruby_server" },
    opts = {
      servers = {
        fuzzy_ls = {
          enabled = true,
          filetypes = { "ruby" },
          root_markers = { 'Gemfile', '.git' },
          mason = false,
          init_options = {
            -- possible values:
            -- ram: use RAM (can be very high on big project)
            -- tempdir: use mmap directory to store the indexes (e.g. /tmp/.tmpcCUkiK)
            allocationType = "tempdir",
            indexGems = true,
            reportDiagnostics = true,
          },
          cmd = {
            vim.fn.expand(vim.fn.stdpath("data") .. "/lazy/fuzzy_ruby_server/bin/fuzzy_darwin-arm64"),
          },
        },
      },
    },
  },
}
