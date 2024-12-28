local neotree_commands = require("plugins.custom.editor.neotree")
local telescope_commands = require("plugins.custom.editor.telescope")
local telescope_live_multigrep = require("plugins.custom.editor.telescope-live-multigrep")

local find_files = function(default_text)
  -- require("telescope.builtin").find_files({ default_text = default_text })

  require("telescope").extensions.smart_open.smart_open({
    cwd_only = true,
    match_algorithm = "fzf",
    default_text = default_text,
    filename_first = false,
  })
end

return {
  -- No need for grug-far, let's use quickfix list!
  { "MagicDuck/grug-far.nvim", enabled = false, },

  -- #######################
  -- override default config
  -- #######################

  -- fuzzy finding anything anywhere
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        "l-lin/smart-open.nvim",
        branch = "0.2.x",
        config = function()
          LazyVim.on_load("telescope.nvim", function()
            require("telescope").load_extension("smart_open")
          end)
        end,
        dependencies = { "kkharji/sqlite.lua" },
      },
    },
    keys = {
      -- disable
      { "<leader>gc", false },
      { "<leader>gs", false },
      -- finder
      {
        "<C-g>",
        function()
          find_files("")
        end,
        mode = "n",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<C-g>",
        function()
          find_files(telescope_commands.get_selected_text())
        end,
        mode = "v",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<C-t>",
        function()
          find_files(telescope_commands.find_associate_test_or_file())
        end,
        desc = "Find associated test file (Ctrl+t)",
        noremap = true,
        silent = true,
      },
      {
        "<M-f>",
        telescope_live_multigrep.search,
        mode = "n",
        noremap = true,
        silent = true,
        desc = "Find pattern in all files (Alt+f)",
      },
      {
        "<M-f>",
        function(opts)
          telescope_live_multigrep.search(opts, telescope_commands.get_selected_text())
        end,
        mode = "v",
        noremap = true,
        silent = true,
        desc = "Find pattern in all files (Alt+f)",
      },
      {
        "<C-e>",
        function()
          require("telescope.builtin").buffers({ sort_mru = true, ignore_current_buffer = true })
        end,
        noremap = true,
        silent = true,
        desc = "Find file in buffer (Ctrl+e)",
      },
      { "<C-x>", "<cmd>Telescope resume<cr>", noremap = true, silent = true, desc = "Resume search" },
    },
    opts = {
      defaults = {
        mappings = {
          i = {
            ["<C-j>"] = require("telescope.actions").preview_scrolling_down,
            ["<C-k>"] = require("telescope.actions").preview_scrolling_up,
            -- Invert the keymap because I'm already using C-q with tmux, and I more often sending the whole result to qflist.
            ["<M-q>"] = function(prompt_bufn)
              require("telescope.actions").send_to_qflist(prompt_bufn)
              require("trouble").open({ mode = "qflist", focus = true })
            end,
            ["<C-q>"] = function(prompt_bufn)
              require("telescope.actions").send_selected_to_qflist(prompt_bufn)
              require("trouble").open({ mode = "qflist", focus = true })
            end,
            ["<C-o>"] = function(prompt_bufn)
              local picker = require("telescope.actions.state").get_current_picker(prompt_bufn)
              local prompt = picker:_get_prompt()
              vim.api.nvim_command("edit! " .. prompt)
            end
          },
        },
        prompt_prefix = " ",
        path_display = {
          "truncate",
        },
        layout_strategy = "vertical",
        sorting_strategy = "ascending",
        layout_config = {
          vertical = {
            prompt_position = "bottom",
            mirror = false,
            preview_height = 0.65,
          }
        },
      },
      pickers = {
        buffers = {
          sort_mru = true,
          sort_lastused = true,
        },
      },
    },
  },

  -- file explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      close_if_last_window = true,
      enable_git_status = false,
      enable_diagnostics = false,
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
      event_handlers = {
        {
          event = "neo_tree_popup_input_ready",
          ---@param input NuiInput
          handler = function(input)
            -- enter input popup with normal mode by default.
            vim.cmd("stopinsert")
          end,
        },
      },
    },
  },

  -- highlight TODO comments
  {
    "folke/todo-comments.nvim",
    keys = {
      { "<M-2>", "<cmd>TodoTelescope<cr>", noremap = true, desc = "Telescope find TODO (Alt+2)" },
    },
  },

  -- better diagnostics list and others
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    keys = {
      { "<M-3>", "<cmd>Trouble qflist toggle focus=true<cr>", desc = "Toggle Trouble (Alt+3)" },
    },
  },

  -- Flash enhances the built-in search functionality by showing labels
  -- at the end of each match, letting you quickly jump to a specific
  -- location.
  {
    "folke/flash.nvim",
    -- I do not use it after all...
    enabled = false,
    event = "VeryLazy",
    opts = {
      modes = {
        search = {
          enabled = false,
        },
      },
    },
    keys = {
      -- disable the default flash keymaps, let me use the default behavior
      { "s", mode = { "n", "x", "o" }, false },
      { "S", mode = { "n", "o", "x" }, false },
      {
        "<leader>sf",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "<leader>sF",
        mode = { "n", "o", "x" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
    },
  },

  -- code outline window
  {
    "stevearc/aerial.nvim",
    optional = true,
    keys = {
      { "<A-7>", "<cmd>AerialToggle<cr>", desc = "Aerial Symbols (Alt+7)" },
      { "<F36>", "<cmd>Telescope aerial<cr>", desc = "Goto Symbol (Ctrl+F12)" },
    },
  },

  -- #######################
  -- add new plugins
  -- #######################

  -- multilevel undo explorer
  {
    "mbbill/undotree",
    keys = {
      { "<leader>U", "<cmd>UndotreeToggle<cr>", noremap = true, desc = "Undotree Toggle" },
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
}
