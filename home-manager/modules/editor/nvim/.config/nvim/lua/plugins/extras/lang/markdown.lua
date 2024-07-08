return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        -- Disable linter, let me freely write anything without hassle!
        -- src: https://github.com/LazyVim/LazyVim/issues/2437
        markdown = { },
      },
    },
  },
}
