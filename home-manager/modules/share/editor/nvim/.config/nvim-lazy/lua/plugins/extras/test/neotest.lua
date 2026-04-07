return {
  -- Installing rust-analyzer Language Server because I keep getting the following error message when executing neo-test:
  -- > **rust-analyzer** not found in PATH, please install it.\nhttps://rust-analyzer.github.io/
  -- It appears it was removed from LazyVim Rust extras because, for Rust devs, rust-analyzer is installed from a toolchain
  -- different to Mason.
  -- But neotest seems to use rust-analyzer... And I do not install it from another source, thus adding this dependency here.
  -- src: https://github.com/LazyVim/LazyVim/pull/2755
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        rust_analyzer = {},
      },
    },
  },

  -- #######################
  -- override default config
  -- #######################

  {
    "nvim-neotest/neotest",
    keys = {
      {
        "<M-S-F9>",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Run File (Alt+Shift+F9)",
        noremap = true,
        silent = true,
      },
      {
        "<F21>",
        function()
          require("neotest").run.run()
        end,
        desc = "Run Nearest (Shift+F9)",
        noremap = true,
        silent = true,
      },
    },
  },
}
