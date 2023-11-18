local neotree_commands = require("plugins.extras.neotree.commands")

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
    opts = {
      defaults = {
        mappings = {
          i = {
            ["<C-f>"] = require("telescope.actions").preview_scrolling_left,
          },
        },
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
      enable_git_status = false,
      enable_normal_mode_for_inputs = true,
      enable_modified_markers = false,
      window = {
        mappings = {
          ["o"] = "open",
          ["S"] = "none",
          ["s"] = "none",
          ["<C-v>"] = "open_vsplit",
          ["<C-x>"] = "open_split",
          ["h"] = neotree_commands.focus_parent,
          ["l"] = neotree_commands.focus_child,
        },
      },
      filesystem = {
        follow_current_file = {
          enabled = true,
          leave_dir_open = true,
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
      { "<leader>U", "<cmd>UndotreeToggle<cr>", noremap = true, desc = "Undotree Toggle" },
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
        "<M-r>",
        "<cmd>lua require('spectre').open_file_search()<cr>",
        desc = "Replace in file (Spectre) (Alt+r)",
      },
      {
        "<M-r>",
        "<cmd>lua require('spectre').open_file_search({select_word = true})<cr>",
        mode = "v",
        desc = "Replace in file (Spectre) (Alt+r)",
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
      { "<leader>xL", false },
      { "<leader>xl", "<cmd>TroubleToggle loclist<cr>", desc = "Location List (Trouble)" },
      { "<leader>xo", "<cmd>TroubleToggle<cr>", desc = "Toggle Trouble (Alt+3)" },
      { "<M-3>", "<cmd>TroubleToggle<cr>", desc = "Toggle Trouble (Alt+3)" },
      { "<leader>xQ", false },
      { "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List (Trouble)" },
    },
  },

  -- Flash enhances the built-in search functionality by showing labels
  -- at the end of each match, letting you quickly jump to a specific
  -- location.
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        search = {
          enabled = false,
        },
      },
    },
  },

  {
    "stevearc/aerial.nvim",
    keys = {
      { "<A-7>", "<cmd>AerialToggle<cr>", desc = "Aerial Symbols (Alt+7)" },
      { "<F36>", "<cmd>Telescope aerial<cr>", desc = "Goto Symbol (Ctrl+F12)" },
    },
  },
}
