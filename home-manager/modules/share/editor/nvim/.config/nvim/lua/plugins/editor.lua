return {
  -- No need for grug-far, let's use quickfix list!
  { "MagicDuck/grug-far.nvim", enabled = false, },
  -- Not using flash, moving with basic vim motions.
  { "folke/flash.nvim", enabled = false },


  -- #######################
  -- override default config
  -- #######################

  -- file explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = false,
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
          ["h"] = require("plugins.custom.editor.neotree").focus_parent,
          ["l"] = require("plugins.custom.editor.neotree").focus_child,
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

  -- better diagnostics list and others
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    keys = {
      { "<M-3>", "<cmd>Trouble qflist toggle focus=true<cr>", desc = "Toggle Trouble (Alt+3)" },
    },
  },
}
