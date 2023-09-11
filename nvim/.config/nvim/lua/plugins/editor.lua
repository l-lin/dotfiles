local function get_selected_text()
  vim.cmd('noau normal! "vy"')
  local text = vim.fn.getreg("v")
  vim.fn.setreg("v", {})
  text = string.gsub(text, "\n", "")
  if string.len(text) == 0 then
    text = ""
  end
  return text
end

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
        mode = "n",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<C-g>",
        function()
          require("telescope.builtin").find_files({ default_text = get_selected_text() })
        end,
        mode = "v",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<M-f>",
        "<cmd>Telescope live_grep<cr>",
        mode = "n",
        noremap = true,
        silent = true,
        desc = "Find pattern in all files (Alt+f)",
      },
      {
        "<M-f>",
        function()
          require("telescope.builtin").live_grep({ default_text = get_selected_text() })
        end,
        mode = "v",
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
    opts = {
      close_if_last_window = true,
      window = {
        mappings = {
          ["o"] = "open",
          ["S"] = "none",
          ["s"] = "none",
          ["<C-v>"] = "open_vsplit",
          ["<C-x>"] = "open_split",
        },
      },
      default_component_configs = {
        file_size = {
          enabled = false,
        },
        last_modified = {
          enabled = false,
        },
        created = {
          enabled = false,
        },
        type = {
          enabled = false,
        },
      },
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
        "<leader>fo",
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

  -- multiple cursors
  {
    "mg979/vim-visual-multi",
    event = "ModeChanged",
    init = function()
      vim.cmd([[
        let g:VM_theme = "paper"
        let g:VM_maps = {}
        let g:VM_maps["Find Under"] = "<A-h>"
        let g:VM_maps["Find Subword Under"] = "<A-h>"
      ]])
    end,
  },

  -- fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        path_display = {
          "truncate",
        },
      },
    },
  },

  -- search/replace in multiple files
  {
    "nvim-pack/nvim-spectre",
    keys = {
      {
        "<M-3>",
        "<cmd>lua require('spectre').open_file_search()<cr>",
        desc = "Replace in file (Spectre) (Alt+3)",
      },
      {
        "<M-3>",
        "<cmd>lua require('spectre').open_file_search({select_word = true})<cr>",
        mode = "v",
        desc = "Replace in file (Spectre) (Alt+3)",
      },
    },
    opts = {
      highlight = {
        search = "DiffAdd",
      },
    },
  },

  -- better diagnostics list and others
  {
    "folke/trouble.nvim",
    keys = {
      { "<leader>xQ", false },
      { "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List (Trouble)" },
    },
  },
}
