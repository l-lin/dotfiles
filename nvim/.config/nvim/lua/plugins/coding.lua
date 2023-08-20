return {
  {
    "dhruvasagar/vim-table-mode",
    ft = "md",
  },
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<C-b>",
        "<cmd>Telescope lsp_definitions<cr>",
        silent = true,
        desc = "Goto definition (Ctrl+b)",
      },
      {
        "<M-6>",
        "<cmd>Telescope diagnostics<cr>",
        noremap = true,
        silent = true,
        desc = "Diagnostic (Alt+6)",
      },
    },
  },
}
