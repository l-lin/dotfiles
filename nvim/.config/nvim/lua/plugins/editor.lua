return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      -- disable
      { "<leader>gc", false },
      { "<leader>gs", false },
      -- finder
      {
        "<C-g>",
        "<cmd>Telescope find_files<cr>",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<M-f>",
        "<cmd>Telescope live_grep<cr>",
        noremap = true,
        silent = true,
        desc = "Find pattern in all files (Alt+f)",
      },
      {
        "<C-e>",
        "<cmd>Telescope buffers<cr>",
        noremap = true,
        silent = true,
        desc = "Find file in buffer (Ctrl+e)",
      },
      {
        "<leader>fk",
        "<cmd>Telescope keymaps<cr>",
        noremap = true,
        silent = true,
        desc = "Find nvim keymaps",
      },

      -- code
      {
        "<C-b>",
        "<cmd>Telescope lsp_definitions<cr>",
        noremap = true,
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

      -- dap
      {
        "<leader>dc",
        "<cmd>Telescope dap configurations<cr>",
        noremap = true,
        silent = true,
        desc = "Telescope DAP configuration",
      },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      { "<A-1>", "<leader>fe", desc = "Explorer NeoTree (root dir) (Alt+1)", remap = true },
    },
  },
}
