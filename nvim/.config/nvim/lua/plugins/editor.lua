return {
  -- fuzzy finding anything anywhere
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
    },
  },
  -- file explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      { "<A-1>", "<leader>fE", desc = "Explorer NeoTree (root dir) (Alt+1)", remap = true },
    },
  },
  -- multilevel undo explorer
  {
    "mbbill/undotree",
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<cr>", noremap = true, desc = "Undotree Toggle" },
    },
  },
  -- file explorer to edit filesystem like a normal buffer, vim-vinegar like
  {
    "stevearc/oil.nvim",
    keys = {
      {
        "<leader>no",
        function()
          require("oil").open()
        end,
        desc = "Oil open current directory",
      },
    },
    config = function()
      require("oil").setup()
    end,
  },
  -- highlight TODO comments
  {
    "folke/todo-comments.nvim",
    keys = {
      { "<M-2>", "<cmd>TodoTelescope<cr>", noremap = true, desc = "Telescope find TODO (Alt+2)" },
    },
  },
  {
    "mg979/vim-visual-multi",
    event = "ModeChanged",
    init = function()
      vim.cmd([[
        let g:VM_theme = "spacegray"
        let g:VM_maps = {}
        let g:VM_maps["Find Under"] = "<A-h>"
        let g:VM_maps["Find Subword Under"] = "<A-h>"
      ]])
    end,
  },
}
